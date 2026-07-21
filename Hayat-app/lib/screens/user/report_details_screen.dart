import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/report_model.dart';
import '../../services/app_language.dart';
import '../../services/report_service.dart';

class ReportDetailsPage extends StatefulWidget {
  const ReportDetailsPage({super.key, required this.report});

  final ReportModel report;

  @override
  State<ReportDetailsPage> createState() => _ReportDetailsPageState();
}

class _ReportDetailsPageState extends State<ReportDetailsPage> {
  final ReportService _reportService = ReportService();
  late ReportModel _report;

  String _displayStatus(String status) {
    if (AppLanguage.isArabic) return status;

    switch (status) {
      case 'جديد':
        return 'New';
      case 'قيد المعالجة':
      case 'قيد التنفيذ':
        return 'In Progress';
      case 'موافق':
        return 'Approved';
      case 'مغلق':
        return 'Closed';
      default:
        return status;
    }
  }

  String _displaySeverity(String severity) {
    if (AppLanguage.isArabic) return severity;

    switch (severity) {
      case 'حرجة':
        return 'Critical';
      case 'عالية':
        return 'High';
      case 'متوسطة':
        return 'Medium';
      case 'منخفضة':
        return 'Low';
      default:
        return severity;
    }
  }

  String _displayType(String type) {
    if (AppLanguage.isArabic) return type;

    return type
        .replaceAll('طوارئ بيئية', 'Environmental Emergency')
        .replaceAll('انهيار مبنى', 'Building Collapse')
        .replaceAll('كوارث طبيعية', 'Natural Disaster')
        .replaceAll('صيانة طرق', 'Road Maintenance')
        .replaceAll('حريق', 'Fire')
        .replaceAll('حادث', 'Accident')
        .replaceAll('أخرى', 'Other')
        .replaceAll('احتراق', 'Burning');
  }

  @override
  void initState() {
    super.initState();
    _report = widget.report;
  }

  Future<void> _editReport() async {
    final subjectCtrl = TextEditingController(text: _report.subject);
    final descriptionCtrl = TextEditingController(text: _report.description);
    final locationCtrl = TextEditingController(text: _report.location);

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLanguage.text('Edit Report', 'تعديل البلاغ')),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogField(AppLanguage.text('Subject', 'الموضوع'), subjectCtrl),
              const SizedBox(height: 12),
              _dialogField(
                AppLanguage.text('Description', 'الوصف'),
                descriptionCtrl,
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              _dialogField(
                AppLanguage.text('Location', 'الموقع'),
                locationCtrl,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLanguage.text('Cancel', 'إلغاء')),
          ),
          ElevatedButton(
            onPressed: () async {
              final subject = subjectCtrl.text.trim();
              final description = descriptionCtrl.text.trim();
              final location = locationCtrl.text.trim();
              if (subject.isEmpty || description.isEmpty || location.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLanguage.text(
                        'Please fill in all report fields',
                        'يرجى تعبئة كل حقول البلاغ',
                      ),
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              await _reportService.updateReport(_report.id, {
                'subject': subject,
                'description': description,
                'location': location,
                'analysis': description,
              });
              if (!context.mounted) return;
              Navigator.pop(context, true);
            },
            child: Text(AppLanguage.text('Save Changes', 'حفظ التعديلات')),
          ),
        ],
      ),
    );

    if (saved != true || !mounted) {
      subjectCtrl.dispose();
      descriptionCtrl.dispose();
      locationCtrl.dispose();
      return;
    }

    final updatedSubject = subjectCtrl.text.trim();
    final updatedDescription = descriptionCtrl.text.trim();
    final updatedLocation = locationCtrl.text.trim();
    subjectCtrl.dispose();
    descriptionCtrl.dispose();
    locationCtrl.dispose();

    setState(() {
      _report = ReportModel(
        id: _report.id,
        subject: updatedSubject,
        description: updatedDescription,
        date: _report.date,
        type: _report.type,
        status: _report.status,
        severity: _report.severity,
        location: updatedLocation,
        department: _report.department,
        reporterName: _report.reporterName,
        reporterPhone: _report.reporterPhone,
        analysis: updatedDescription,
        imageAnalysis: _report.imageAnalysis,
        audioAnalysis: _report.audioAnalysis,
        imagePath: _report.imagePath,
        audioPath: _report.audioPath,
        documentPath: _report.documentPath,
        mapsUrl: _report.mapsUrl,
        rawReportText: _report.rawReportText,
      );
    });
    _showMessage(
      AppLanguage.text('Report updated successfully', 'تم تعديل البلاغ بنجاح'),
    );
  }

  void _trackStatus() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLanguage.text('Track Status', 'متابعة الحالة'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _statusStep(AppLanguage.text('Submitted', 'تم الإرسال'), true),
            _statusStep(
              AppLanguage.text('In Progress', 'قيد المعالجة'),
              _isInProgressOrDone(_report.status),
            ),
            _statusStep(
              AppLanguage.text('Completed', 'مكتمل'),
              _isDone(_report.status),
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  bool _isInProgressOrDone(String status) {
    return status == 'قيد المعالجة' ||
        status == 'قيد التنفيذ' ||
        status == 'موافق' ||
        status == 'مغلق' ||
        status == 'In Progress' ||
        status == 'Resolved';
  }

  bool _isDone(String status) {
    return status == 'موافق' || status == 'مغلق' || status == 'Resolved';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green[700]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final attachments = [
      if (_report.imagePath.isNotEmpty)
        (_fileName(_report.imagePath), AppLanguage.text('Image', 'صورة')),
      if (_report.documentPath.isNotEmpty)
        (
          _fileName(_report.documentPath),
          AppLanguage.text('Document', 'مستند'),
        ),
      if (_report.audioPath.isNotEmpty)
        (_fileName(_report.audioPath), AppLanguage.text('Audio', 'صوت')),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: const Icon(Icons.arrow_back, color: Colors.black),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppLanguage.text('Report Details', 'تفاصيل البلاغ'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _chip(
                          _displayStatus(_report.status),
                          _statusColor(_report.status),
                        ),
                        const SizedBox(width: 10),
                        _chip(
                          _displaySeverity(_report.severity),
                          _priorityColor(_report.severity),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _report.subject.trim().isEmpty
                          ? AppLanguage.text(
                              'Untitled Report',
                              'بلاغ بدون عنوان',
                            )
                          : _report.subject,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _infoCard(),
                    const SizedBox(height: 20),
                    Text(
                      AppLanguage.text('Description', 'الوصف'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _report.description.trim().isEmpty
                          ? AppLanguage.text(
                              'No description available',
                              'لا يوجد وصف',
                            )
                          : _report.description,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      AppLanguage.text('Attachments', 'المرفقات'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (attachments.isEmpty)
                      Text(
                        AppLanguage.text('No attachments', 'لا توجد مرفقات'),
                        style: const TextStyle(color: Colors.grey),
                      )
                    else
                      ...attachments.map(
                        (item) => _attachmentItem(item.$1, item.$2),
                      ),
                    const SizedBox(height: 90),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _editReport,
                      icon: const Icon(Icons.edit),
                      label: Text(
                        AppLanguage.text('Edit Report', 'تعديل البلاغ'),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _trackStatus,
                      icon: const Icon(Icons.bar_chart),
                      label: Text(
                        AppLanguage.text('Track Status', 'متابعة الحالة'),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2F4B8F),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _infoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          _infoRow(
            Icons.confirmation_number_outlined,
            AppLanguage.text('Report No.', 'رقم البلاغ'),
            _report.id,
          ),
          const SizedBox(height: 12),
          _infoRow(
            Icons.category_outlined,
            AppLanguage.text('Type', 'النوع'),
            _empty(_displayType(_report.type)),
          ),
          const SizedBox(height: 12),
          _infoRow(
            Icons.calendar_today,
            AppLanguage.text('Submitted On', 'تاريخ الإرسال'),
            _empty(_report.date),
          ),
          const SizedBox(height: 12),
          _infoRow(
            Icons.location_on,
            AppLanguage.text('Location', 'الموقع'),
            _empty(_report.location),
          ),
          if (_report.mapsUrl.isNotEmpty) ...[
            const SizedBox(height: 12),
            _mapRow(_report.mapsUrl),
          ],
          const SizedBox(height: 12),
          _infoRow(
            Icons.person,
            AppLanguage.text('Reported By', 'اسم المبلغ'),
            _empty(_report.reporterName),
          ),
          const SizedBox(height: 12),
          _infoRow(
            Icons.phone,
            AppLanguage.text('Mobile Number', 'رقم الجوال'),
            _empty(_report.reporterPhone),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: Colors.grey.shade200,
          child: Icon(icon, color: Colors.blueGrey),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _mapRow(String url) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: Colors.grey.shade200,
          child: const Icon(Icons.map_outlined, color: Colors.blueGrey),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            onTap: () async {
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            child: Text(
              AppLanguage.text('Open map location', 'فتح الموقع على الخريطة'),
              style: const TextStyle(
                color: Color(0xFF2D3A8C),
                fontSize: 15,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _attachmentItem(String name, String type) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.grey.shade200,
            child: const Icon(Icons.insert_drive_file, color: Colors.blueGrey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(
                  type,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          const Icon(Icons.attach_file, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _statusStep(String label, bool active, {bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            CircleAvatar(
              radius: 11,
              backgroundColor: active
                  ? const Color(0xFF2D3A8C)
                  : Colors.grey[300],
              child: active
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 34,
                color: active ? const Color(0xFF2D3A8C) : Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: active ? Colors.black87 : Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'عالية':
      case 'High':
        return Colors.orange;
      case 'حرجة':
      case 'Critical':
        return Colors.red;
      case 'متوسطة':
      case 'Medium':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Color _statusColor(String status) {
    if (_isDone(status)) return Colors.green;
    if (_isInProgressOrDone(status)) return Colors.orange;
    return Colors.blue;
  }

  String _empty(String value) => value.trim().isEmpty
      ? AppLanguage.text('Not specified', 'غير محدد')
      : value;

  String _fileName(String path) {
    final normalized = path.replaceAll('\\', '/');
    return normalized.split('/').last;
  }
}
