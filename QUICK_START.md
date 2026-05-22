# Notification System - Quick Start Guide

## Installation & Setup

### 1. **Add to pubspec.yaml** (already included)
```yaml
provider: ^6.1.0
supabase_flutter: ^2.3.0
firebase_messaging: ^16.2.0  # For push notifications
flutter_local_notifications: ^17.0.0
```

### 2. **Initialize in main.dart**
```dart
import 'package:flex_pilates_studio/services/multi_channel_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
  
  // Initialize notification service
  final notificationService = MultiChannelNotificationService();
  await notificationService.initialize();
  
  runApp(const MyApp());
}
```

### 3. **Add NotificationController to Provider**
```dart
import 'package:flex_pilates_studio/controllers/notification_controller.dart';

MaterialApp(
  home: MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (_) => NotificationController(),
      ),
      // ... other providers
    ],
    child: const MyHomePage(),
  ),
)
```

### 4. **Initialize Controller on User Login**
```dart
@override
void initState() {
  super.initState();
  final authController = context.read<AuthController>();
  final notificationController = context.read<NotificationController>();
  
  // Initialize notifications for current user
  notificationController.initialize(authController.currentUserId!);
}
```

## Common Usage Patterns

### Display Notifications in UI
```dart
Consumer<NotificationController>(
  builder: (context, notificationController, _) {
    final notifications = notificationController.notifications;
    
    return ListView.builder(
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return Card(
          child: ListTile(
            title: Text(notification.title),
            subtitle: Text(notification.body),
            leading: notification.isRead
                ? null
                : const Icon(Icons.circle, color: Colors.blue, size: 8),
            onTap: () {
              notificationController.markAsRead(notification.id);
            },
          ),
        );
      },
    );
  },
)
```

### Show Unread Count Badge
```dart
Consumer<NotificationController>(
  builder: (context, notificationController, _) {
    return Badge(
      label: Text(notificationController.unreadCount.toString()),
      child: IconButton(
        icon: const Icon(Icons.notifications),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(
            builder: (context) => const NotificationsPage(),
          ));
        },
      ),
    );
  },
)
```

### Send Session Created Notification
```dart
// In session creation logic
final notificationService = MultiChannelNotificationService();

await notificationService.notifySessionCreated(
  sessionId: session.id,
  sessionTitle: session.title,
  coachId: currentCoachId,
  coachFollowerIds: followerList,
);
```

### Send Spot Available Notification
```dart
// In booking cancellation/spot availability logic
final notificationService = MultiChannelNotificationService();

await notificationService.notifySpotAvailable(
  sessionId: session.id,
  sessionTitle: session.title,
  waitlistMemberIds: waitlistIds,
);
```

### Send Booking Confirmation
```dart
// After successful booking
final notificationService = MultiChannelNotificationService();

await notificationService.notifyBookingConfirmed(
  bookingId: booking.id,
  sessionTitle: session.title,
  userId: currentUserId,
  amount: session.priceTnd,
);
```

### Mark All as Read
```dart
final notificationController = context.read<NotificationController>();
await notificationController.markAllAsRead();
```

### Search Notifications
```dart
final notificationController = context.read<NotificationController>();
final results = notificationController.searchNotifications('Pilates');
```

### Filter by Event Type
```dart
final notificationController = context.read<NotificationController>();
final sessionNotifications = notificationController.getNotificationsByEventType(
  NotificationEvent.SESSION_SPOT_AVAILABLE,
);
```

### Get Unread Count by Event Type
```dart
final count = notificationController.getUnreadCountByEventType(
  NotificationEvent.BOOKING_CONFIRMED,
);
```

### Filter by Date Range
```dart
final today = DateTime.now();
final yesterday = today.subtract(const Duration(days: 1));

final todaysNotifications = notificationController.filterByDateRange(
  startDate: yesterday,
  endDate: today,
);
```

### User Preferences
```dart
// Get current preferences
final prefs = await notificationController.getUserPreferences(userId);

// Update preferences
final updatedPrefs = prefs.copyWith(
  emailEnabled: false,
  pushEnabled: true,
  sessionNotificationsEnabled: true,
);

await notificationController.updateNotificationPreferences(updatedPrefs);
```

### Refresh Notifications
```dart
// Pull latest from server
await notificationController.refreshNotifications();
```

### Clear All Notifications
```dart
// Delete all notifications for user
await notificationController.clearAllNotifications();
```

## File Structure
```
lib/
├── models/
│   └── notification_model.dart          # Data models
├── services/
│   ├── in_app_notification_service.dart # In-app channel
│   ├── push_notification_service.dart   # Push channel
│   └── multi_channel_notification_service.dart  # Orchestration
└── controllers/
    └── notification_controller.dart      # State management
```

## Data Models

### NotificationData
```dart
final notification = NotificationData(
  id: 'notif-123',
  memberId: 'user-456',
  sessionId: 'session-789',
  title: 'Session Cancelled',
  body: 'Your morning session has been cancelled',
  eventType: NotificationEvent.SESSION_CANCELLED,
  data: {
    'session_id': 'session-789',
    'refund_status': 'pending',
  },
  createdAt: DateTime.now(),
  isRead: false,
);

// Copy with changes
final readNotification = notification.copyWith(
  isRead: true,
  readAt: DateTime.now(),
);
```

### NotificationPreferences
```dart
final prefs = NotificationPreferences(
  memberId: 'user-123',
  emailEnabled: true,
  inAppEnabled: true,
  pushEnabled: false,
  sessionNotificationsEnabled: true,
  coachUpdatesEnabled: false,
  waitlistAlertsEnabled: true,
  updatedAt: DateTime.now(),
);

// Update specific field
final updated = prefs.copyWith(
  emailEnabled: false,
  pushEnabled: true,
);
```

## Event Types
```dart
NotificationEvent.COACH_SESSION_CREATED      // Coach published new session
NotificationEvent.SESSION_SPOT_AVAILABLE     // Spot opened in session
NotificationEvent.WAITLIST_AVAILABLE         // Waitlist position changed
NotificationEvent.SESSION_CANCELLED          // Session cancelled
NotificationEvent.BOOKING_CONFIRMED          // Booking confirmed
NotificationEvent.CUSTOM                     // Custom/other event
```

## Notification Channels
```dart
NotificationChannel.EMAIL    // Email notification
NotificationChannel.IN_APP   // In-app notification
NotificationChannel.PUSH     // Push notification
```

## Error Handling

All services handle errors gracefully:
```dart
try {
  await notificationController.fetchNotifications();
} catch (e) {
  // Access error via controller
  print(notificationController.error); // Shows error message
  
  // Or handle the exception
  showErrorSnackBar(context, 'Failed to load notifications');
}
```

## Debugging

Enable debug logs (automatically enabled in debug mode):
```dart
// In debug console, you'll see:
// - Notification created messages
// - Service initialization logs
// - Error details if any occur
// - Operation status updates
```

To check logs in release build, connect debugger or use crash reporting.

## Performance Tips

1. **Pagination**: Use `limit` and `offset` parameters
   ```dart
   final page2 = await controller.getNotifications(
     userId: 'user-123',
     limit: 50,
     offset: 50,
   );
   ```

2. **Only Load Unread**: When you don't need full list
   ```dart
   await controller.fetchUnreadNotifications();
   ```

3. **Batch Updates**: Mark multiple as read at once
   ```dart
   await controller.markAllAsRead();
   ```

4. **Clean Up**: Delete old read notifications
   ```dart
   await controller.deleteAllReadNotifications();
   ```

## Production Checklist

- [ ] Supabase notification_preferences table created
- [ ] All services tested with real data
- [ ] Error handling verified
- [ ] User preferences UI created
- [ ] Notification display UI created
- [ ] All integration points wired
- [ ] Firebase configured (for push)
- [ ] Email service configured (optional)
- [ ] Monitoring/analytics integrated
- [ ] User documentation provided

## Support & Resources

- See `NOTIFICATION_SYSTEM.md` for full documentation
- See `IMPLEMENTATION_SUMMARY.md` for architecture details
- Check existing services for integration patterns
- Review error logs for debugging issues

---

**Status**: ✅ Ready to integrate
**Last Updated**: 2024
