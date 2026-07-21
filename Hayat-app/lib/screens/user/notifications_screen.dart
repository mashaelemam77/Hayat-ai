import 'package:flutter/material.dart';
import '../../models/report_model.dart';
import '../../services/app_language.dart';
import '../../services/report_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, this.showBackButton = true});

  final bool showBackButton;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ReportService _reportService = ReportService();
  final Set<String> _readNotificationIds = {};
  List<_UserNotification> _latestNotifications = const [];

  void _markAllRead() {
    if (_latestNotifications.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLanguage.text(
              'No notifications to mark as read',
              'لا توجد إشعارات لتحديدها كمقروءة',
            ),
          ),
        ),
      );
      return;
    }

    setState(() {
      _readNotificationIds.addAll(
        _latestNotifications.map((notification) => notification.id),
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLanguage.text(
            'All notifications marked as read',
            'تم تحديد كل الإشعارات كمقروءة',
          ),
        ),
      ),
    );
  }

  List<_UserNotification> _notificationsFromReports(List<ReportModel> reports) {
    return reports.map((report) {
      final status = report.status.trim();
      final id = '${report.id}|$status';
      final title = _notificationTitle(status);
      final subtitle = AppLanguage.text(
        'Your report "${report.subject}" status is now $status.',
        'تم تحديث بلاغك "${report.subject}" إلى: $status.',
      );
      return _UserNotification(
        id: id,
        title: title,
        subtitle: subtitle,
        time: report.date.isEmpty
            ? AppLanguage.text('Now', 'الآن')
            : report.date,
        icon: _notificationIcon(status),
        iconColor: _notificationColor(status),
      );
    }).toList();
  }

  String _notificationTitle(String status) {
    if (_isClosed(status)) {
      return AppLanguage.text('Report Closed', 'تم إغلاق البلاغ');
    }
    if (_isApproved(status)) {
      return AppLanguage.text('Report Approved', 'تم اعتماد البلاغ');
    }
    if (_isInProgress(status)) {
      return AppLanguage.text('Status Update', 'تحديث الحالة');
    }
    return AppLanguage.text('Report Received', 'تم استلام البلاغ');
  }

  IconData _notificationIcon(String status) {
    if (_isClosed(status)) return Icons.check_circle_outline;
    if (_isApproved(status)) return Icons.verified_outlined;
    if (_isInProgress(status)) return Icons.autorenew;
    return Icons.notifications_active_outlined;
  }

  Color _notificationColor(String status) {
    if (_isClosed(status)) return Colors.green;
    if (_isApproved(status)) return Colors.blue;
    if (_isInProgress(status)) return Colors.orange;
    return const Color(0xFF2D3A8C);
  }

  bool _isClosed(String status) {
    return status == 'مغلق' || status == 'Closed' || status == 'Resolved';
  }

  bool _isApproved(String status) {
    return status == 'موافق' || status == 'Approved';
  }

  bool _isInProgress(String status) {
    return status == 'قيد المعالجة' ||
        status == 'قيد التنفيذ' ||
        status == 'In Progress';
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
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
                        AppLanguage.text('Notifications', 'الإشعارات'),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: _markAllRead,
                    child: Text(
                      AppLanguage.text('Mark all read', 'تحديد الكل كمقروء'),
                      style: const TextStyle(
                        color: Color(0xFF2D3A8C),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<List<ReportModel>>(
                stream: _reportService.watchReports(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2D3A8C),
                      ),
                    );
                  }

                  final notifications = _notificationsFromReports(
                    snapshot.data ?? const [],
                  );
                  _latestNotifications = notifications;
                  if (notifications.isEmpty) {
                    return Center(
                      child: Text(
                        AppLanguage.text(
                          'No notifications yet',
                          'لا توجد إشعارات حالياً',
                        ),
                        style: const TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  final unread = notifications
                      .where(
                        (notification) =>
                            !_readNotificationIds.contains(notification.id),
                      )
                      .toList();
                  final read = notifications
                      .where(
                        (notification) =>
                            _readNotificationIds.contains(notification.id),
                      )
                      .toList();

                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      if (unread.isNotEmpty) ...[
                        _sectionLabel(AppLanguage.text('New', 'جديد')),
                        const SizedBox(height: 10),
                        ...unread.map(
                          (notification) => _notifCard(
                            notification: notification,
                            isNew: true,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (read.isNotEmpty) ...[
                        _sectionLabel(AppLanguage.text('Earlier', 'سابقاً')),
                        const SizedBox(height: 10),
                        ...read.map(
                          (notification) => _notifCard(
                            notification: notification,
                            isNew: false,
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(text, style: const TextStyle(color: Colors.grey, fontSize: 13));
  }

  Widget _notifCard({
    required _UserNotification notification,
    required bool isNew,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isNew ? const Color(0xFFEEF0FB) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isNew
            ? const Border(left: BorderSide(color: Color(0xFF2D3A8C), width: 3))
            : Border.all(color: Colors.transparent),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: notification.iconColor.withValues(alpha: 0.15),
            child: Icon(
              notification.icon,
              color: notification.iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (isNew)
                      const CircleAvatar(
                        radius: 5,
                        backgroundColor: Color(0xFF2D3A8C),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notification.subtitle,
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  notification.time,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UserNotification {
  const _UserNotification({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.iconColor,
  });

  final String id;
  final String title;
  final String subtitle;
  final String time;
  final IconData icon;
  final Color iconColor;
}
