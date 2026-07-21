import 'package:flutter/material.dart';
import '../../models/report_model.dart';
import '../../services/app_language.dart';
import '../../services/report_service.dart';
import 'report_details_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, this.showBackButton = true});

  final bool showBackButton;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ReportService _reportService = ReportService();
  String _searchQuery = '';
  String _statusFilter = 'all';
  String _priorityFilter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      case 'منخفضة':
      case 'Low':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'قيد التنفيذ':
      case 'In Progress':
        return Colors.orange;
      case 'جديد':
      case 'Submitted':
        return Colors.blue;
      case 'مغلق':
      case 'Resolved':
        return Colors.green;
      case 'موافق':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _displayStatus(String status) {
    if (AppLanguage.code.value == 'ar') return status;

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

  String _displayPriority(String priority) {
    if (AppLanguage.code.value == 'ar') return priority;

    switch (priority) {
      case 'حرجة':
        return 'Critical';
      case 'عالية':
        return 'High';
      case 'متوسطة':
        return 'Medium';
      case 'منخفضة':
        return 'Low';
      default:
        return priority;
    }
  }

  String _displaySubject(String subject) {
    if (AppLanguage.code.value == 'ar') return subject;

    return subject
        .replaceAll('حريق خشب', 'Wood Fire')
        .replaceAll('اصطدام سيارتين', 'Two-Car Collision')
        .replaceAll('اصطدام سيارتين ', 'Two-Car Collision')
        .replaceAll('تصادم سيارتين', 'Two-Car Collision')
        .replaceAll('تصادم مركبتين', 'Two-Vehicle Collision')
        .replaceAll('اصطدام مركبتين', 'Two-Vehicle Collision')
        .replaceAll('بلاغ عن حريق في مستودع', 'Warehouse Fire Report')
        .replaceAll('حادث مروري تصادم 3 سيارات', 'Traffic Accident - 3 Cars Collision')
        .replaceAll('وجود حفرة عميقة في طريق الملك', 'Deep Pothole on King Road')
        .replaceAll('حريق سيارة', 'Car Fire')
        .replaceAll('حريق', 'Fire')
        .replaceAll('حادث', 'Accident')
        .replaceAll('مروري', 'Traffic')
        .replaceAll('اصطدام', 'Collision')
        .replaceAll('تصادم', 'Collision')
        .replaceAll('احتراق', 'Burning')
        .replaceAll('خشب', 'Wood')
        .replaceAll('سيارتين', 'Two Cars')
        .replaceAll('سيارة', 'Car')
        .replaceAll('مركبتين', 'Two Vehicles')
        .replaceAll('صيانة طرق', 'Road Maintenance')
        .replaceAll('كوارث طبيعية', 'Natural Disaster')
        .replaceAll('انهيار مبنى', 'Building Collapse')
        .replaceAll('طوارئ بيئية', 'Environmental Emergency');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  if (widget.showBackButton) ...[
                    GestureDetector(
                      onTap: () => Navigator.maybePop(context),
                      child: CircleAvatar(
                        backgroundColor: Colors.grey.shade200,
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    AppLanguage.text('My Reports', 'بلاغاتي'),
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: AppLanguage.text(
                          'Search reports...',
                          'ابحث في البلاغات...',
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.grey,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _filterDropdown(
                          value: _statusFilter,
                          items: {
                            'all': AppLanguage.text(
                              'All statuses',
                              'كل الحالات',
                            ),
                            'جديد': AppLanguage.text('New', 'جديد'),
                            'قيد المعالجة': AppLanguage.text(
                              'In Progress',
                              'قيد المعالجة',
                            ),
                            'قيد التنفيذ': AppLanguage.text(
                              'Executing',
                              'قيد التنفيذ',
                            ),
                            'موافق': AppLanguage.text('Approved', 'موافق'),
                            'مغلق': AppLanguage.text('Closed', 'مغلق'),
                          },
                          onChanged: (value) =>
                              setState(() => _statusFilter = value ?? 'all'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _filterDropdown(
                          value: _priorityFilter,
                          items: {
                            'all': AppLanguage.text(
                              'All priorities',
                              'كل الأولويات',
                            ),
                            'منخفضة': AppLanguage.text('Low', 'منخفضة'),
                            'متوسطة': AppLanguage.text('Medium', 'متوسطة'),
                            'عالية': AppLanguage.text('High', 'عالية'),
                            'حرجة': AppLanguage.text('Critical', 'حرجة'),
                          },
                          onChanged: (value) =>
                              setState(() => _priorityFilter = value ?? 'all'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder(
                stream: _reportService.watchReports(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final reports = (snapshot.data ?? <ReportModel>[]).where((
                    report,
                  ) {
                    final query = _searchQuery.toLowerCase();
                    final matchesSearch =
                        report.subject.toLowerCase().contains(query) ||
                        report.description.toLowerCase().contains(query) ||
                        report.id.toLowerCase().contains(query);
                    final matchesStatus =
                        _statusFilter == 'all' ||
                        report.status == _statusFilter;
                    final matchesPriority =
                        _priorityFilter == 'all' ||
                        report.severity == _priorityFilter;
                    return matchesSearch && matchesStatus && matchesPriority;
                  }).toList();

                  if (reports.isEmpty) {
                    return Center(
                      child: Text(
                        AppLanguage.text(
                          'No reports yet',
                          'لا توجد بلاغات بعد',
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: reports.length,
                    itemBuilder: (context, index) {
                      final report = reports[index];
                      final r = report.toUserMap();
                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReportDetailsPage(report: report),
                          ),
                        ),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      _displaySubject(report.subject),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _priorityColor(
                                        r['priority']!,
                                      ).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _displayPriority(r['priority']!),
                                      style: TextStyle(
                                        color: _priorityColor(r['priority']!),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                r['date']!,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: _statusColor(
                                    r['status']!,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _displayStatus(r['status']!),
                                  style: TextStyle(
                                    color: _statusColor(r['status']!),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterDropdown({
    required String value,
    required Map<String, String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: items.entries
              .map(
                (entry) => DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
