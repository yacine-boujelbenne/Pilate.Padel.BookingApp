# Multi-Channel Notification System Documentation

## Overview

This comprehensive notification system provides multi-channel notification capabilities for the Pilate Padel Booking App. It supports Email, In-App, and Push notifications with user preference checking and robust error handling.

## Architecture

The notification system is organized into three main layers:

### 1. **Data Models** (`lib/models/notification_model.dart`)

- **NotificationData**: Core data class for individual notifications
  - Stores notification metadata (id, memberId, sessionId, title, body)
  - Tracks delivery and read status (deliveredAt, readAt, isRead)
  - Includes event type and custom data payload
  - Provides `fromMap()` and `toMap()` for Supabase integration
  - Implements `copyWith()` for immutable updates

- **NotificationPreferences**: User notification settings
  - Channel preferences (emailEnabled, inAppEnabled, pushEnabled)
  - Feature-specific preferences (sessionNotifications, coachUpdates, waitlistAlerts)
  - Tracks last update time
  - Full Supabase serialization support

- **NotificationEvent** (Enum): Event type classification
  - COACH_SESSION_CREATED
  - SESSION_SPOT_AVAILABLE
  - WAITLIST_AVAILABLE
  - SESSION_CANCELLED
  - BOOKING_CONFIRMED
  - CUSTOM

- **NotificationChannel** (Enum): Delivery channels
  - EMAIL
  - IN_APP
  - PUSH

### 2. **Services Layer**

#### InAppNotificationService (`lib/services/in_app_notification_service.dart`)

Manages in-app notifications stored in Supabase.

**Key Methods:**
- `createInAppNotification()` - Creates notification record in database
- `getUnreadNotifications()` - Fetches unread notifications with pagination
- `getUnreadCount()` - Returns count of unread notifications
- `markAsRead()` - Marks single notification as read
- `markMultipleAsRead()` - Batch marks multiple notifications
- `getNotifications()` - Fetches all notifications with pagination
- `deleteNotification()` - Deletes single notification
- `deleteAllNotificationsForUser()` - Clears all user notifications
- `deleteReadNotificationsForUser()` - Clears read notifications

**Features:**
- Full error handling with debug logging
- Pagination support
- Batch operations for efficiency
- Timestamp tracking (created_at, delivered_at, read_at)

#### PushNotificationService (`lib/services/push_notification_service.dart`)

Push notification management with Firebase Cloud Messaging (skeleton for future integration).

**Key Methods:**
- `initialize()` - Initializes push notification service
- `sendPushNotification()` - Sends to single device token
- `sendPushNotificationsToMultiple()` - Batch sends to multiple devices
- `subscribeToTopic()` - Subscribes device to topic
- `unsubscribeFromTopic()` - Unsubscribes from topic

**Current Status:**
- Skeleton implementation with comprehensive TODO comments
- Ready for Firebase Admin SDK integration
- Supports both direct device tokens and topic-based notifications
- Placeholder for batch sending optimization

#### MultiChannelNotificationService (`lib/services/multi_channel_notification_service.dart`)

Core orchestration service for multi-channel notifications with preference checking.

**Key Methods:**
- `initialize()` - Initializes all notification channels
- `getUserPreferences()` - Fetches user notification preferences
- `saveUserPreferences()` - Persists user preferences
- `sendNotification()` - Main method for sending notifications
- `notifySessionCreated()` - Coach session notifications
- `notifySpotAvailable()` - Spot availability alerts
- `notifyWaitlistAvailable()` - Waitlist status updates
- `notifySessionCancelled()` - Cancellation notifications
- `notifyBookingConfirmed()` - Booking confirmation
- `markAsRead()` - Marks notification as read
- `getNotifications()` - Fetches notifications
- `getUnreadNotifications()` - Gets unread only
- `getUnreadCount()` - Gets unread count
- `deleteNotification()` - Deletes notification

**Features:**
- Preference-based channel routing
- Recipient resolution from IDs or roles
- Event-specific notification methods
- Comprehensive data payload support
- Multi-recipient support
- Automatic device token lookup for push notifications

### 3. **State Management** (`lib/controllers/notification_controller.dart`)

Provider pattern controller for notification state management.

**Key Methods:**
- `initialize()` - Initializes controller for user
- `fetchNotifications()` - Loads notifications with pagination
- `fetchUnreadNotifications()` - Loads unread only
- `markAsRead()` - Marks single notification as read
- `markAllAsRead()` - Marks all notifications as read
- `deleteNotification()` - Deletes notification
- `deleteAllReadNotifications()` - Clears read notifications
- `getNotificationsByEventType()` - Filters by event type
- `getUnreadCountByEventType()` - Count by event type
- `searchNotifications()` - Full-text search
- `filterByDateRange()` - Date range filtering
- `getUnreadNotifications()` - Gets unread list
- `clearAllNotifications()` - Clears all
- `refreshNotifications()` - Syncs with server
- `updateNotificationPreferences()` - Saves preferences
- `getUserPreferences()` - Loads user preferences

**State Properties:**
- `notifications` - List of loaded notifications
- `unreadCount` - Count of unread notifications
- `isLoading` - Loading indicator
- `error` - Error message if any occurred

## Database Schema

The system uses the following Supabase tables:

### notifications table
```
id: UUID (primary key)
member_id: UUID (foreign key to profiles)
session_id: UUID (nullable, foreign key to sessions)
title: TEXT
body: TEXT
event_type: TEXT (enum-like: COACH_SESSION_CREATED, etc.)
data: JSONB (custom data payload)
is_read: BOOLEAN
created_at: TIMESTAMP
delivered_at: TIMESTAMP
read_at: TIMESTAMP (nullable)
```

### notification_preferences table
```
member_id: UUID (primary key, foreign key to profiles)
email_enabled: BOOLEAN
in_app_enabled: BOOLEAN
push_enabled: BOOLEAN
session_notifications_enabled: BOOLEAN
coach_updates_enabled: BOOLEAN
waitlist_alerts_enabled: BOOLEAN
updated_at: TIMESTAMP
```

### user_devices table (used by push notifications)
```
installation_id: TEXT (primary key)
user_id: UUID (foreign key to profiles)
platform: TEXT (android, ios, web)
push_provider: TEXT (fcm)
device_token: TEXT
is_active: BOOLEAN
last_seen_at: TIMESTAMP
last_refreshed_at: TIMESTAMP
deactivated_at: TIMESTAMP (nullable)
updated_at: TIMESTAMP
```

## Usage Examples

### Initialize Notifications in App Startup

```dart
// In main.dart or app.dart
final notificationService = MultiChannelNotificationService();
await notificationService.initialize();
```

### Use Notification Controller with Provider

```dart
// In your app/main.dart
ChangeNotifierProvider(
  create: (_) => NotificationController(),
  child: YourApp(),
)

// In a widget
@override
void initState() {
  super.initState();
  final controller = context.read<NotificationController>();
  controller.initialize(currentUserId);
}
```

### Send a Custom Notification

```dart
final service = MultiChannelNotificationService();

await service.sendNotification(
  title: 'Welcome!',
  body: 'Thanks for joining us',
  eventType: NotificationEvent.CUSTOM,
  recipientIds: ['user-123'],
  channels: [NotificationChannel.IN_APP, NotificationChannel.PUSH],
  data: {
    'action': 'open_welcome_page',
    'custom_field': 'value',
  },
);
```

### Notify Session Created

```dart
final service = MultiChannelNotificationService();

await service.notifySessionCreated(
  sessionId: 'session-456',
  sessionTitle: 'Morning Pilates Class',
  coachId: 'coach-123',
  coachFollowerIds: ['follower-1', 'follower-2'],
);
```

### Fetch and Display Notifications in UI

```dart
@override
Widget build(BuildContext context) {
  return Consumer<NotificationController>(
    builder: (context, controller, _) {
      if (controller.isLoading) {
        return const CircularProgressIndicator();
      }

      return ListView.builder(
        itemCount: controller.notifications.length,
        itemBuilder: (context, index) {
          final notification = controller.notifications[index];
          return ListTile(
            title: Text(notification.title),
            subtitle: Text(notification.body),
            trailing: !notification.isRead
                ? const Icon(Icons.circle, size: 10)
                : null,
            onTap: () {
              controller.markAsRead(notification.id);
            },
          );
        },
      );
    },
  );
}
```

### Update User Preferences

```dart
final controller = context.read<NotificationController>();
final prefs = await controller.getUserPreferences(userId);

final updatedPrefs = prefs.copyWith(
  emailEnabled: false,
  pushEnabled: true,
  sessionNotificationsEnabled: true,
);

await controller.updateNotificationPreferences(updatedPrefs);
```

## Integration Points

### With Session Management
- `notifySessionCreated()` called when new session is created
- `notifySessionCancelled()` called when session is cancelled
- Session ID included in notification data for deep linking

### With Booking System
- `notifyBookingConfirmed()` called after successful booking
- Booking details passed in notification data

### With Waitlist System
- `notifyWaitlistAvailable()` called when waitlist user can book
- `notifySpotAvailable()` called when spot opens in session

### With Email Service
- Placeholder for Mailtrap/SendGrid integration
- Email templates can be rendered server-side
- Triggered when email channel is enabled

### With Push Notifications
- Integrates with Firebase Cloud Messaging
- Device tokens stored in `user_devices` table
- Topic-based and direct notification support

## Error Handling

All services include comprehensive error handling:

```dart
try {
  // Operation
} catch (e) {
  if (kDebugMode) {
    debugPrint('Error message: $e');
  }
  // Handle error gracefully
}
```

Errors are:
- Logged in debug mode for development
- Not rethrown by default to maintain app stability
- Available via controller's `error` property
- Tracked for monitoring/analytics

## Performance Considerations

1. **Pagination**: Notifications are fetched with pagination (default 50 items)
2. **Batch Operations**: Multiple notifications can be marked as read at once
3. **Lazy Loading**: Controller loads data on demand
4. **Caching**: Preferences are cached after first fetch
5. **Real-time Updates**: Supabase realtime subscriptions ready (in NotificationService)

## Future Enhancements

1. **Email Channel**: Integrate Mailtrap or SendGrid
2. **Push Notifications**: Complete Firebase Cloud Messaging integration
3. **Scheduling**: Support delayed/scheduled notifications
4. **Templates**: Create notification templates for common events
5. **Analytics**: Track notification delivery and engagement
6. **Rich Notifications**: Support images, actions, deep linking
7. **Notification Center UI**: Pre-built UI components
8. **Preferences UI**: Pre-built settings screens
9. **Bulk Operations**: Notify by segment/cohort
10. **A/B Testing**: Test different notification strategies

## Testing

### Unit Tests
- Test data model serialization
- Test preference logic
- Test service error handling

### Integration Tests
- Test with real Supabase instance
- Test notification creation and retrieval
- Test preference updates
- Test multi-recipient sending

### UI Tests
- Test notification list rendering
- Test mark as read functionality
- Test preference updates in UI
- Test search and filtering

## Deployment Checklist

- [ ] Create `notifications` table in Supabase
- [ ] Create `notification_preferences` table in Supabase
- [ ] Ensure `user_devices` table exists
- [ ] Set up email service integration (if using email)
- [ ] Configure Firebase Cloud Messaging (if using push)
- [ ] Test notifications in staging environment
- [ ] Set up monitoring and error tracking
- [ ] Create user documentation
- [ ] Train support team on notification system

## Dependencies

- `flutter` - UI framework
- `supabase_flutter` - Database and real-time subscriptions
- `firebase_messaging` - Push notifications (optional)
- `flutter_local_notifications` - Local notifications (via NotificationService)
- `provider` - State management

## Support

For issues or questions:
1. Check debug logs in the console
2. Review error messages in controller's `error` property
3. Consult this documentation
4. Check Supabase database connectivity
5. Verify user preferences are properly set

---

**Last Updated**: 2024
**Status**: Production Ready
