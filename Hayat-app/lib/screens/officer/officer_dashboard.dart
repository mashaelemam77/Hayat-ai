import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/app_language.dart';
import '../../services/app_session.dart';
import '../../services/officer_auth_store.dart';
import '../../services/report_service.dart';
import '../../services/gemini_analysis_service.dart';
import '../../services/stored_audio_opener.dart';
import '../../widgets/stored_local_image.dart';
import '../../welcome_screen.dart';

class OfficerDashboard extends StatefulWidget {
  const OfficerDashboard({
    super.key,
    this.initialPassword = 'officer123',
    this.officerUsername = 'officer1',
  });

  final String initialPassword;
  final String officerUsername;

  @override
  State<OfficerDashboard> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<OfficerDashboard> {
  String _selectedPage = "لوحة التحكم";
  String _currentPassword = "1234";
  Map<String, dynamic>? _detailReport;
  final ReportService _reportService = ReportService();
  final GeminiAnalysisService _geminiTranslationService = GeminiAnalysisService();
  final Map<String, String> _translationCache = {};

  bool _isDarkMode = false;
  bool _largeFontSize = false;
  final TextEditingController _settingsCurrentPasswordCtrl =
      TextEditingController();
  final TextEditingController _settingsNewPasswordCtrl =
      TextEditingController();
  final TextEditingController _settingsConfirmPasswordCtrl =
      TextEditingController();
  String? _settingsPasswordMessage;
  bool _settingsPasswordIsError = false;
  bool _settingsObscureCurrent = true;
  bool _settingsObscureNew = true;
  bool _settingsObscureConfirm = true;

  // ── ترجمة النصوص ──
  bool get _isEnglish => !AppLanguage.isArabic;

  String _t(String ar, String en) => _isEnglish ? en : ar;
String _displayType(dynamic value) {
  final text = value?.toString().trim() ?? '';
  if (text.isEmpty) return text;

  if (_isEnglish) {
    return text
        .replaceAll('طوارئ بيئية', 'Environmental Emergency')
        .replaceAll('انهيار مبنى', 'Building Collapse')
        .replaceAll('كوارث طبيعية', 'Natural Disaster')
        .replaceAll('صيانة طرق', 'Road Maintenance')
        .replaceAll('حريق', 'Fire')
        .replaceAll('حادث', 'Accident')
        .replaceAll('أخرى', 'Other')
        .replaceAll('احتراق', 'Burning');
  }

  return text
      .replaceAll('Environmental Emergency', 'طوارئ بيئية')
      .replaceAll('Building Collapse', 'انهيار مبنى')
      .replaceAll('Natural Disaster', 'كوارث طبيعية')
      .replaceAll('Road Maintenance', 'صيانة طرق')
      .replaceAll('Accident', 'حادث')
      .replaceAll('Fire', 'حريق')
      .replaceAll('Other', 'أخرى')
      .replaceAll('Burning', 'احتراق');
}

String _displaySeverity(dynamic value) {
  final text = value?.toString().trim() ?? '';
  if (text.isEmpty) return text;

  if (_isEnglish) {
    switch (text) {
      case 'حرجة':
        return 'Critical';
      case 'عالية':
        return 'High';
      case 'متوسطة':
        return 'Medium';
      case 'منخفضة':
        return 'Low';
      default:
        return text;
    }
  }

  switch (text) {
    case 'Critical':
      return 'حرجة';
    case 'High':
      return 'عالية';
    case 'Medium':
      return 'متوسطة';
    case 'Low':
      return 'منخفضة';
    default:
      return text;
  }
}

String _displayStatus(dynamic value) {
  final text = value?.toString().trim() ?? '';
  if (text.isEmpty) return text;

  if (_isEnglish) {
    switch (text) {
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
        return text;
    }
  }

  switch (text) {
    case 'New':
      return 'جديد';
    case 'In Progress':
      return 'قيد التنفيذ';
    case 'Approved':
      return 'موافق';
    case 'Closed':
      return 'مغلق';
    default:
      return text;
  }
}

String _displayDepartment(dynamic value) {
  final text = value?.toString().trim() ?? '';
  if (!_isEnglish || text.isEmpty) return text;

  return text
      .replaceAll('الدفاع المدني', 'Civil Defense')
      .replaceAll('الشرطة', 'Police')
      .replaceAll('الهلال الأحمر', 'Red Crescent')
      .replaceAll('المرور', 'Traffic')
      .replaceAll('وزارة البيئة', 'Ministry of Environment')
      .replaceAll('أمانة المدينة', 'Municipality');
}

String _displaySubject(dynamic value) {
  final text = value?.toString().trim() ?? '';
  if (text.isEmpty) return text;

  if (_isEnglish) {
    return text
        .replaceAll('حريق خشب', 'Wood Fire')
        .replaceAll('اصطدام سيارتين', 'Two-Car Collision')
        .replaceAll('تصادم سيارتين', 'Two-Car Collision')
        .replaceAll('بلاغ عن حريق في مستودع', 'Warehouse Fire Report')
        .replaceAll('حادث مروري تصادم 3 سيارات', 'Traffic Accident - 3 Cars Collision')
        .replaceAll('وجود حفرة عميقة في طريق الملك', 'Deep Pothole on King Road')
        .replaceAll('حريق', 'Fire')
        .replaceAll('حادث', 'Accident')
        .replaceAll('احتراق', 'Burning')
        .replaceAll('خشب', 'Wood')
        .replaceAll('صيانة طرق', 'Road Maintenance')
        .replaceAll('كوارث طبيعية', 'Natural Disaster')
        .replaceAll('انهيار مبنى', 'Building Collapse')
        .replaceAll('طوارئ بيئية', 'Environmental Emergency');
  }

  return text
      .replaceAll('Wood Fire', 'حريق خشب')
      .replaceAll('Two-Car Collision', 'اصطدام سيارتين')
      .replaceAll('Two-Vehicle Collision', 'اصطدام مركبتين')
      .replaceAll('Warehouse Fire Report', 'بلاغ عن حريق في مستودع')
      .replaceAll('Traffic Accident - 3 Cars Collision', 'حادث مروري تصادم 3 سيارات')
      .replaceAll('Deep Pothole on King Road', 'وجود حفرة عميقة في طريق الملك')
      .replaceAll('Car Fire', 'حريق سيارة')
      .replaceAll('Environmental Emergency', 'طوارئ بيئية')
      .replaceAll('Building Collapse', 'انهيار مبنى')
      .replaceAll('Natural Disaster', 'كوارث طبيعية')
      .replaceAll('Road Maintenance', 'صيانة طرق')
      .replaceAll('Accident', 'حادث')
      .replaceAll('Fire', 'حريق')
      .replaceAll('Burning', 'احتراق')
      .replaceAll('Collision', 'اصطدام')
      .replaceAll('Wood', 'خشب')
      .replaceAll('Two Cars', 'سيارتين')
      .replaceAll('Car', 'سيارة')
      .replaceAll('Other', 'أخرى');
}
  
  bool _textLooksArabic(String text) => RegExp(r'[\u0600-\u06FF]').hasMatch(text);

  bool _needsAiTranslation(String text) {
    final clean = text.trim();
    if (clean.isEmpty) return false;
    final hasArabic = _textLooksArabic(clean);
    return _isEnglish ? hasArabic : !hasArabic;
  }

  Future<String> _translatedStoredText(dynamic value) async {
    final clean = value?.toString().trim() ?? '';
    if (clean.isEmpty) return clean;
    if (!_needsAiTranslation(clean)) return clean;

    final key = '${AppLanguage.code.value}::$clean';
    final cached = _translationCache[key];
    if (cached != null) return cached;

    final translated = await _geminiTranslationService.translateStoredText(
      text: clean,
      languageCode: AppLanguage.code.value,
    );
    _translationCache[key] = translated;
    return translated;
  }

  Widget _translatedDetailRow(String label, dynamic value) {
    final original = value?.toString().trim() ?? '';
    if (original.isEmpty || !_needsAiTranslation(original)) {
      return _detailRow(label, _displayValue(value));
    }

    return FutureBuilder<String>(
      future: _translatedStoredText(original),
      builder: (context, snapshot) {
        return _detailRow(label, snapshot.data ?? original);
      },
    );
  }
  static const List<String> _incidentTypes = [
    "حريق",
    "حادث",
    "صيانة طرق",
    "كوارث طبيعية",
    "انهيار مبنى",
    "طوارئ بيئية",
    "أخرى",
  ];

  static const List<String> _departments = [
    "الدفاع المدني",
    "الشرطة",
    "الهلال الأحمر",
    "المرور",
    "وزارة البيئة",
  ];

  static const List<String> _departmentsEn = [
    "Civil Defense",
    "Police",
    "Red Crescent",
    "Traffic",
    "Ministry of Environment",
  ];

  List<Map<String, dynamic>> reports = [
    {
      "id": "RPT-2401",
      "subject": "بلاغ عن حريق في مستودع",
      "date": "2026-04-16",
      "type": "حريق",
      "status": "جديد",
      "severity": "عالية",
      "location": "حي الصناعية، شارع الأمير سلطان",
      "department": "",
      "reporterName": "محمد عبدالله السهلي",
      "reporterPhone": "0501234567",
      "analysis":
          "تم رصد حريق في مستودع تجاري. يُشتبه في أن السبب قصور كهربائي. الموقف يستدعي تدخلاً فورياً من الدفاع المدني. لا يوجد إصابات مُبلَّغ عنها حتى الآن.",
    },
    {
      "id": "RPT-2402",
      "subject": "حادث مروري تصادم 3 سيارات",
      "date": "2026-04-16",
      "type": "حادث",
      "status": "قيد التنفيذ",
      "severity": "متوسطة",
      "location": "طريق الملك فهد، تقاطع مع شارع التحلية",
      "department": "المرور",
      "reporterName": "خالد عبدالرحمن القحطاني",
      "reporterPhone": "0559876543",
      "analysis":
          "تصادم بين 3 مركبات على الطريق الرئيسي. أُفيد بوجود إصابات طفيفة. الطريق مغلق جزئياً مما يسبب ازدحاماً. تم إبلاغ فرق الإسعاف.",
    },
    {
      "id": "RPT-2403",
      "subject": "وجود حفرة عميقة في طريق الملك",
      "date": "2026-04-15",
      "type": "صيانة طرق",
      "status": "مغلق",
      "severity": "منخفضة",
      "location": "طريق الملك عبدالله، الحارة اليمنى",
      "department": "أمانة المدينة",
      "reporterName": "سارة يوسف العمري",
      "reporterPhone": "0531122334",
      "analysis":
          "رصد حفرة بعمق تقريبي 40 سم في الحارة اليمنى. تشكّل خطراً على المركبات. يُوصى بإصلاحها خلال 48 ساعة.",
    },
  ];

  String _filterType = "all";
  String _filterStatus = "all";

  @override
  void initState() {
    super.initState();
    AppSession.role.value = AppRole.officer;
    _currentPassword = widget.initialPassword;
    _loadReports();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkNewReports();
    });
  }

  @override
  void dispose() {
    _settingsCurrentPasswordCtrl.dispose();
    _settingsNewPasswordCtrl.dispose();
    _settingsConfirmPasswordCtrl.dispose();
    super.dispose();
  }

  void _checkNewReports() {
    final newCount = reports.where((r) => r['status'] == 'جديد').length;
    if (newCount == 0) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _t(
            '🔔 يوجد $newCount بلاغ جديد يحتاج مراجعة',
            '🔔 $newCount new report(s) need your attention',
          ),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.red[700],
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _loadReports() async {
    final remoteReports = await _reportService.fetchReports();
    if (!mounted || remoteReports.isEmpty) return;
    setState(() {
      reports = remoteReports.map((report) => report.toOfficerMap()).toList();
    });
    _checkNewReports();
  }

  List<Map<String, dynamic>> get filteredReports {
    final activeReports = reports.where((r) => !_isClosedStatus(r)).toList();
    final filtered = activeReports.where((r) {
      final typeMatch = switch (_filterType) {
        "all" => true,
        "fire" => _hasType(r, "حريق"),
        "accident" => _hasType(r, "حادث"),
        "road_maintenance" => _hasType(r, "صيانة طرق"),
        "natural_disaster" => _hasType(r, "كوارث طبيعية"),
        "building_collapse" => _hasType(r, "انهيار مبنى"),
        "environmental_emergency" => _hasType(r, "طوارئ بيئية"),
        "other" => _hasType(r, "أخرى"),
        _ => true,
      };
      final statusMatch = switch (_filterStatus) {
        "all" || "closed" => true,
        "new" => r['status'] == "جديد",
        "in_progress" =>
          r['status'] == "قيد التنفيذ" || r['status'] == "قيد المعالجة",
        "approved" => r['status'] == "موافق",
        _ => true,
      };
      return typeMatch && statusMatch;
    }).toList();
    return _sortBySeverityDesc(filtered);
  }

  bool _isClosedStatus(Map<String, dynamic> report) {
    final status = report['status']?.toString().trim() ?? '';
    return status == 'مغلق' || status == 'Closed' || status == 'Resolved';
  }

  int _severityRank(String? severity) {
    final value = severity?.trim() ?? '';
    if (value == 'حرجة' || value == 'Critical') return 4;
    if (value == 'عالية' || value == 'High') return 3;
    if (value == 'متوسطة' || value == 'Medium') return 2;
    if (value == 'منخفضة' || value == 'Low') return 1;
    return 0;
  }

  List<Map<String, dynamic>> _sortBySeverityDesc(
    List<Map<String, dynamic>> source,
  ) {
    return [...source]..sort(
      (a, b) => _severityRank(
        b['severity']?.toString(),
      ).compareTo(_severityRank(a['severity']?.toString())),
    );
  }

  int _dateRank(Map<String, dynamic> report) {
    final rawDate = report['date']?.toString().trim() ?? '';
    final parsed = DateTime.tryParse(rawDate);
    if (parsed != null) return parsed.millisecondsSinceEpoch;

    final rawCreatedAt = report['createdAt']?.toString().trim() ?? '';
    final parsedCreatedAt = DateTime.tryParse(rawCreatedAt);
    if (parsedCreatedAt != null) return parsedCreatedAt.millisecondsSinceEpoch;

    return 0;
  }

  List<Map<String, dynamic>> _sortByNewestDesc(
    List<Map<String, dynamic>> source,
  ) {
    return [...source]..sort(
      (a, b) => _dateRank(b).compareTo(_dateRank(a)),
    );
  }

  List<Map<String, dynamic>> get _dashboardReports {
    final filtered = reports.where((r) {
      final typeMatch = switch (_filterType) {
        "all" => true,
        "fire" => _hasType(r, "حريق") || _hasType(r, "Fire"),
        "accident" => _hasType(r, "حادث") || _hasType(r, "Accident"),
        "road_maintenance" =>
          _hasType(r, "صيانة طرق") || _hasType(r, "Road Maintenance"),
        "natural_disaster" =>
          _hasType(r, "كوارث طبيعية") || _hasType(r, "Natural Disaster"),
        "building_collapse" =>
          _hasType(r, "انهيار مبنى") || _hasType(r, "Building Collapse"),
        "environmental_emergency" =>
          _hasType(r, "طوارئ بيئية") || _hasType(r, "Environmental Emergency"),
        "other" => _hasType(r, "أخرى") || _hasType(r, "Other"),
        _ => true,
      };

      final status = r['status']?.toString().trim() ?? '';
      final statusMatch = switch (_filterStatus) {
        "all" => true,
        "new" => status == "جديد" || status == "New" || status == "Submitted",
        "in_progress" =>
          status == "قيد التنفيذ" ||
          status == "قيد المعالجة" ||
          status == "In Progress",
        "approved" => status == "موافق" || status == "Approved",
        "closed" => _isClosedStatus(r),
        _ => true,
      };

      return typeMatch && statusMatch;
    }).toList();

    return _sortByNewestDesc(filtered);
  }

  List<Map<String, dynamic>> get _activeReports =>
      _sortBySeverityDesc(reports.where((r) => !_isClosedStatus(r)).toList());

  List<Map<String, dynamic>> get _closedReports =>
      _sortBySeverityDesc(reports.where(_isClosedStatus).toList());

  List<String> _reportTypes(Map<String, dynamic> report) {
    return (report['type']?.toString() ?? '')
        .split(',')
        .map((type) => type.trim())
        .where((type) => type.isNotEmpty)
        .toList();
  }

  bool _hasType(Map<String, dynamic> report, String type) {
    return _reportTypes(report).contains(type);
  }

  int _countType(String type) {
    return reports.where((report) => _hasType(report, type)).length;
  }

  // ── قوائم الفلتر حسب اللغة ──
  List<Map<String, String>> get _typeFilterItems => [
    {"value": "all", "label": _t("الكل", "All")},
    {"value": "fire", "label": _t("حريق", "Fire")},
    {"value": "accident", "label": _t("حادث", "Accident")},
    {"value": "road_maintenance", "label": _t("صيانة طرق", "Road Maintenance")},
    {
      "value": "natural_disaster",
      "label": _t("كوارث طبيعية", "Natural Disaster"),
    },
    {
      "value": "building_collapse",
      "label": _t("انهيار مبنى", "Building Collapse"),
    },
    {
      "value": "environmental_emergency",
      "label": _t("طوارئ بيئية", "Environmental Emergency"),
    },
    {"value": "other", "label": _t("أخرى", "Other")},
  ];

  List<Map<String, String>> get _statusFilterItems => [
    {"value": "all", "label": _t("الكل", "All")},
    {"value": "new", "label": _t("جديد", "New")},
    {"value": "in_progress", "label": _t("قيد المعالجة", "In Progress")},
    {"value": "approved", "label": _t("موافق", "Approved")},
    {"value": "closed", "label": _t("مغلق", "Closed")},
  ];

  // ─────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isEnglish ? TextDirection.ltr : TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _isDarkMode
            ? const Color(0xFF0D0D1A)
            : const Color(0xFFF8FAFC),
        body: Row(
          children: [
            // ───── Sidebar ─────
            Container(
              width: 260,
              color: const Color(0xFF111827),
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Center(
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.white,
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/images/hayat.png',
                                    fit: BoxFit.cover,
                                    width: 60,
                                    height: 60,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _t("منصة حياة", "Hayat Platform"),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _t(
                                  "نظام إدارة البلاغات",
                                  "Incident Management System",
                                ),
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 15),
                        _sidebarButton(
                          icon: Icons.dashboard,
                          title: _t("لوحة التحكم", "Dashboard"),
                          pageKey: "لوحة التحكم",
                        ),
                        const SizedBox(height: 5),
                        _sectionTitle(_t("البلاغات", "Reports")),
                        _sidebarButton(
                          icon: Icons.description,
                          title: _t("البلاغات", "Reports"),
                          pageKey: "البلاغات",
                          badge: "${_activeReports.length}",
                        ),
                        _sidebarButton(
                          icon: Icons.task_alt,
                          title: _t("الحالات المغلقة", "Closed Cases"),
                          pageKey: "الحالات المغلقة",
                          badge: "${_closedReports.length}",
                        ),
                        _sidebarButton(
                          icon: Icons.bar_chart,
                          title: _t(
                            "التقارير والإحصائيات",
                            "Reports & Statistics",
                          ),
                          pageKey: "التقارير والإحصائيات",
                        ),
                        const SizedBox(height: 5),
                        _sectionTitle(_t("النظام", "System")),
                        _sidebarButton(
                          icon: Icons.settings,
                          title: _t("الإعدادات", "Settings"),
                          pageKey: "الإعدادات",
                        ),
                        const SizedBox(height: 5),
                        _sidebarButton(
                          icon: Icons.logout,
                          title: _t("تسجيل الخروج", "Logout"),
                          pageKey: "تسجيل الخروج",
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // ───── Main Content ─────
            Expanded(
              child: _detailReport != null
                  ? _buildReportDetailPage(_detailReport!)
                  : _buildPageContent(),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Page router
  // ─────────────────────────────────────────────
  Widget _buildPageContent() {
    switch (_selectedPage) {
      case "البلاغات":
        return _buildReportsPage();
      case "الحالات المغلقة":
        return _buildClosedCasesPage();
      case "التقارير والإحصائيات":
        return _buildStatisticsPage();
      case "الإعدادات":
        return _buildSettingsPage();
      default:
        return _buildDashboardPage();
    }
  }

  // ─────────────────────────────────────────────
  // Dashboard page
  // ─────────────────────────────────────────────
  Widget _buildDashboardPage() {
    return Padding(
      padding: const EdgeInsets.all(25.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t(
              "إدارة العمليات والبلاغات الميدانية",
              "Field Operations & Incident Management",
            ),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 25),
          Row(
            children: [
              _statCard(
                _t("إجمالي البلاغات", "Total Reports"),
                reports.length.toString(),
                Colors.blue,
              ),
              _statCard(
                _t("حرائق", "Fires"),
                _countType("حريق").toString(),
                Colors.red,
              ),
              _statCard(
                _t("حوادث", "Accidents"),
                _countType("حادث").toString(),
                Colors.orange,
              ),
              _statCard(
                _t("حفر وصيانة", "Road Maintenance"),
                _countType("صيانة طرق").toString(),
                Colors.green,
              ),
              _statCard(
                _t("أخرى", "Other"),
                _countType("أخرى").toString(),
                Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 25),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _t("تفاصيل البلاغات", "Report Details"),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _t(
                  "مرتبة حسب الأحدث وتشمل جميع الحالات",
                  "Sorted by newest and includes all statuses",
                ),
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      _t("النوع", "Type"),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  _filterDropdown(
                    label: _t("النوع", "Type"),
                    value: _filterType,
                    items: _typeFilterItems,
                    onChanged: (v) => setState(() => _filterType = v!),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      _t("الحالة", "Status"),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  _filterDropdown(
                    label: _t("الحالة", "Status"),
                    value: _filterStatus,
                    items: _statusFilterItems,
                    onChanged: (v) => setState(() => _filterStatus = v!),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: ListView(
                children: [
                  _buildTableHeader(),
                  ..._dashboardReports.map((r) => _buildTableRow(r)),
                  if (_dashboardReports.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(30),
                      child: Center(
                        child: Text(
                          _t(
                            "لا توجد بلاغات تطابق الفلتر",
                            "No reports match the filter",
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Reports page
  // ─────────────────────────────────────────────
  Widget _buildReportsPage() {
    return Padding(
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t("البلاغات", "Reports"),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: ListView(
                children: [
                  _buildTableHeader(),
                  ..._activeReports.map((r) => _buildTableRow(r)),
                  if (_activeReports.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(30),
                      child: Center(
                        child: Text(
                          _t(
                            "لا توجد بلاغات فعالة حالياً",
                            "No active reports currently",
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Closed cases page
  // ─────────────────────────────────────────────
  Widget _buildClosedCasesPage() {
    final closedCases = _closedReports;
    return Padding(
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.task_alt, color: Colors.green, size: 30),
              const SizedBox(width: 10),
              Text(
                _t("الحالات المغلقة", "Closed Cases"),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${closedCases.length}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: closedCases.isEmpty
                  ? Center(
                      child: Text(
                        _t(
                          "لا توجد حالات مغلقة حالياً",
                          "No closed cases currently",
                        ),
                      ),
                    )
                  : ListView(
                      children: [
                        _buildTableHeader(),
                        ...closedCases.map((r) => _buildTableRow(r)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Statistics page
  // ─────────────────────────────────────────────
  Widget _buildStatisticsPage() {
    return Padding(
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t("التقارير والإحصائيات", "Reports & Statistics"),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 25),
          Text(
            _t("حسب النوع", "By Type"),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              _statCard(
                _t("إجمالي البلاغات", "Total Reports"),
                reports.length.toString(),
                Colors.blue,
              ),
              _statCard(
                _t("حرائق", "Fires"),
                _countType("حريق").toString(),
                Colors.red,
              ),
              _statCard(
                _t("حوادث", "Accidents"),
                _countType("حادث").toString(),
                Colors.orange,
              ),
              _statCard(
                _t("صيانة طرق", "Road Maintenance"),
                _countType("صيانة طرق").toString(),
                Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 25),
          Text(
            _t("حسب الحالة", "By Status"),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              _statCard(
                _t("جديد", "New"),
                reports.where((r) => r['status'] == "جديد").length.toString(),
                Colors.red,
              ),
              _statCard(
                _t("قيد المعالجة", "In Progress"),
                reports
                    .where(
                      (r) =>
                          r['status'] == "قيد التنفيذ" ||
                          r['status'] == "قيد المعالجة",
                    )
                    .length
                    .toString(),
                Colors.orange,
              ),
              _statCard(
                _t("موافق", "Approved"),
                reports.where((r) => r['status'] == "موافق").length.toString(),
                Colors.blue,
              ),
              _statCard(
                _t("مغلق", "Closed"),
                reports.where((r) => r['status'] == "مغلق").length.toString(),
                Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Settings page
  // ─────────────────────────────────────────────
  Widget _buildSettingsPage() {
    final Color bgColor = _isDarkMode
        ? const Color(0xFF0D0D1A)
        : const Color(0xFFF8FAFC);
    final Color cardColor = _isDarkMode
        ? const Color(0xFF1A1A2E)
        : Colors.white;
    final Color textColor = _isDarkMode
        ? Colors.white
        : const Color(0xFF1A1A2E);
    final Color subTextColor = _isDarkMode ? Colors.white54 : Colors.grey;
    final Color borderColor = _isDarkMode
        ? Colors.white12
        : Colors.grey.shade200;
    final double baseFontSize = _largeFontSize ? 16.0 : 14.0;

    return Container(
      color: bgColor,
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _t("الإعدادات", "Settings"),
              style: TextStyle(
                fontSize: _largeFontSize ? 28 : 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 25),
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Column(
                      children: [
                        // ══ قسم اللغة ══
                        _settingsCard(
                          cardColor: cardColor,
                          borderColor: borderColor,
                          child: StatefulBuilder(
                            builder: (ctx, setLang) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _settingsSectionHeader(
                                  icon: Icons.language,
                                  title: _t("اللغة", "Language"),
                                  textColor: textColor,
                                  fontSize: baseFontSize,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _t("لغة الواجهة", "Interface Language"),
                                  style: TextStyle(
                                    fontSize: baseFontSize - 1,
                                    color: subTextColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _isDarkMode
                                        ? const Color(0xFF0D0D1A)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: borderColor),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: AppLanguage.isArabic
                                          ? "العربية"
                                          : "English",
                                      isExpanded: true,
                                      dropdownColor: cardColor,
                                      icon: Icon(
                                        Icons.keyboard_arrow_down,
                                        color: subTextColor,
                                      ),
                                      items: ["العربية", "English"]
                                          .map(
                                            (lang) => DropdownMenuItem(
                                              value: lang,
                                              child: Text(
                                                lang,
                                                style: TextStyle(
                                                  color: textColor,
                                                  fontSize: baseFontSize,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (val) {
                                        if (val == null) return;
                                        // تطبيق اللغة مباشرةً بدون زر حفظ
                                        setState(() {});
                                        AppLanguage.code.value =
                                            val == "English" ? 'en' : 'ar';
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              val == "English"
                                                  ? "✓ Language changed to English"
                                                  : "✓ تم التغيير إلى العربية",
                                            ),
                                            backgroundColor: Colors.green,
                                            duration: const Duration(
                                              seconds: 2,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ══ قسم المظهر ══
                        _settingsCard(
                          cardColor: cardColor,
                          borderColor: borderColor,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _settingsSectionHeader(
                                icon: Icons.palette_outlined,
                                title: _t("المظهر", "Appearance"),
                                textColor: textColor,
                                fontSize: baseFontSize,
                              ),
                              const SizedBox(height: 16),
                              _settingsToggleRow(
                                title: _t(
                                  "الوضع الليلي (Dark Mode)",
                                  "Dark Mode",
                                ),
                                subtitle: _t(
                                  "تغيير مظهر الواجهة إلى الوضع الداكن",
                                  "Switch interface to dark mode",
                                ),
                                value: _isDarkMode,
                                textColor: textColor,
                                subTextColor: subTextColor,
                                fontSize: baseFontSize,
                                onChanged: (val) =>
                                    setState(() => _isDarkMode = val),
                              ),
                              Divider(color: borderColor, height: 24),
                              _settingsToggleRow(
                                title: _t("تكبير حجم الخط", "Large Font Size"),
                                subtitle: _t(
                                  "تكبير النصوص لسهولة القراءة",
                                  "Enlarge text for easier reading",
                                ),
                                value: _largeFontSize,
                                textColor: textColor,
                                subTextColor: subTextColor,
                                fontSize: baseFontSize,
                                onChanged: (val) =>
                                    setState(() => _largeFontSize = val),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ══ قسم كلمة المرور ══
                        _settingsCard(
                          cardColor: cardColor,
                          borderColor: borderColor,
                          child: StatefulBuilder(
                            builder: (context, setLocalState) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _settingsSectionHeader(
                                    icon: Icons.lock_outline,
                                    title: _t(
                                      "تغيير كلمة المرور",
                                      "Change Password",
                                    ),
                                    textColor: textColor,
                                    fontSize: baseFontSize,
                                  ),
                                  const SizedBox(height: 20),
                                  _pwdFieldStyled(
                                    label: _t(
                                      "كلمة المرور الحالية",
                                      "Current Password",
                                    ),
                                    hint: _t(
                                      "أدخل كلمة المرور الحالية",
                                      "Enter current password",
                                    ),
                                    ctrl: _settingsCurrentPasswordCtrl,
                                    obscure: _settingsObscureCurrent,
                                    isDark: _isDarkMode,
                                    fontSize: baseFontSize,
                                    toggle: () => setLocalState(
                                      () => _settingsObscureCurrent =
                                          !_settingsObscureCurrent,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _pwdFieldStyled(
                                    label: _t(
                                      "كلمة المرور الجديدة",
                                      "New Password",
                                    ),
                                    hint: _t(
                                      "أدخل كلمة المرور الجديدة",
                                      "Enter new password",
                                    ),
                                    ctrl: _settingsNewPasswordCtrl,
                                    obscure: _settingsObscureNew,
                                    isDark: _isDarkMode,
                                    fontSize: baseFontSize,
                                    toggle: () => setLocalState(
                                      () => _settingsObscureNew =
                                          !_settingsObscureNew,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _pwdFieldStyled(
                                    label: _t(
                                      "تأكيد كلمة المرور الجديدة",
                                      "Confirm New Password",
                                    ),
                                    hint: _t(
                                      "أعد إدخال كلمة المرور الجديدة",
                                      "Re-enter new password",
                                    ),
                                    ctrl: _settingsConfirmPasswordCtrl,
                                    obscure: _settingsObscureConfirm,
                                    isDark: _isDarkMode,
                                    fontSize: baseFontSize,
                                    toggle: () => setLocalState(
                                      () => _settingsObscureConfirm =
                                          !_settingsObscureConfirm,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  if (_settingsPasswordMessage != null)
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: _settingsPasswordIsError
                                            ? Colors.red.withValues(alpha: 0.1)
                                            : Colors.green.withValues(
                                                alpha: 0.1,
                                              ),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: _settingsPasswordIsError
                                              ? Colors.red.shade200
                                              : Colors.green.shade200,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            _settingsPasswordIsError
                                                ? Icons.error_outline
                                                : Icons.check_circle_outline,
                                            color: _settingsPasswordIsError
                                                ? Colors.red
                                                : Colors.green,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _settingsPasswordMessage!,
                                              style: TextStyle(
                                                color: _settingsPasswordIsError
                                                    ? Colors.red
                                                    : Colors.green,
                                                fontSize: baseFontSize - 1,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      onPressed: () async {
                                        final current =
                                            _settingsCurrentPasswordCtrl.text
                                                .trim();
                                        final newPass = _settingsNewPasswordCtrl
                                            .text
                                            .trim();
                                        final confirm =
                                            _settingsConfirmPasswordCtrl.text
                                                .trim();
                                        final savedPassword =
                                            OfficerAuthStore.officers[widget
                                                .officerUsername]?['password'] ??
                                            _currentPassword;
                                        if (current != savedPassword) {
                                          setLocalState(() {
                                            _settingsPasswordMessage = _t(
                                              "كلمة المرور الحالية غير صحيحة",
                                              "Current password is incorrect",
                                            );
                                            _settingsPasswordIsError = true;
                                          });
                                          return;
                                        }
                                        if (newPass.isEmpty) {
                                          setLocalState(() {
                                            _settingsPasswordMessage = _t(
                                              "الرجاء إدخال كلمة المرور الجديدة",
                                              "Please enter a new password",
                                            );
                                            _settingsPasswordIsError = true;
                                          });
                                          return;
                                        }
                                        if (newPass != confirm) {
                                          setLocalState(() {
                                            _settingsPasswordMessage = _t(
                                              "كلمة المرور الجديدة غير متطابقة",
                                              "Passwords do not match",
                                            );
                                            _settingsPasswordIsError = true;
                                          });
                                          return;
                                        }
                                        await OfficerAuthStore.setPassword(
                                          widget.officerUsername,
                                          newPass,
                                        );
                                        _settingsCurrentPasswordCtrl.clear();
                                        _settingsNewPasswordCtrl.clear();
                                        _settingsConfirmPasswordCtrl.clear();
                                        if (!context.mounted) return;
                                        setState(() {
                                          _currentPassword = newPass;
                                        });
                                        setLocalState(() {
                                          _settingsPasswordMessage = _t(
                                            "✅ تم تغيير كلمة المرور بنجاح",
                                            "✅ Password changed successfully",
                                          );
                                          _settingsPasswordIsError = false;
                                        });
                                      },
                                      child: Text(
                                        _t("حفظ كلمة المرور", "Save Password"),
                                        style: TextStyle(
                                          fontSize: baseFontSize + 1,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 25),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helper Widgets للإعدادات ──
  Widget _settingsCard({
    required Widget child,
    required Color cardColor,
    required Color borderColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _isDarkMode ? 0.2 : 0.04),
            blurRadius: 12,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _settingsSectionHeader({
    required IconData icon,
    required String title,
    required Color textColor,
    required double fontSize,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.red, size: 22),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: fontSize + 3,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _settingsToggleRow({
    required String title,
    required String subtitle,
    required bool value,
    required Color textColor,
    required Color subTextColor,
    required double fontSize,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(fontSize: fontSize - 2, color: subTextColor),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.red,
        ),
      ],
    );
  }

  Widget _pwdFieldStyled({
    required String label,
    required String hint,
    required TextEditingController ctrl,
    required bool obscure,
    required bool isDark,
    required double fontSize,
    required VoidCallback toggle,
  }) {
    final Color labelColor = isDark ? Colors.white70 : Colors.grey.shade700;
    final Color inputBg = isDark ? const Color(0xFF0D0D1A) : Colors.white;
    final Color inputBorder = isDark ? Colors.white24 : Colors.grey.shade300;
    final Color inputText = isDark ? Colors.white : Colors.black87;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize - 1,
            fontWeight: FontWeight.w600,
            color: labelColor,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          obscureText: obscure,
          textAlign: TextAlign.right,
          style: TextStyle(color: inputText, fontSize: fontSize),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: inputBorder, fontSize: fontSize - 1),
            filled: true,
            fillColor: inputBg,
            prefixIcon: IconButton(
              icon: Icon(
                obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: isDark ? Colors.white38 : Colors.grey,
                size: 20,
              ),
              onPressed: toggle,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: inputBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: inputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // Report Detail Page
  // ─────────────────────────────────────────────
  Widget _buildReportDetailPage(Map<String, dynamic> report) {
    return Padding(
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TextButton.icon(
                onPressed: () => setState(() => _detailReport = null),
                icon: const Icon(
                  Icons.arrow_back_ios,
                  size: 16,
                  color: Colors.red,
                ),
                label: Text(
                  _t("رجوع", "Back"),
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  backgroundColor: Colors.red.withValues(alpha: 0.07),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "${_t('تفاصيل البلاغ', 'Report Details')} ${report['id']}",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              _typeBadge(_displayType(report['type'])),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _detailCard(
                          title: _t("معلومات البلاغ", "Report Information"),
                          icon: Icons.info_outline,
                          child: StatefulBuilder(
                            builder: (ctx, setInfoEdit) {
                              bool editingInfo = false;
                              final subjectCtrl = TextEditingController(
                                text: report['subject'] ?? '',
                              );
                              final dateCtrl = TextEditingController(
                                text: report['date'] ?? '',
                              );
                              final locationCtrl = TextEditingController(
                                text: report['location'] ?? '',
                              );
                              return StatefulBuilder(
                                builder: (ctx2, setInfoInner) => Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _detailRow(
                                      _t("رقم البلاغ", "Report No."),
                                      report['id'],
                                    ),
                                    if (!editingInfo) ...[
                                      _detailRow(
                                        _t("نوع البلاغ", "Report Type"),
                                        _displayType(report['type']).isNotEmpty
                                            ? _displayType(report['type'])
                                            : _t("غير محدد", "Not specified"),
                                      ),
                                    _translatedDetailRow(
                                      _t("الموضوع", "Subject"),
                                      _displaySubject(report['subject']),
                                    ),
                                      _detailRow(
                                        _t("التاريخ", "Date"),
                                        report['date'],
                                      ),
                                      _detailRow(
                                        _t("الموقع", "Location"),
                                        _displayValue(report['location']),
                                      ),
                                      _mapLinkRow(report),
                                      const SizedBox(height: 8),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: TextButton.icon(
                                          onPressed: () => setInfoInner(
                                            () => editingInfo = true,
                                          ),
                                          icon: const Icon(
                                            Icons.edit,
                                            size: 14,
                                          ),
                                          label: Text(_t("تعديل", "Edit")),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.indigo,
                                          ),
                                        ),
                                      ),
                                    ] else ...[
                                      Text(
                                        _t("نوع البلاغ", "Report Type"),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      StatefulBuilder(
                                        builder: (ctx3, setTypeInner) {
                                          List<String> selectedTypes =
                                              (report['type']?.toString() ?? '')
                                                  .split(',')
                                                  .map((e) => e.trim())
                                                  .where((e) => e.isNotEmpty)
                                                  .toList();
                                          return Wrap(
                                            spacing: 8,
                                            runSpacing: 4,
                                            children: _incidentTypes.map((t) {
                                              final isSelected = selectedTypes
                                                  .contains(t);
                                              return FilterChip(
                                                label: Text(
                                                  t,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                selected: isSelected,
                                                selectedColor: Colors.red
                                                    .withValues(alpha: 0.2),
                                                checkmarkColor: Colors.red,
                                                onSelected: (val) {
                                                  setTypeInner(() {
                                                    if (val) {
                                                      if (!selectedTypes
                                                          .contains(t)) {
                                                        selectedTypes.add(t);
                                                      }
                                                    } else {
                                                      selectedTypes.remove(t);
                                                    }
                                                    report['type'] =
                                                        selectedTypes.join(',');
                                                  });
                                                },
                                              );
                                            }).toList(),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        _t("الموضوع", "Subject"),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      TextField(
                                        controller: subjectCtrl,
                                        textAlign: TextAlign.right,
                                        decoration: InputDecoration(
                                          isDense: true,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            borderSide: const BorderSide(
                                              color: Colors.indigo,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        _t("التاريخ", "Date"),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      TextField(
                                        controller: dateCtrl,
                                        textAlign: TextAlign.right,
                                        keyboardType: TextInputType.datetime,
                                        decoration: InputDecoration(
                                          isDense: true,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            borderSide: const BorderSide(
                                              color: Colors.indigo,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        _t("الموقع", "Location"),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      TextField(
                                        controller: locationCtrl,
                                        textAlign: TextAlign.right,
                                        decoration: InputDecoration(
                                          isDense: true,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            borderSide: const BorderSide(
                                              color: Colors.indigo,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.indigo,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            onPressed: () async {
                                              final subject = subjectCtrl.text
                                                  .trim();
                                              final date = dateCtrl.text.trim();
                                              final location = locationCtrl.text
                                                  .trim();
                                              setState(() {
                                                report['subject'] = subject;
                                                report['date'] = date;
                                                report['location'] = location;
                                              });
                                              await _reportService
                                                  .updateReport(report['id'], {
                                                    'subject': subject,
                                                    'date': date,
                                                    'location': location,
                                                  });
                                              if (!mounted) return;
                                              setInfoInner(
                                                () => editingInfo = false,
                                              );
                                            },
                                            child: Text(_t("حفظ", "Save")),
                                          ),
                                          const SizedBox(width: 8),
                                          TextButton(
                                            onPressed: () => setInfoInner(
                                              () => editingInfo = false,
                                            ),
                                            child: Text(_t("إلغاء", "Cancel")),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        _detailCard(
                          title: _t("بيانات المبلغ", "Reporter Info"),
                          icon: Icons.person_outline,
                          iconColor: Colors.teal,
                          child: Column(
                            children: [
                              _detailRow(
                                _t("اسم المبلغ", "Reporter Name"),
                                _displayValue(
                                  report['reporterName'] ??
                                      _fallbackReporterName(report),
                                ),
                              ),
                              _detailRow(
                                _t("رقم الجوال", "Phone Number"),
                                _displayValue(
                                  report['reporterPhone'] ??
                                      _fallbackReporterPhone(report),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _detailCard(
                          title: _t(
                            "الحالة والجهة المحالة",
                            "Status & Referred Department",
                          ),
                          icon: Icons.tune,
                          child: StatefulBuilder(
                            builder: (ctx, setLocal) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _readOnlyInfoBox(
                                  label: _t(
                                    'نوع البلاغ من Gemini',
                                    'Gemini Report Type',
                                  ),
                                  value: _displayType(report['type']),
                                  icon: Icons.auto_awesome,
                                  color: Colors.indigo,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _t("الحالة", "Status"),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _editableDropdown(
                                  value: report['status'],
                                  items: [
                                    "جديد",
                                    "قيد المعالجة",
                                    "قيد التنفيذ",
                                    "موافق",
                                    "مغلق",
                                  ],
                                  color: _statusColor(report['status']),
                                  onChanged: (v) async {
                                    if (v == null) return;
                                    setState(() => report['status'] = v);
                                    await _reportService.updateReport(
                                      report['id'],
                                      {'status': v},
                                    );
                                    if (!mounted) return;
                                    _showStatusSnackbar(v, report['id']);
                                    setLocal(() {});
                                  },
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _t("مستوى الخطورة", "Severity Level"),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _editableDropdown(
                                  value: report['severity'],
                                  items: ["منخفضة", "متوسطة", "عالية", "حرجة"],
                                  color: _severityColor(report['severity']),
                                  onChanged: (v) async {
                                    if (v == null) return;
                                    setState(() => report['severity'] = v);
                                    await _reportService.updateReport(
                                      report['id'],
                                      {'severity': v},
                                    );
                                    if (!mounted) return;
                                    setLocal(() {});
                                  },
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _t("الجهة المحالة", "Referred Department"),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // ── multi-select checkboxes with StatefulBuilder ──
                                StatefulBuilder(
                                  builder: (ctx2, setDeptState) {
                                    List<String> currentDepts = [];
                                    final dept = report['department'];
                                    if (dept is List) {
                                      currentDepts = List<String>.from(dept);
                                    } else if (dept is String &&
                                        dept.isNotEmpty) {
                                      currentDepts = dept
                                          .split(',')
                                          .map((e) => e.trim())
                                          .where((e) => e.isNotEmpty)
                                          .toList();
                                    }
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ..._departments.map((d) {
                                          final label = _displayDepartment(d);
                                          return CheckboxListTile(
                                            dense: true,
                                            contentPadding: EdgeInsets.zero,
                                            title: Text(
                                              label,
                                              style: const TextStyle(
                                                fontSize: 13,
                                              ),
                                            ),
                                            value: currentDepts.contains(d),
                                            activeColor: Colors.blue,
                                            onChanged: (checked) {
                                              setDeptState(() {
                                                if (checked == true) {
                                                  if (!currentDepts.contains(
                                                    d,
                                                  )) {
                                                    currentDepts.add(d);
                                                  }
                                                } else {
                                                  currentDepts.remove(d);
                                                }
                                                report['department'] =
                                                    currentDepts.join(',');
                                              });
                                              setLocal(() {});
                                            },
                                          );
                                        }),
                                        const SizedBox(height: 8),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            icon: const Icon(
                                              Icons.send,
                                              size: 14,
                                            ),
                                            label: Text(_t("إحالة", "Refer")),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.blue,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 14,
                                                    vertical: 10,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            onPressed: () async {
                                              if (currentDepts.isEmpty) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      _t(
                                                        'يرجى اختيار جهة واحدة على الأقل',
                                                        'Please select at least one department',
                                                      ),
                                                    ),
                                                    backgroundColor: Colors.red,
                                                    behavior: SnackBarBehavior
                                                        .floating,
                                                    margin:
                                                        const EdgeInsets.all(
                                                          16,
                                                        ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                    ),
                                                  ),
                                                );
                                                return;
                                              }
                                              if (!mounted) return;
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    _t(
                                                      '✅ تمت إحالة البلاغ ${report['id']} إلى ${currentDepts.join('، ')}',
                                                      '✅ Report ${report['id']} referred to ${_departmentDisplay(currentDepts.join(', '))}',
                                                    ),
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  backgroundColor: Colors.green,
                                                  duration: const Duration(
                                                    seconds: 4,
                                                  ),
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                  margin: const EdgeInsets.all(
                                                    16,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                ),
                                              );
                                              _showForwardSuccessDialog(
                                                report['id'],
                                                currentDepts.join('، '),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _detailCard(
                          title: _t("التحليل الذكي", "AI Analysis"),
                          icon: Icons.auto_awesome,
                          iconColor: Colors.purple,
                          child: FutureBuilder<String>(
                            future: _translatedStoredText(
                              report['aiAnalysis'] ??
                                  report['ai_analysis'] ??
                                  report['analysis'] ??
                                  '',
                            ),
                            builder: (context, snapshot) {
                              final original = (report['aiAnalysis'] ??
                                      report['ai_analysis'] ??
                                      report['analysis'] ??
                                      '')
                                  .toString();

                              return _analysisBox(
                                snapshot.data ?? original,
                                emptyText: _t(
                                  "لا يوجد تحليل متاح",
                                  "No analysis available",
                                ),
                                color: Colors.purple,
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        _detailCard(
                          title: _t("تحليل الصورة", "Image Analysis"),
                          icon: Icons.image_search,
                          iconColor: Colors.indigo,
                          child: FutureBuilder<String>(
                            future: _translatedStoredText(
                              report['imageAnalysis'] ??
                                  report['image_analysis'] ??
                                  '',
                            ),
                            builder: (context, snapshot) {
                              final original = (report['imageAnalysis'] ??
                                      report['image_analysis'] ??
                                      '')
                                  .toString();

                              return _analysisBox(
                                snapshot.data ?? original,
                                emptyText: _t(
                                  "لا يوجد تحليل للصورة",
                                  "No image analysis available",
                                ),
                                color: Colors.indigo,
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        _detailCard(
                          title: _t("تحليل الصوت", "Audio Analysis"),
                          icon: Icons.graphic_eq,
                          iconColor: Colors.teal,
                          child: FutureBuilder<String>(
                            future: _translatedStoredText(
                              report['audioAnalysis'] ??
                                  report['audio_analysis'] ??
                                  '',
                            ),
                            builder: (context, snapshot) {
                              final original = (report['audioAnalysis'] ??
                                      report['audio_analysis'] ??
                                      '')
                                  .toString();

                              return _analysisBox(
                                snapshot.data ?? original,
                                emptyText: _t(
                                  "لا يوجد تحليل أو تفريغ للصوت",
                                  "No audio analysis or transcript available",
                                ),
                                color: Colors.teal,
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        _detailCard(
                          title: _t("صورة البلاغ", "Report Image"),
                          icon: Icons.image_outlined,
                          child: Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child:
                                (report['image'] != null &&
                                    (report['image'] as String).isNotEmpty)
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: _buildReportImage(
                                      report['image'] as String,
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.image_not_supported_outlined,
                                        size: 48,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _t(
                                          "لا توجد صورة مرفقة",
                                          "No image attached",
                                        ),
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _detailCard(
                          title: _t(
                            "تسجيل صوت البلاغ",
                            "Report Voice Recording",
                          ),
                          icon: Icons.play_circle_outline,
                          iconColor: Colors.teal,
                          child: _audioAttachmentBox(
                            report['audio']?.toString() ?? '',
                          ),
                        ),
                        const SizedBox(height: 16),
                        _detailCard(
                          title: _t("مرفق البلاغ", "Report Document"),
                          icon: Icons.attach_file,
                          iconColor: Colors.blueGrey,
                          child: _analysisBox(
                            report['document']?.toString() ?? '',
                            emptyText: _t(
                              "لا يوجد مستند مرفق",
                              "No document attached",
                            ),
                            color: Colors.blueGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Dialog تأكيد الإحالة
  // ─────────────────────────────────────────────
  void _showForwardSuccessDialog(String reportId, String department) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 44,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                _t("تمت الإحالة بنجاح", "Referral Successful"),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _t("رقم البلاغ", "Report No."),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          reportId,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _t("الجهة المحالة إليها", "Referred To"),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          _departmentDisplay(department),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _t(
                  "تم إرسال البلاغ إلى $department وسيتم متابعته من قِبلهم",
                  "The report has been sent and will be followed up by the department",
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    _t("حسناً", "OK"),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _departmentDisplay(String departments) {
    final selected = departments
        .split(RegExp(r'[,،]'))
        .map((dept) => dept.trim())
        .where((dept) => dept.isNotEmpty)
        .toList();
    if (!_isEnglish) return selected.join('، ');
    return selected
        .map((dept) {
          final index = _departments.indexOf(dept);
          return index >= 0 ? _departmentsEn[index] : dept;
        })
        .join(', ');
  }

  // ─────────────────────────────────────────────
  // Table helpers
  // ─────────────────────────────────────────────
  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      color: Colors.grey[50],
      child: Row(
        children: [
          Expanded(
            child: Text(
              _t("رقم البلاغ", "Report No."),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _t("الموضوع", "Subject"),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              _t("التاريخ", "Date"),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              _t("النوع", "Type"),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: Text(
              _t("الخطورة", "Severity"),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: Text(
              _t("الحالة", "Status"),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Text(
              _t("الإجراءات", "Actions"),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(Map<String, dynamic> report) {
    return InkWell(
      onTap: () => setState(() => _detailReport = report),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF1F1F1))),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                report['id'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(flex: 2, child: Text(_displaySubject(report['subject']))),
            Expanded(
              child: Text(
                report['date'],
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            SizedBox(width: 100, child: _typeBadge(_displayType(report['type']))),
            const SizedBox(width: 8),
            SizedBox(width: 110, child: _severityDropdown(report)),
            const SizedBox(width: 8),
            SizedBox(width: 110, child: _statusDropdown(report)),
            const SizedBox(width: 8),
            // ── الإجراءات: إحالة، تعديل، حذف فقط ──
            SizedBox(
              width: 100,
              child: PopupMenuButton<String>(
                tooltip: _t("العمليات المتاحة", "Available Actions"),
                icon: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _t("إجراء", "Action"),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down, size: 14),
                    ],
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: "forward",
                    child: Row(
                      children: [
                        const Icon(
                          Icons.forward_to_inbox,
                          color: Colors.blue,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _t("إحالة", "Refer"),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: "edit",
                    child: Row(
                      children: [
                        const Icon(Icons.edit, color: Colors.orange, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          _t("تعديل", "Edit"),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: "delete",
                    child: Row(
                      children: [
                        const Icon(Icons.delete, color: Colors.red, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          _t("حذف", "Delete"),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  switch (value) {
                    case "forward":
                      _forwardReport(report);
                      break;
                    case "edit":
                      _editReport(report);
                      break;
                    case "delete":
                      _deleteReport(report);
                      break;
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Status Snackbar
  // ─────────────────────────────────────────────
  void _showStatusSnackbar(String status, String reportId) {
    final Map<String, Map<String, dynamic>> config = {
      'جديد': {
        'color': Colors.red,
        'ar': 'تم تعيين البلاغ $reportId كجديد',
        'en': 'Report $reportId marked as New',
      },
      'قيد المعالجة': {
        'color': Colors.orange,
        'ar': '⏳ البلاغ $reportId قيد المعالجة',
        'en': '⏳ Report $reportId is In Progress',
      },
      'قيد التنفيذ': {
        'color': Colors.orange,
        'ar': '🔧 البلاغ $reportId قيد التنفيذ',
        'en': '🔧 Report $reportId is being Executed',
      },
      'موافق': {
        'color': Colors.blue,
        'ar': '✅ تمت الموافقة على البلاغ $reportId',
        'en': '✅ Report $reportId has been Approved',
      },
      'مغلق': {
        'color': Colors.green,
        'ar': '🔒 تم إغلاق البلاغ $reportId بنجاح',
        'en': '🔒 Report $reportId has been Closed',
      },
    };
    final c = config[status];
    if (c == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isEnglish ? c['en'] as String : c['ar'] as String,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: c['color'] as Color,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Actions
  // ─────────────────────────────────────────────
  void _forwardReport(Map<String, dynamic> report) {
    // تحويل department لـ List بغض النظر عن نوعه
    List<String> selectedDepts = [];
    final dept = report['department'];
    if (dept is List) {
      selectedDepts = List<String>.from(dept);
    } else if (dept is String && dept.isNotEmpty) {
      selectedDepts = dept
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.forward_to_inbox, color: Colors.blue),
              const SizedBox(width: 8),
              Text("${_t('إحالة البلاغ', 'Refer Report')} ${report['id']}"),
            ],
          ),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t(
                    "اختر الجهات المختصة (يمكن اختيار أكثر من جهة)",
                    "Select departments (multiple allowed)",
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                ..._departments.map((d) {
                  final label = _isEnglish
                      ? _departmentsEn[_departments.indexOf(d)]
                      : d;
                  return CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(label, style: const TextStyle(fontSize: 13)),
                    value: selectedDepts.contains(d),
                    activeColor: Colors.blue,
                    onChanged: (checked) => setLocal(() {
                      if (checked == true) {
                        if (!selectedDepts.contains(d)) selectedDepts.add(d);
                      } else {
                        selectedDepts.remove(d);
                      }
                    }),
                  );
                }),
                if (selectedDepts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _t(
                        'يرجى اختيار جهة واحدة على الأقل',
                        'Please select at least one department',
                      ),
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(_t("إلغاء", "Cancel")),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.send, size: 16),
              label: Text(_t("إحالة", "Refer")),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                if (selectedDepts.isEmpty) return;
                setState(() => report['department'] = selectedDepts.join(','));
                if (!context.mounted) return;
                Navigator.pop(context);
                _showForwardSuccessDialog(
                  report['id'],
                  selectedDepts.join('، '),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _editReport(Map<String, dynamic> report) {
    final subjectCtrl = TextEditingController(text: report['subject']);
    final selectedTypes = _reportTypes(report);
    String selectedStatus = report['status'];
    String selectedSeverity = report['severity'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.edit, color: Colors.orange),
              const SizedBox(width: 8),
              Text("${_t('تعديل البلاغ', 'Edit Report')} ${report['id']}"),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t("الموضوع", "Subject"),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: subjectCtrl,
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.orange),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _t("النوع", "Type"),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: _incidentTypes.map((type) {
                    return FilterChip(
                      label: Text(type),
                      selected: selectedTypes.contains(type),
                      selectedColor: Colors.orange.withValues(alpha: 0.18),
                      checkmarkColor: Colors.orange,
                      onSelected: (checked) => setLocalState(() {
                        if (checked) {
                          if (!selectedTypes.contains(type)) {
                            selectedTypes.add(type);
                          }
                        } else {
                          selectedTypes.remove(type);
                        }
                      }),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text(
                  _t("مستوى الخطورة", "Severity Level"),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _dialogDropdown(
                  value: selectedSeverity,
                  items: ["منخفضة", "متوسطة", "عالية", "حرجة"],
                  onChanged: (v) => setLocalState(() => selectedSeverity = v!),
                ),
                const SizedBox(height: 16),
                Text(
                  _t("الحالة", "Status"),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _dialogDropdown(
                  value: selectedStatus,
                  items: [
                    "جديد",
                    "قيد المعالجة",
                    "قيد التنفيذ",
                    "موافق",
                    "مغلق",
                  ],
                  onChanged: (v) => setLocalState(() => selectedStatus = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(_t("إلغاء", "Cancel")),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                final subject = subjectCtrl.text.trim();
                if (subject.isEmpty || selectedTypes.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _t(
                          'يرجى إدخال الموضوع واختيار نوع واحد على الأقل',
                          'Please enter a subject and select at least one type',
                        ),
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                final joinedTypes = selectedTypes.join(',');
                setState(() {
                  report['subject'] = subject;
                  report['type'] = joinedTypes;
                  report['status'] = selectedStatus;
                  report['severity'] = selectedSeverity;
                });
                await _reportService.updateReport(report['id'], {
                  'subject': subject,
                  'type': joinedTypes,
                  'status': selectedStatus,
                  'severity': selectedSeverity,
                });
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_t('تم حفظ التعديلات', 'Changes saved')),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: Text(_t("حفظ التعديلات", "Save Changes")),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteReport(Map<String, dynamic> report) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(_t("حذف البلاغ", "Delete Report")),
        content: Text(
          "${_t('هل أنت متأكد من حذف البلاغ', 'Are you sure you want to delete report')} ${report['id']}؟",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_t("إلغاء", "Cancel")),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              _t("حذف", "Delete"),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _reportService.deleteReport(report['id']);
      if (!mounted) return;
      setState(() {
        reports.remove(report);
        if (_detailReport == report) _detailReport = null;
      });
    }
  }

  void _confirmLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_t("تأكيد تسجيل الخروج", "Confirm Logout")),
        content: Text(
          _t(
            "هل أنت متأكد من تسجيل الخروج؟",
            "Are you sure you want to logout?",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_t("إلغاء", "Cancel")),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(_t("خروج", "Logout")),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      AppSession.role.value = null;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (_) => false,
      );
    }
  }

  // ─────────────────────────────────────────────
  // Widget helpers
  // ─────────────────────────────────────────────
  Widget _analysisBox(
    String text, {
    required String emptyText,
    required Color color,
  }) {
    final content = text.trim();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Text(
        content.isEmpty ? emptyText : content,
        style: TextStyle(
          fontSize: 14,
          height: 1.7,
          color: content.isEmpty
              ? Colors.grey.shade600
              : const Color(0xFF333333),
        ),
      ),
    );
  }

  Widget _audioAttachmentBox(String audioPath) {
    final path = audioPath.trim();
    if (path.isEmpty || path == 'null' || path == 'N/A') {
      return _analysisBox(
        '',
        emptyText: _t('لا يوجد تسجيل صوتي مرفق', 'No voice recording attached'),
        color: Colors.teal,
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.teal.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.teal.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.graphic_eq, color: Colors.teal),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _t('يوجد تسجيل صوتي مرفق', 'Voice recording attached'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _audioLabel(path),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openAudio(path),
              icon: const Icon(Icons.play_arrow),
              label: Text(_t('تشغيل الصوت', 'Play Voice')),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _readOnlyInfoBox({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final display = _displayValue(value);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  display,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _audioLabel(String path) {
    if (path.startsWith('data:audio/')) {
      return _t('ملف صوت مرفق', 'Attached audio file');
    }
    final normalized = path.replaceAll('\\', '/');
    return normalized.split('/').last;
  }

  Future<void> _openAudio(String path) async {
    if (!await openStoredAudio(path)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t('تعذر فتح التسجيل الصوتي', 'Unable to open voice recording'),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildReportImage(String imagePath) {
    final path = imagePath.trim();
    if (path.startsWith('data:image/')) {
      try {
        final commaIndex = path.indexOf(',');
        if (commaIndex > 0) {
          final bytes = base64Decode(path.substring(commaIndex + 1));
          return Image.memory(
            bytes,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _missingImage(path),
          );
        }
      } catch (_) {
        return _missingImage(path);
      }
    }

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _missingImage(path),
      );
    }

    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _missingImage(path),
      );
    }

    return buildStoredLocalImage(path, _missingImage);
  }

  Widget _missingImage(String imagePath) {
    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: 42,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            _t(
              "تعذر عرض الصورة المرفقة",
              "Unable to display the attached image",
            ),
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          if (imagePath.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              imagePath,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailCard({
    required String title,
    required IconData icon,
    required Widget child,
    Color iconColor = Colors.red,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          child,
        ],
      ),
    );
  }

  String _displayValue(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty || text == 'null' || text == 'N/A') {
      return _t("غير محدد", "Not specified");
    }
    return text;
  }

  String _fallbackReporterName(Map<String, dynamic> report) {
    final raw = report['rawReportText']?.toString() ?? '';
    final match = RegExp(r'المبلّغ:\s*([^|\n]+)').firstMatch(raw);
    return match?.group(1)?.trim() ?? '';
  }

  String _fallbackReporterPhone(Map<String, dynamic> report) {
    final raw = report['rawReportText']?.toString() ?? '';
    final match = RegExp(r'هاتف:\s*([^\n]+)').firstMatch(raw);
    return match?.group(1)?.trim() ?? '';
  }

  String _mapLinkForReport(Map<String, dynamic> report) {
    final direct = report['mapsUrl']?.toString().trim() ?? '';
    if (direct.isNotEmpty && direct != 'null' && direct != 'N/A') return direct;

    final location = report['location']?.toString() ?? '';
    final match = RegExp(
      r'(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)',
    ).firstMatch(location);
    if (match == null) return _t("غير محدد", "Not specified");
    return 'https://www.google.com/maps?q=${match.group(1)},${match.group(2)}';
  }

  Widget _mapLinkRow(Map<String, dynamic> report) {
    final link = _mapLinkForReport(report);
    final canOpen = link.startsWith('http://') || link.startsWith('https://');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              _t("رابط الخريطة", "Map Link"),
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: canOpen
                ? InkWell(
                    onTap: () async {
                      final uri = Uri.parse(link);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                    child: Text(
                      link,
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  )
                : Text(
                    link,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool selectable = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: selectable
                ? SelectableText(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _editableDropdown({
    required String value,
    required List<String> items,
    required Color color,
    required ValueChanged<String?> onChanged,
  }) {
    final dropdownValue = items.contains(value) ? value : items.first;

    String displayLabel(String item) {
      if (items.contains('حرجة') || items.contains('عالية')) {
        return _displaySeverity(item);
      }
      if (items.contains('جديد') || items.contains('قيد المعالجة')) {
        return _displayStatus(item);
      }
      return item;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: dropdownValue,
          isExpanded: true,
          dropdownColor: Colors.white,
          icon: Icon(Icons.arrow_drop_down, color: color),
          selectedItemBuilder: (context) => items
              .map(
                (s) => Text(
                  displayLabel(s),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              )
              .toList(),
          items: items
              .map(
                (s) => DropdownMenuItem(
                  value: s,
                  child: Text(
                    displayLabel(s),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _dialogDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final dropdownValue = items.contains(value) ? value : items.first;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: dropdownValue,
          isExpanded: true,
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _typeBadge(String type) {
    final types = type
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
    final display = types.isEmpty
        ? _t("غير محدد", "Not specified")
        : types.join('، ');
    final primaryType = types.isEmpty ? type : types.first;
    Color color;
    switch (primaryType) {
      case "حريق":
        color = Colors.red;
        break;
      case "حادث":
        color = Colors.orange;
        break;
      case "صيانة طرق":
        color = Colors.green;
        break;
      case "بلاغ عام":
        color = Colors.purple;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        display,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case "حرجة":
        return Colors.red.shade900;
      case "عالية":
        return Colors.red;
      case "متوسطة":
        return Colors.orange;
      case "منخفضة":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case "جديد":
        return Colors.red;
      case "قيد التنفيذ":
      case "قيد المعالجة":
        return Colors.orange;
      case "مغلق":
        return Colors.green;
      case "موافق":
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _statCard(String title, String count, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border(right: BorderSide(color: color, width: 4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
            const SizedBox(height: 4),
            Text(
              count,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sidebarButton({
    required IconData icon,
    required String title,
    required String pageKey,
    String? badge,
  }) {
    final isActive = _selectedPage == pageKey && _detailReport == null;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.red : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        trailing: badge != null
            ? Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  badge,
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              )
            : null,
        onTap: () {
          if (pageKey == "تسجيل الخروج") {
            _confirmLogout();
          } else {
            setState(() {
              _selectedPage = pageKey;
              _detailReport = null;
            });
          }
        },
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
    );
  }

  Widget _filterDropdown({
    required String label,
    required String value,
    required List<Map<String, String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: items
              .map(
                (e) => DropdownMenuItem<String>(
                  value: e["value"]!,
                  child: Text(e["label"]!),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _statusDropdown(Map<String, dynamic> report) {
    Color color = _statusColor(report['status']);
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: report['status'],
          isExpanded: true,
          dropdownColor: Colors.white,
          iconSize: 16,
          icon: Icon(Icons.arrow_drop_down, color: color),
          selectedItemBuilder: (context) => ["جديد", "قيد المعالجة", "قيد التنفيذ", "موافق", "مغلق"]
              .map(
                (status) => Text(
                  _displayStatus(status),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _statusColor(status),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              )
              .toList(),
          items: ["جديد", "قيد المعالجة", "قيد التنفيذ", "موافق", "مغلق"]
              .map(
                (status) => DropdownMenuItem(
                  value: status,
                  child: Text(
                    _displayStatus(status),
                    style: TextStyle(
                      color: _statusColor(status),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) async {
            if (value == null) return;
            setState(() => report['status'] = value);
            await _reportService.updateReport(report['id'], {'status': value});
            if (!mounted) return;
            _showStatusSnackbar(value, report['id']);
          },
        ),
      ),
    );
  }

  Widget _severityDropdown(Map<String, dynamic> report) {
    Color color = _severityColor(report['severity']);
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: report['severity'],
          isExpanded: true,
          dropdownColor: Colors.white,
          iconSize: 16,
          icon: Icon(Icons.arrow_drop_down, color: color),
          selectedItemBuilder: (context) => ["منخفضة", "متوسطة", "عالية", "حرجة"]
              .map(
                (severity) => Text(
                  _displaySeverity(severity),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _severityColor(severity),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              )
              .toList(),
          items: ["منخفضة", "متوسطة", "عالية", "حرجة"]
              .map(
                (severity) => DropdownMenuItem(
                  value: severity,
                  child: Text(
                    _displaySeverity(severity),
                    style: TextStyle(
                      color: _severityColor(severity),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) async {
            if (value == null) return;
            setState(() => report['severity'] = value);
            await _reportService.updateReport(report['id'], {
              'severity': value,
            });
          },
        ),
      ),
    );
  }
}
