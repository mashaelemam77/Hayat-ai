import 'dart:convert';
import 'dart:async';

import '../models/report_model.dart';
import 'api_service.dart';

class ReportService {
  static const String tableName = 'reports';
  static final List<ReportModel> _localReports = [];
  static final StreamController<List<ReportModel>> _localReportsController =
      StreamController<List<ReportModel>>.broadcast();

  static List<ReportModel> get _localSnapshot =>
      List<ReportModel>.unmodifiable(_localReports);

  static void _emitLocalReports() {
    if (!_localReportsController.isClosed) {
      _localReportsController.add(_localSnapshot);
    }
  }

  Future<List<ReportModel>> fetchReports() async {
    if (!ApiService.isSupabaseConfigured) {
      return _localSnapshot;
    }

    final response = await ApiService.client
        .from(tableName)
        .select()
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((item) => ReportModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Stream<List<ReportModel>> watchReports() {
    if (!ApiService.isSupabaseConfigured) {
      return Stream<List<ReportModel>>.multi((controller) {
        controller.add(_localSnapshot);
        final sub = _localReportsController.stream.listen(controller.add);
        controller.onCancel = sub.cancel;
      });
    }

    return ApiService.client
        .from(tableName)
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map(
          (rows) => rows
              .map(
                (item) => ReportModel.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList(),
        );
  }

  Future<void> createReport({
    required String reporterName,
    required String reporterPhone,
    required String description,
    required String location,
    String? subject,
    String type = 'أخرى',
    String severity = 'متوسطة',
    String aiAnalysis = '',
    String imageAnalysis = '',
    String audioAnalysis = '',
    String imagePath = '',
    String audioPath = '',
    String documentPath = '',
  }) async {
    final reportSubject = subject?.trim().isNotEmpty == true
        ? subject!.trim()
        : _buildSubject(description);
    final finalAiAnalysis = aiAnalysis.trim().isNotEmpty
        ? aiAnalysis.trim()
        : _buildAiAnalysis(
            subject: reportSubject,
            description: description,
            type: type,
            severity: severity,
            imageAnalysis: imageAnalysis,
            audioAnalysis: audioAnalysis,
          );
    final reportText = jsonEncode({
      'topic': reportSubject,
      'description': description,
      'location': location,
      'incident_type': type
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(),
      'priority_level': _severityToEnglish(severity),
      'report_status': 'New',
      'user_name': reporterName,
      'user_mobile': reporterPhone,
      'image_analysis': imageAnalysis,
      'audio_analysis': audioAnalysis,
      'document_path': documentPath,
    });

    if (!ApiService.isSupabaseConfigured) {
      final now = DateTime.now();
      final id = 'RPT-${now.microsecondsSinceEpoch.toString().substring(6)}';
      _localReports.insert(
        0,
        ReportModel.fromJson({
          'id': id,
          'subject': reportSubject,
          'description': description,
          'date': now.toIso8601String().split('T').first,
          'type': type,
          'status': 'جديد',
          'severity': severity,
          'location': location,
          'department': '',
          'reporter_name': reporterName,
          'reporter_phone': reporterPhone,
          'analysis': finalAiAnalysis,
          'image_analysis': imageAnalysis,
          'audio_analysis': audioAnalysis,
          'image_path': imagePath,
          'voice_path': audioPath,
          'document_path': documentPath,
          'maps_url': _mapsUrlFromLocation(location),
          'report_text': reportText,
        }),
      );
      _emitLocalReports();
      return;
    }

    final websiteValues = <String, dynamic>{
      'report_text': reportText,
      'location_desc': location,
      'image_path': imagePath.trim().isEmpty ? null : imagePath.trim(),
      'voice_path': audioPath.trim().isEmpty ? null : audioPath.trim(),
      'status': 'جديد',
      'ai_analysis': finalAiAnalysis,
      'image_analysis': imageAnalysis.trim().isEmpty
          ? null
          : imageAnalysis.trim(),
      'user_name': reporterName,
      'user_mobile': reporterPhone,
      'topic': reportSubject,
      'incident_type': type,
      'responsible_agents': '',
      'priority': severity,
      'date': DateTime.now().toIso8601String().split('T').first,
    };

    final legacyValues = <String, dynamic>{
      'subject': reportSubject,
      'description': description,
      'type': type,
      'status': 'جديد',
      'severity': severity,
      'location': location,
      'department': '',
      'reporter_name': reporterName,
      'reporter_phone': reporterPhone,
      'analysis': finalAiAnalysis,
    };

    if (imageAnalysis.trim().isNotEmpty) {
      legacyValues['image_analysis'] = imageAnalysis.trim();
    }
    if (audioAnalysis.trim().isNotEmpty) {
      legacyValues['audio_analysis'] = audioAnalysis.trim();
    }
    if (imagePath.trim().isNotEmpty) {
      legacyValues['image_path'] = imagePath.trim();
    }
    if (audioPath.trim().isNotEmpty) {
      legacyValues['voice_path'] = audioPath.trim();
    }
    if (documentPath.trim().isNotEmpty) {
      legacyValues['document_path'] = documentPath.trim();
    }
    legacyValues['report_text'] = reportText;
    legacyValues['location_desc'] = location;

    try {
      await ApiService.client.from(tableName).insert(websiteValues);
    } catch (error) {
      try {
        await ApiService.client.from(tableName).insert(legacyValues);
      } catch (_) {
        final now = DateTime.now();
        _localReports.insert(
          0,
          ReportModel.fromJson({
            ...websiteValues,
            'id': 'RPT-${now.microsecondsSinceEpoch.toString().substring(6)}',
            'date': now.toIso8601String().split('T').first,
          }),
        );
        _emitLocalReports();
      }
    }
  }

  Future<void> updateReport(String id, Map<String, dynamic> values) async {
    if (!ApiService.isSupabaseConfigured) {
      _updateLocalReport(id, values);
      return;
    }

    await ApiService.client
        .from(tableName)
        .update(_toDatabaseColumns(values))
        .eq('id', id);
  }

  Future<void> deleteReport(String id) async {
    if (!ApiService.isSupabaseConfigured) {
      _localReports.removeWhere((report) => report.id == id);
      _emitLocalReports();
      return;
    }

    await ApiService.client.from(tableName).delete().eq('id', id);
  }

  String _buildSubject(String description) {
    final clean = description.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (clean.isEmpty) return 'بلاغ جديد';
    return clean.length <= 42 ? clean : '${clean.substring(0, 42)}...';
  }

  String _severityToEnglish(String severity) {
    return switch (severity) {
      'منخفضة' => 'Low',
      'متوسطة' => 'Medium',
      'عالية' => 'High',
      'حرجة' => 'Critical',
      _ => severity,
    };
  }

  String _buildAiAnalysis({
    required String subject,
    required String description,
    required String type,
    required String severity,
    String imageAnalysis = '',
    String audioAnalysis = '',
  }) {
    return [
      '- العنوان: $subject',
      '- الوصف: $description',
      '- نوع البلاغ: $type',
      '- مستوى الأولوية: $severity',
      if (imageAnalysis.trim().isNotEmpty)
        '- تحليل الصورة: ${imageAnalysis.trim()}',
      if (audioAnalysis.trim().isNotEmpty)
        '- تحليل الصوت: ${audioAnalysis.trim()}',
      '- حالة البلاغ: جديد',
    ].join('\n');
  }

  String _mapsUrlFromLocation(String location) {
    final match = RegExp(
      r'(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)',
    ).firstMatch(location);
    if (match == null) return '';
    return 'https://www.google.com/maps?q=${match.group(1)},${match.group(2)}';
  }

  void _updateLocalReport(String id, Map<String, dynamic> values) {
    final index = _localReports.indexWhere((report) => report.id == id);
    if (index < 0) return;
    final current = _localReports[index];
    _localReports[index] = ReportModel(
      id: current.id,
      subject: values['subject']?.toString() ?? current.subject,
      description: values['description']?.toString() ?? current.description,
      date: values['date']?.toString() ?? current.date,
      type: values['type']?.toString() ?? current.type,
      status: values['status']?.toString() ?? current.status,
      severity: values['severity']?.toString() ?? current.severity,
      location: values['location']?.toString() ?? current.location,
      department:
          values['department']?.toString() ??
          values['reporterDepartment']?.toString() ??
          current.department,
      reporterName: values['reporterName']?.toString() ?? current.reporterName,
      reporterPhone:
          values['reporterPhone']?.toString() ?? current.reporterPhone,
      analysis: values['analysis']?.toString() ?? current.analysis,
      imageAnalysis:
          values['imageAnalysis']?.toString() ?? current.imageAnalysis,
      audioAnalysis:
          values['audioAnalysis']?.toString() ?? current.audioAnalysis,
      imagePath: values['image']?.toString() ?? current.imagePath,
      audioPath: values['audio']?.toString() ?? current.audioPath,
      documentPath: values['document']?.toString() ?? current.documentPath,
      mapsUrl: values['mapsUrl']?.toString() ?? current.mapsUrl,
      rawReportText: current.rawReportText,
    );
    _emitLocalReports();
  }

  Map<String, dynamic> _toDatabaseColumns(Map<String, dynamic> values) {
    const columnNames = {
      'reporterName': 'reporter_name',
      'reporterPhone': 'reporter_phone',
      'subject': 'topic',
      'description': 'report_text',
      'type': 'incident_type',
      'severity': 'priority',
      'location': 'location_desc',
      'analysis': 'ai_analysis',
    };

    return values.map((key, value) => MapEntry(columnNames[key] ?? key, value));
  }
}
