import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/notification_controller.dart';
import '../../models/notification_model.dart';
import '../widgets/modern_components.dart';
import '../widgets/modern_colors.dart';
import '../widgets/modern_theme.dart';

/// Notification center screen showing all notifications
/// Features: Grouped by date, mark as read/unread, delete, filter by type, real-time updates
class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  NotificationEvent? _selectedFilter;
  bool _showUnreadOnly = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationController>().fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: ModernColors.primaryGradient,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Notifications',
                        style: ModernTypography.headlineLarge.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Consumer<NotificationController>(
                    builder: (context, notifController, child) {
                      return Text(
                        '${notifController.unreadCount} unread',
                        style: ModernTypography.bodyMedium.copyWith(
                          color: Colors.white70,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Filter and action buttons
            Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _showUnreadOnly = !_showUnreadOnly);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: ModernSpacing.md,
                              vertical: ModernSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: _showUnreadOnly
                                  ? Colors.blue.withOpacity(0.1)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _showUnreadOnly
                                    ? Colors.blue
                                    : Colors.grey[300]!,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.filter_alt,
                                  color: _showUnreadOnly
                                      ? Colors.blue
                                      : Colors.grey[700],
                                  size: 20,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  _showUnreadOnly ? 'Unread Only' : 'All',
                                  style: ModernTypography.labelMedium.copyWith(
                                    color: _showUnreadOnly
                                        ? Colors.blue
                                        : Colors.grey[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Consumer<NotificationController>(
                        builder: (context, notifController, child) {
                          return GestureDetector(
                            onTap: () {
                              notifController.markAllAsRead();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('All notifications marked as read'),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: ModernSpacing.md,
                                vertical: ModernSpacing.sm,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.green.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.done_all,
                                    color: Colors.green.shade600,
                                    size: 20,
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Mark All',
                                    style: ModernTypography.labelMedium.copyWith(
                                      color: Colors.green.shade600,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Notifications list
            Expanded(
              child: Consumer<NotificationController>(
                builder: (context, notifController, child) {
                  if (notifController.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  var notifications = notifController.notifications;

                  // Filter by unread only
                  if (_showUnreadOnly) {
                    notifications = notifications
                        .where((n) => !n.isRead)
                        .toList();
                  }

                  if (notifications.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_off_outlined,
                            size: 64,
                            color: Colors.grey.withOpacity(0.3),
                          ),
                          SizedBox(height: 24),
                          Text(
                            'No notifications',
                            style: ModernTypography.headlineSmall.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            _showUnreadOnly
                                ? 'All your notifications are read'
                                : 'You\'re all caught up!',
                            style: ModernTypography.bodyMedium.copyWith(
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Group notifications by date
                  final groupedNotifications = _groupNotificationsByDate(notifications);

                  return RefreshIndicator(
                    onRefresh: () => notifController.refreshNotifications(),
                    child: ListView.builder(
                      padding: EdgeInsets.all(24),
                      itemCount: groupedNotifications.length,
                      itemBuilder: (context, index) {
                        final entry = groupedNotifications.entries.toList()[index];
                        return _buildDateGroup(
                          entry.key,
                          entry.value,
                          notifController,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Consumer<NotificationController>(
        builder: (context, notifController, child) {
          return FloatingActionButton.extended(
            onPressed: () => Navigator.pushNamed(context, '/notification-preferences'),
            backgroundColor: Colors.white,
            foregroundColor: Colors.blue,
            icon: const Icon(Icons.settings),
            label: const Text('Preferences'),
          );
        },
      ),
    );
  }

  Map<String, List<NotificationData>> _groupNotificationsByDate(
    List<NotificationData> notifications,
  ) {
    final grouped = <String, List<NotificationData>>{};

    for (final notification in notifications) {
      final date = notification.createdAt;
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));

      String dateKey;
      if (date.year == today.year &&
          date.month == today.month &&
          date.day == today.day) {
        dateKey = 'Today';
      } else if (date.year == yesterday.year &&
          date.month == yesterday.month &&
          date.day == yesterday.day) {
        dateKey = 'Yesterday';
      } else {
        dateKey =
            '${date.day}/${date.month}/${date.year}';
      }

      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(notification);
    }

    return grouped;
  }

  Widget _buildDateGroup(
    String dateKey,
    List<NotificationData> notifications,
    NotificationController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text(
            dateKey,
            style: ModernTypography.labelMedium.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...notifications.map((notification) {
          return _buildNotificationItem(notification, controller);
        }).toList(),
      ],
    );
  }

  Widget _buildNotificationItem(
    NotificationData notification,
    NotificationController controller,
  ) {
    final icon = _getNotificationIcon(notification.eventType);
    final color = _getNotificationColor(notification.eventType);

    return GlassCard(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      onTap: () {
        if (!notification.isRead) {
          controller.markAsRead(notification.id);
        }
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),

          SizedBox(width: 16),

          // Content
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
                        style: ModernTypography.bodyMedium.copyWith(
                          fontWeight: notification.isRead
                              ? FontWeight.w500
                              : FontWeight.w700,
                          color: notification.isRead
                              ? Colors.grey[700]
                              : Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!notification.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  notification.body,
                  style: ModernTypography.labelMedium.copyWith(
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          SizedBox(width: 16),

          // Actions
          GestureDetector(
            onTap: () {
              controller.deleteNotification(notification.id);
            },
            child: Icon(
              Icons.close,
              color: Colors.red.withOpacity(0.5),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getNotificationIcon(NotificationEvent eventType) {
    switch (eventType) {
      case NotificationEvent.SESSION_SPOT_AVAILABLE:
        return Icons.event_available;
      case NotificationEvent.WAITLIST_AVAILABLE:
        return Icons.assignment;
      case NotificationEvent.SESSION_CANCELLED:
        return Icons.cancel;
      case NotificationEvent.BOOKING_CONFIRMED:
        return Icons.check_circle;
      case NotificationEvent.COACH_SESSION_CREATED:
        return Icons.person_add;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(NotificationEvent eventType) {
    switch (eventType) {
      case NotificationEvent.SESSION_SPOT_AVAILABLE:
        return Colors.green;
      case NotificationEvent.WAITLIST_AVAILABLE:
        return Colors.orange;
      case NotificationEvent.SESSION_CANCELLED:
        return Colors.red;
      case NotificationEvent.BOOKING_CONFIRMED:
        return Colors.blue;
      case NotificationEvent.COACH_SESSION_CREATED:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
