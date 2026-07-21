import 'package:flutter/material.dart';
import '../../models/report_model.dart';
import '../../services/app_language.dart';
import '../../services/app_session.dart';
import '../../services/report_service.dart';
import '../../welcome_screen.dart';
import 'my_report_screen.dart';
import 'submit_report_screen.dart';

class HomeScreenContent extends StatefulWidget {
  const HomeScreenContent({super.key});

  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent> {
  final ReportService _reportService = ReportService();

  bool _isInProgress(String status) {
    return status == 'قيد التنفيذ' ||
        status == 'قيد المعالجة' ||
        status == 'In Progress';
  }

  bool _isResolved(String status) {
    return status == 'مغلق' || status == 'موافق' || status == 'Resolved';
  }

  Color _statusColor(String status) {
    if (_isInProgress(status)) return const Color(0xFFF5A623);
    if (_isResolved(status)) return const Color.fromARGB(255, 16, 134, 115);
    return const Color(0xFF2D3A8C);
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
  void initState() {
    super.initState();
    AppSession.role.value = AppRole.user;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F5),
      body: StreamBuilder<List<ReportModel>>(
        stream: _reportService.watchReports(),
        builder: (context, snapshot) {
          final reports = snapshot.data ?? const <ReportModel>[];
          final inProgress = reports
              .where((report) => _isInProgress(report.status))
              .length;
          final resolved = reports
              .where((report) => _isResolved(report.status))
              .length;
          final recentReports = reports.take(3).toList();

          return SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 40),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2D3A8C),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              AppLanguage.text(
                                "Welcome Back!",
                                "مرحباً بعودتك!",
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => setState(AppLanguage.toggle),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.white24,
                            ),
                            child: Text(AppLanguage.isArabic ? 'EN' : 'عربي'),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () {
                              AppSession.role.value = null;
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (_) => const WelcomeScreen(),
                                ),
                                (_) => false,
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.white24,
                            ),
                            icon: const Icon(Icons.login, size: 16),
                            label: Text(
                              AppLanguage.text('Roles', 'اختيار الدور'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        AppLanguage.text(
                          "Emergency Reporting System",
                          "نظام البلاغات الطارئة",
                        ),
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -30),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _statCard(
                          reports.length.toString(),
                          AppLanguage.text(
                            "Total\nReports",
                            "إجمالي\nالبلاغات",
                          ),
                          const Color.fromARGB(255, 78, 207, 185),
                          Icons.description,
                        ),
                        const SizedBox(width: 10),
                        _statCard(
                          inProgress.toString(),
                          AppLanguage.text("In Progress", "قيد المعالجة"),
                          const Color(0xFFF5A623),
                          Icons.access_time,
                        ),
                        const SizedBox(width: 10),
                        _statCard(
                          resolved.toString(),
                          AppLanguage.text("Resolved", "مغلقة"),
                          const Color.fromARGB(255, 16, 134, 115),
                          Icons.check_circle_outline,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLanguage.text("Quick Actions", "إجراءات سريعة"),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SubmitReportScreen(),
                                ),
                              ),
                              child: Container(
                                height: 100,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2D3A8C),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.add,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      AppLanguage.text(
                                        "Submit Report",
                                        "إرسال بلاغ",
                                      ),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ReportsScreen(),
                                ),
                              ),
                              child: Container(
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.description_outlined,
                                      size: 30,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      AppLanguage.text(
                                        "View Reports",
                                        "عرض البلاغات",
                                      ),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),
                      Text(
                        AppLanguage.text("Recent Reports", "آخر البلاغات"),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (snapshot.hasError)
                        _emptyState(
                          AppLanguage.text(
                            "Unable to load reports",
                            "تعذر تحميل البلاغات",
                          ),
                        )
                      else if (recentReports.isEmpty)
                        _emptyState(
                          AppLanguage.text(
                            "No reports yet",
                            "لا توجد بلاغات بعد",
                          ),
                        )
                      else
                        ...recentReports.map(
                          (report) => _recentReport(
                            _displaySubject(report.subject),
                            report.date,
                            _displayStatus(report.status),
                            _statusColor(report.status),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _emptyState(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.grey),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _statCard(String value, String label, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: color,
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _recentReport(
    String title,
    String time,
    String status,
    Color statusColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
