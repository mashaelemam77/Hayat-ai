import 'package:flutter/material.dart';
import '../user/my_report_screen.dart';
import '../user/notifications_screen.dart';
import '../user/submit_report_screen.dart';

class EntryScreen extends StatefulWidget {
  const EntryScreen({super.key});

  @override
  State<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen> {
  int _selectedIndex = 0;

  // هذه الشاشات اللي برمجناها
  final List<Widget> _screens = [
    const ReportsScreen(showBackButton: false), // شاشة ماي ريبورت
    const SubmitReportScreen(showBackButton: false), // شاشة إنشاء البلاغ
    const NotificationsScreen(showBackButton: false), // شاشة الإشعارات
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Reports'),
          BottomNavigationBarItem(icon: Icon(Icons.add_box), label: 'Create'),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
        ],
      ),
    );
  }
}
