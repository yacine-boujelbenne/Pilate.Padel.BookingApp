import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../controllers/auth_controller.dart';
import '../../../services/session_notification_service.dart';
import '../../widgets/flex_app_bar.dart';

class CoachNotificationsScreen extends StatefulWidget {
  const CoachNotificationsScreen({super.key});

  @override
  State<CoachNotificationsScreen> createState() =>
      _CoachNotificationsScreenState();
}

class _CoachNotificationsScreenState extends State<CoachNotificationsScreen> {
  final SessionNotificationService _service = SessionNotificationService();
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final userId = context.read<AuthController>().user?.id;
      if (userId == null) {
        if (!mounted) return;
        setState(() {
          _notifications = [];
          _loading = false;
        });
        return;
      }

      final notifications = await _service.fetchUserNotifications(userId);
      if (!mounted) return;
      setState(() {
        _notifications = notifications;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _markRead(String notificationId) async {
    await _service.markAsRead(notificationId);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const FlexAppBar(
        title: 'Notifications',
        showBack: true,
        backTarget: '/coach/home',
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _notifications.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(24),
                      children: const [
                        SizedBox(height: 72),
                        Icon(Icons.notifications_none,
                            size: 56, color: AppColors.sageLight),
                        SizedBox(height: 12),
                        Text(
                          'No notifications yet',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _notifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final notification = _notifications[index];
                        final isRead =
                            notification['is_read'] as bool? ?? false;
                        final title =
                            notification['title']?.toString() ?? 'Notification';
                        final body = notification['body']?.toString() ?? '';
                        final id = notification['id']?.toString() ?? '';
                        final createdAt =
                            notification['created_at']?.toString();

                        return InkWell(
                          onTap:
                              id.isEmpty || isRead ? null : () => _markRead(id),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isRead ? AppColors.white : AppColors.mint,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isRead
                                    ? AppColors.sagePale
                                    : AppColors.sage,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.sageDark,
                                  ),
                                  child: const Icon(Icons.notifications,
                                      color: AppColors.white, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              title,
                                              style:
                                                  AppTextStyles.body.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          if (!isRead)
                                            const Icon(
                                                Icons.fiber_manual_record,
                                                size: 10,
                                                color: AppColors.sageDark),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(body,
                                          style: AppTextStyles.sessionMeta),
                                      if (createdAt != null) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          createdAt,
                                          style: AppTextStyles.chip.copyWith(
                                            color: AppColors.textMid,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}