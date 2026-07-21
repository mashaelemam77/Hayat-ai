import 'dart:convert';

class ReportModel {
  final String id;
  final String subject;
  final String description;
  final String date;
  final String type;
  final String status;
  final String severity;
  final String location;
  final String department;
  final String reporterName;
  final String reporterPhone;
  final String analysis;
  final String imageAnalysis;
  final String audioAnalysis;
  final String imagePath;
  final String audioPath;
  final String documentPath;
  final String mapsUrl;
  final String rawReportText;

  const ReportModel({
    required this.id,
    required this.subject,
    required this.description,
    required this.date,
    required this.type,
    required this.status,
    required this.severity,
    required this.location,
    required this.department,
    required this.reporterName,
    required this.reporterPhone,
    required this.analysis,
    required this.imageAnalysis,
    required this.audioAnalysis,
    required this.imagePath,
    required this.audioPath,
    required this.documentPath,
    required this.mapsUrl,
    required this.rawReportText,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    final createdAt = DateTime.tryParse(json['created_at']?.toString() ?? '');
    final date =
        json['date']?.toString() ??
        (createdAt == null ? '' : createdAt.toIso8601String().split('T').first);
    final reportText = json['report_text']?.toString() ?? '';
    final structuredReport = _decodeReportText(reportText);
    final fallbackSections = _extractFallbackSections(reportText);
    final locationText = _firstText([
      json['location'],
      structuredReport['location'],
      json['location_desc'],
    ]);

    return ReportModel(
      id: json['id']?.toString() ?? '',
      subject: _firstText([
        json['subject'],
        structuredReport['topic'],
        structuredReport['الموضوع'],
        structuredReport['title'],
        structuredReport['عنوان البلاغ'],
        structuredReport['report_subject'],
        json['topic'],
        json['title'],
        _extractLineValue(reportText, ['الموضوع', 'عنوان البلاغ', 'topic']),
      ]),
      description: _firstText([
        json['description'],
        structuredReport['description'],
        structuredReport['وصف البلاغ'],
        structuredReport['الوصف'],
        structuredReport['user_text'],
        structuredReport['report_description'],
        json['details'],
        json['report_text'],
        fallbackSections['userText'],
        reportText,
      ]),
      date: date,
      type: _firstText([
        json['type'],
        _joinIfList(structuredReport['incident_type']),
        _joinIfList(structuredReport['نوع البلاغ']),
        _joinIfList(structuredReport['نوع الحادث']),
        json['incident_type'],
        'أخرى',
      ]),
      status: _normalizeStatus(
        _firstText([json['status'], structuredReport['report_status'], 'جديد']),
      ),
      severity: _normalizeSeverity(
        _firstText([
          json['severity'],
          json['priority'],
          structuredReport['priority_level'],
          'متوسطة',
        ]),
      ),
      location: locationText,
      department: json['department']?.toString() ?? '',
      reporterName: _firstText([
        json['reporter_name'],
        json['user_name'],
        structuredReport['user_name'],
        structuredReport['reporter_name'],
        structuredReport['اسم المبلغ'],
        structuredReport['اسم المبلّغ'],
        structuredReport['name'],
        structuredReport['user'],
        structuredReport['اسم المستخدم'],
        structuredReport['المبلغ'],
        fallbackSections['reporterName'],
        _extractLineValue(reportText, ['اسم المبلغ', 'اسم المبلّغ', 'المبلّغ']),
      ]),
      reporterPhone: _firstText([
        json['reporter_phone'],
        json['user_mobile'],
        structuredReport['user_mobile'],
        structuredReport['reporter_phone'],
        structuredReport['رقم الجوال'],
        structuredReport['هاتف المبلغ'],
        structuredReport['mobile'],
        structuredReport['phone'],
        structuredReport['user_phone'],
        structuredReport['رقم الهاتف'],
        fallbackSections['reporterPhone'],
        _extractLineValue(reportText, ['رقم الجوال', 'هاتف المبلغ', 'هاتف']),
      ]),
      analysis: _firstText([
        json['analysis'],
        json['ai_analysis'],
        structuredReport['description'],
        structuredReport['analysis'],
        structuredReport['ai_analysis'],
        structuredReport['تحليل البلاغ'],
        fallbackSections['combinedAnalysis'],
      ]),
      imageAnalysis: _firstText([
        json['image_analysis'],
        json['image_text'],
        structuredReport['image_analysis'],
        structuredReport['image_text'],
        structuredReport['image_description'],
        structuredReport['تحليل الصورة'],
        structuredReport['وصف الصورة'],
        fallbackSections['imageAnalysis'],
        _extractLineValue(reportText, ['تحليل الصورة', 'وصف الصورة']),
      ]),
      audioAnalysis: _firstText([
        json['audio_analysis'],
        json['voice_text'],
        json['voice_analysis'],
        json['audio_text'],
        json['transcribed_text'],
        structuredReport['audio_analysis'],
        structuredReport['voice_text'],
        structuredReport['transcribed_text'],
        structuredReport['transcript'],
        structuredReport['تحليل الصوت'],
        structuredReport['تفريغ الصوت'],
        structuredReport['النص الناتج من الصوت'],
        fallbackSections['audioAnalysis'],
        _extractLineValue(reportText, [
          'تحليل الصوت',
          'تفريغ الصوت',
          'النص الناتج من الصوت',
        ]),
      ]),
      imagePath: _firstText([
        json['image_path'],
        json['image'],
        json['image_url'],
      ]),
      audioPath: _firstText([
        json['voice_path'],
        json['audio_path'],
        json['audio_url'],
      ]),
      documentPath: _firstText([
        json['document_path'],
        json['document'],
        json['document_url'],
        structuredReport['document_path'],
      ]),
      mapsUrl: _firstText([
        json['maps_url'],
        json['google_maps_url'],
        structuredReport['maps_url'],
        _mapsUrlFromText(locationText),
      ]),
      rawReportText: reportText,
    );
  }

  Map<String, dynamic> toOfficerMap() => {
    'id': id,
    'subject': subject,
    'date': date,
    'type': type,
    'status': status,
    'severity': severity,
    'location': location,
    'department': department,
    'reporterName': reporterName,
    'reporterPhone': reporterPhone,
    'analysis': analysis.isEmpty ? description : analysis,
    'imageAnalysis': imageAnalysis,
    'audioAnalysis': audioAnalysis,
    'image': imagePath,
    'audio': audioPath,
    'document': documentPath,
    'mapsUrl': mapsUrl,
    'rawReportText': rawReportText,
  };

  Map<String, String> toUserMap() => {
    'id': id,
    'title': subject,
    'date': date,
    'priority': severity,
    'status': status,
  };

  static Map<String, dynamic> _decodeReportText(String value) {
    if (value.trim().isEmpty) return const {};
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {
      return const {};
    }
    return const {};
  }

  static Map<String, String> _extractFallbackSections(String value) {
    String sectionBetween(String start, List<String> endMarkers) {
      final startIndex = value.indexOf(start);
      if (startIndex < 0) return '';
      final contentStart = startIndex + start.length;
      var contentEnd = value.length;
      for (final marker in endMarkers) {
        final markerIndex = value.indexOf(marker, contentStart);
        if (markerIndex >= 0 && markerIndex < contentEnd) {
          contentEnd = markerIndex;
        }
      }
      return value.substring(contentStart, contentEnd).trim();
    }

    final userText = sectionBetween('وصف المستخدم:', [
      'النص الناتج من الصوت:',
      'تحليل الصورة:',
      'الموقع:',
    ]);
    final audioAnalysis = sectionBetween('النص الناتج من الصوت:', [
      'تحليل الصورة:',
      'الموقع:',
    ]);
    final imageAnalysis = sectionBetween('تحليل الصورة:', ['الموقع:']);
    final reporterMatch = RegExp(
      r'المبلّغ:\s*([^|\n]+)(?:\|\s*هاتف:\s*([^\n]+))?',
    ).firstMatch(value);

    return {
      'userText': userText,
      'audioAnalysis': audioAnalysis,
      'imageAnalysis': imageAnalysis,
      'reporterName': reporterMatch?.group(1)?.trim() ?? '',
      'reporterPhone': reporterMatch?.group(2)?.trim() ?? '',
      'combinedAnalysis': [
        if (userText.isNotEmpty) userText,
        if (audioAnalysis.isNotEmpty) audioAnalysis,
        if (imageAnalysis.isNotEmpty) imageAnalysis,
      ].join('\n\n'),
    };
  }

  static String _extractLineValue(String value, List<String> labels) {
    for (final label in labels) {
      final match = RegExp(
        '$label\\s*[:：]\\s*([^\\n\\r]+)',
        caseSensitive: false,
      ).firstMatch(value);
      final text = match?.group(1)?.trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  static String _firstText(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty && text != 'null' && text != 'N/A') return text;
    }
    return '';
  }

  static String _joinIfList(dynamic value) {
    if (value is List) return value.map((item) => item.toString()).join('، ');
    return value?.toString() ?? '';
  }

  static String _mapsUrlFromText(String value) {
    final match = RegExp(
      r'(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)',
    ).firstMatch(value);
    if (match == null) return '';
    return 'https://www.google.com/maps?q=${match.group(1)},${match.group(2)}';
  }

  static String _normalizeStatus(String value) {
    return switch (value) {
      'New' || 'Submitted' => 'جديد',
      'In Progress' => 'قيد المعالجة',
      'Resolved' || 'Closed' => 'مغلق',
      _ => value,
    };
  }

  static String _normalizeSeverity(String value) {
    return switch (value) {
      'Low' => 'منخفضة',
      'Medium' => 'متوسطة',
      'High' => 'عالية',
      'Critical' => 'حرجة',
      _ => value,
    };
  }
}
