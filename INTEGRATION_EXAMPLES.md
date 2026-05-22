# Notification System - Integration Examples

## Complete Integration Scenarios

### Scenario 1: Coach Creates a New Session

When a coach creates a new session and publishes it, notify all followers.

```dart
// In SessionController or similar
Future<void> createAndPublishSession({
  required String coachId,
  required String title,
  required DateTime startAt,
  required DateTime endAt,
  required int maxParticipants,
}) async {
  try {
    // Create session in database
    final response = await _client.from('sessions').insert({
      'coach_id': coachId,
      'title': title,
      'start_at': startAt.toUtc().toIso8601String(),
      'end_at': endAt.toUtc().toIso8601String(),
      'max_participants': maxParticipants,
      'status': 'scheduled',
    }).select();

    final sessionId = response[0]['id'];

    // Get coach's followers
    final followers = await _client
        .from('follows')
        .select('follower_id')
        .eq('coach_id', coachId)
        .eq('is_active', true);

    final followerIds =
        followers.map((f) => f['follower_id'] as String).toList();

    // Send notifications to all followers
    final notificationService = MultiChannelNotificationService();
    if (followerIds.isNotEmpty) {
      await notificationService.notifySessionCreated(
        sessionId: sessionId,
        sessionTitle: title,
        coachId: coachId,
        coachFollowerIds: followerIds,
      );
    }

    _error = null;
    notifyListeners();
  } catch (e) {
    _error = e.toString();
    notifyListeners();
    rethrow;
  }
}
```

### Scenario 2: User Books a Session

Send confirmation notification when user successfully books.

```dart
// In BookingController
Future<void> bookSession({
  required String sessionId,
  required String userId,
  required String paymentMethod,
}) async {
  try {
    // Create booking
    final response = await _client.from('bookings').insert({
      'member_id': userId,
      'session_id': sessionId,
      'status': 'confirmed',
      'payment_method': paymentMethod,
      'payment_status': 'pending',
      'booked_at': DateTime.now().toUtc().toIso8601String(),
    }).select();

    final bookingId = response[0]['id'];

    // Get session details
    final session = await _client
        .from('sessions')
        .select('title, price_tnd')
        .eq('id', sessionId)
        .single();

    // Send booking confirmation notification
    final notificationService = MultiChannelNotificationService();
    await notificationService.notifyBookingConfirmed(
      bookingId: bookingId,
      sessionTitle: session['title'],
      userId: userId,
      amount: (session['price_tnd'] as num).toDouble(),
    );

    _bookings.add(Booking.fromMap(response[0]));
    _error = null;
    notifyListeners();
  } catch (e) {
    _error = e.toString();
    notifyListeners();
    rethrow;
  }
}
```

### Scenario 3: Session Spot Becomes Available

When a user cancels booking, notify waitlisted users.

```dart
// In BookingController
Future<void> cancelBooking(String bookingId) async {
  try {
    // Get booking details
    final booking = await _client
        .from('bookings')
        .select('member_id, session_id')
        .eq('id', bookingId)
        .single();

    final sessionId = booking['session_id'];

    // Mark booking as cancelled
    await _client.from('bookings').update({
      'status': 'cancelled',
      'cancelled_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', bookingId);

    // Get waitlisted users for this session
    final waitlist = await _client
        .from('waitlist')
        .select('member_id')
        .eq('session_id', sessionId)
        .order('created_at');

    final waitlistIds =
        waitlist.map((w) => w['member_id'] as String).toList();

    // Get session title
    final session = await _client
        .from('sessions')
        .select('title')
        .eq('id', sessionId)
        .single();

    // Notify waitlisted users that spot is available
    if (waitlistIds.isNotEmpty) {
      final notificationService = MultiChannelNotificationService();
      await notificationService.notifySpotAvailable(
        sessionId: sessionId,
        sessionTitle: session['title'],
        waitlistMemberIds: waitlistIds,
      );
    }

    _error = null;
    notifyListeners();
  } catch (e) {
    _error = e.toString();
    notifyListeners();
    rethrow;
  }
}
```

### Scenario 4: Coach Cancels a Session

Notify all booked members when session is cancelled.

```dart
// In SessionController
Future<void> cancelSession(String sessionId) async {
  try {
    // Get all confirmed bookings for this session
    final bookings = await _client
        .from('bookings')
        .select('member_id')
        .eq('session_id', sessionId)
        .eq('status', 'confirmed');

    final bookedMemberIds =
        bookings.map((b) => b['member_id'] as String).toList();

    // Get session details
    final session = await _client
        .from('sessions')
        .select('title')
        .eq('id', sessionId)
        .single();

    // Update session status
    await _client.from('sessions').update({
      'status': 'cancelled',
    }).eq('id', sessionId);

    // Notify all booked members
    if (bookedMemberIds.isNotEmpty) {
      final notificationService = MultiChannelNotificationService();
      await notificationService.notifySessionCancelled(
        sessionId: sessionId,
        sessionTitle: session['title'],
        bookedMemberIds: bookedMemberIds,
      );
    }

    _error = null;
    notifyListeners();
  } catch (e) {
    _error = e.toString();
    notifyListeners();
    rethrow;
  }
}
```

### Scenario 5: Display Notifications UI Page

Complete page to display user notifications.

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationController>().refreshNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          Consumer<NotificationController>(
            builder: (context, controller, _) {
              if (controller.notifications.isEmpty) {
                return const SizedBox();
              }

              return PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: const Text('Mark all as read'),
                    onTap: () {
                      controller.markAllAsRead();
                    },
                  ),
                  PopupMenuItem(
                    child: const Text('Delete all read'),
                    onTap: () {
                      controller.deleteAllReadNotifications();
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificationController>(
        builder: (context, controller, _) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${controller.error}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => controller.refreshNotifications(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (controller.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => controller.refreshNotifications(),
            child: ListView.builder(
              itemCount: controller.notifications.length,
              itemBuilder: (context, index) {
                final notification = controller.notifications[index];

                return NotificationCard(
                  notification: notification,
                  onTap: () {
                    controller.markAsRead(notification.id);
                  },
                  onDelete: () {
                    controller.deleteNotification(notification.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notification deleted')),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final NotificationData notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const NotificationCard({
    Key? key,
    required this.notification,
    required this.onTap,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: !notification.isRead
            ? Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              )
            : const SizedBox(width: 12),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.body),
            const SizedBox(height: 4),
            Text(
              _formatTime(notification.createdAt),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              child: const Text('Delete'),
              onTap: onDelete,
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
```

### Scenario 6: Notification Preferences Settings

User settings page to manage notification preferences.

```dart
class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  late NotificationPreferences _preferences;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final controller = context.read<NotificationController>();
      final userId = context.read<AuthController>().currentUserId!;
      _preferences = await controller.getUserPreferences(userId);
      setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading preferences: $e')),
        );
      }
    }
  }

  Future<void> _savePreferences() async {
    setState(() => _isSaving = true);
    try {
      final controller = context.read<NotificationController>();
      await controller.updateNotificationPreferences(_preferences);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preferences saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving preferences: $e')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Notification Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Notification Channels',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Email Notifications'),
            subtitle: const Text('Receive emails for important events'),
            value: _preferences.emailEnabled,
            onChanged: (value) {
              setState(() {
                _preferences = _preferences.copyWith(emailEnabled: value);
              });
            },
          ),
          SwitchListTile(
            title: const Text('In-App Notifications'),
            subtitle: const Text('Show notifications in the app'),
            value: _preferences.inAppEnabled,
            onChanged: (value) {
              setState(() {
                _preferences = _preferences.copyWith(inAppEnabled: value);
              });
            },
          ),
          SwitchListTile(
            title: const Text('Push Notifications'),
            subtitle: const Text('Send push notifications to your device'),
            value: _preferences.pushEnabled,
            onChanged: (value) {
              setState(() {
                _preferences = _preferences.copyWith(pushEnabled: value);
              });
            },
          ),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'Notification Types',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Session Notifications'),
            subtitle: const Text('New sessions from coaches you follow'),
            value: _preferences.sessionNotificationsEnabled,
            onChanged: (value) {
              setState(() {
                _preferences =
                    _preferences.copyWith(sessionNotificationsEnabled: value);
              });
            },
          ),
          SwitchListTile(
            title: const Text('Coach Updates'),
            subtitle: const Text('Updates from coaches you follow'),
            value: _preferences.coachUpdatesEnabled,
            onChanged: (value) {
              setState(() {
                _preferences =
                    _preferences.copyWith(coachUpdatesEnabled: value);
              });
            },
          ),
          SwitchListTile(
            title: const Text('Waitlist Alerts'),
            subtitle: const Text('Alerts when waitlist spots open'),
            value: _preferences.waitlistAlertsEnabled,
            onChanged: (value) {
              setState(() {
                _preferences =
                    _preferences.copyWith(waitlistAlertsEnabled: value);
              });
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: const Text('Save Preferences'),
            onPressed: _isSaving ? null : _savePreferences,
          ),
        ],
      ),
    );
  }
}
```

### Scenario 7: Notification Badge in Navigation

Show unread notification count in bottom navigation.

```dart
class MyHomePage extends StatelessWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Consumer<NotificationController>(
        builder: (context, notificationController, _) {
          return BottomNavigationBar(
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.search),
                label: 'Explore',
              ),
              BottomNavigationBarItem(
                icon: Badge(
                  label: notificationController.unreadCount > 0
                      ? Text(notificationController.unreadCount.toString())
                      : null,
                  child: const Icon(Icons.notifications),
                ),
                label: 'Notifications',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
            onTap: (index) {
              if (index == 2) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsPage(),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}
```

## Key Integration Points

1. **Session Creation** → `notifySessionCreated()`
2. **Booking Confirmation** → `notifyBookingConfirmed()`
3. **Booking Cancellation** → `notifySpotAvailable()`
4. **Session Cancellation** → `notifySessionCancelled()`
5. **Waitlist Updates** → `notifyWaitlistAvailable()`
6. **Settings Changes** → `updateNotificationPreferences()`
7. **UI Display** → `NotificationController` + `NotificationsPage`

---

**Status**: ✅ Ready to implement
**Last Updated**: 2024
