import 'package:flutter/material.dart';
import 'services/app_language.dart';
import 'services/api_service.dart';
import 'services/app_session.dart';
import 'services/report_service.dart';
import 'services/officer_auth_store.dart';
import 'screens/user/my_report_screen.dart';
import 'screens/user/notifications_screen.dart';
import 'screens/user/first_aid_screen.dart';
import 'screens/user/home_screen.dart';
import 'welcome_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.initialize();
  await OfficerAuthStore.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppLanguage.code,
      builder: (context, language, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Emergency System',
        theme: ThemeData(primaryColor: Colors.blue[800], useMaterial3: true),
        builder: (context, child) => Directionality(
          textDirection: language == 'ar'
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: _GlobalAppShell(child: child ?? const SizedBox.shrink()),
        ),
        home: const WelcomeScreen(),
      ),
    );
  }
}

class _GlobalAppShell extends StatefulWidget {
  const _GlobalAppShell({required this.child});

  final Widget child;

  @override
  State<_GlobalAppShell> createState() => _GlobalAppShellState();
}

class _GlobalAppShellState extends State<_GlobalAppShell> {
  final ReportService _reportService = ReportService();
  int? _lastReportCount;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _reportService.watchReports(),
      builder: (context, snapshot) {
        final reports = snapshot.data ?? const [];
        if (snapshot.hasData) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            final currentCount = reports.length;
            if (AppSession.role.value == AppRole.officer &&
                _lastReportCount != null &&
                currentCount > _lastReportCount!) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLanguage.text(
                      'New report received and needs review',
                      'يوجد بلاغ جديد يحتاج مراجعة',
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  backgroundColor: const Color(0xFFC43D35),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
            _lastReportCount = currentCount;
          });
        }

        return widget.child;
      },
    );
  }
}

class MainEntryScreen extends StatefulWidget {
  const MainEntryScreen({super.key});

  @override
  State<MainEntryScreen> createState() => _MainEntryScreenState();
}

class _MainEntryScreenState extends State<MainEntryScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeScreenContent(),
    ReportsScreen(showBackButton: false),
    NotificationsScreen(showBackButton: false),
    FirstAidPage(showBackButton: false),
  ];

  @override
  void initState() {
    super.initState();
    AppSession.role.value = AppRole.user;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue[800],
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: AppLanguage.text('Home', 'الرئيسية'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.description),
            label: AppLanguage.text('Reports', 'بلاغاتي'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.notifications),
            label: AppLanguage.text('Alerts', 'الإشعارات'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.favorite_border),
            label: AppLanguage.text('First Aid', 'إسعافات'),
          ),
        ],
      ),
    );
  }
}
