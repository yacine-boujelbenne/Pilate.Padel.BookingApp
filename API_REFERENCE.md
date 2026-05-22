# API Reference

**Complete API documentation for all notification system services and controllers**

---

## Table of Contents

1. [Data Models](#data-models)
2. [NotificationController](#notificationcontroller)
3. [FollowController](#followcontroller)
4. [MultiChannelNotificationService](#multichannelnotificationservice)
5. [InAppNotificationService](#inappnotificationservice)
6. [MailtrapService](#mailtrapservice)
7. [PushNotificationService](#pushnotificationservice)
8. [Error Codes](#error-codes)

---

## Data Models

### NotificationData

Represents a single notification.

```dart
class NotificationData {
  final String id;                    // UUID, auto-generated
  final String memberId;              // Recipient user ID (UUID)
  final String? sessionId;            // Optional related session (UUID)
  final String title;                 // Notification title (max 200 chars)
  final String body;                  // Notification body (max 1000 chars)
  final NotificationEvent eventType;  // Type of event that triggered
  final Map<String, dynamic> data;    // Custom payload
  final DateTime? deliveredAt;        // When first delivered
  final DateTime? readAt;             // When user read it
  final DateTime createdAt;           // When created
  final bool isRead;                  // Read status
}
```

#### Factory Methods

```dart
// Create from Supabase map
NotificationData.fromMap(Map<String, dynamic> map)

// Convert to map for database
Map<String, dynamic> toMap()

// Create modified copy
NotificationData copyWith({
  String? id,
  String? memberId,
  String? sessionId,
  String? title,
  String? body,
  NotificationEvent? eventType,
  Map<String, dynamic>? data,
  DateTime? deliveredAt,
  DateTime? readAt,
  DateTime? createdAt,
  bool? isRead,
})
```

#### Example

```dart
final notification = NotificationData(
  id: '550e8400-e29b-41d4-a716-446655440000',
  memberId: '123e4567-e89b-12d3-a456-426614174000',
  sessionId: '123e4567-e89b-12d3-a456-426614174001',
  title: 'New Session Available',
  body: 'Coach John created Pilates Advanced for Monday 6pm',
  eventType: NotificationEvent.COACH_SESSION_CREATED,
  data: {
    'coach_name': 'John',
    'session_title': 'Pilates Advanced',
    'date': '2025-05-22',
  },
  createdAt: DateTime.now(),
  isRead: false,
);

// To JSON
final json = notification.toMap();

// From JSON
final fromJson = NotificationData.fromMap(json);
```

---

### NotificationEvent (Enum)

Notification event types.

```dart
enum NotificationEvent {
  COACH_SESSION_CREATED,    // Coach created new session
  SESSION_SPOT_AVAILABLE,   // Spot opened in session
  WAITLIST_AVAILABLE,       // Member moved up on waitlist
  SESSION_CANCELLED,        // Session cancelled
  BOOKING_CONFIRMED,        // Booking confirmed
  CUSTOM,                   // Custom event
}
```

#### Usage

```dart
// Check event type
if (notification.eventType == NotificationEvent.SESSION_SPOT_AVAILABLE) {
  // Show booking prompt
}

// Parse from string
final event = NotificationData._parseEventType('COACH_SESSION_CREATED');
```

---

### NotificationChannel (Enum)

Notification delivery channels.

```dart
enum NotificationChannel {
  EMAIL,    // Email via Mailtrap
  IN_APP,   // In-app notification in database
  PUSH,     // Push notification via Firebase
}
```

---

### NotificationPreferences

User notification preferences.

```dart
class NotificationPreferences {
  final String memberId;                              // User ID
  final List<NotificationChannel> enabledChannels;    // Enabled channels
  final List<NotificationEvent> enabledEventTypes;    // Enabled events
  final DateTime updatedAt;                           // Last updated
}
```

#### Factory Methods

```dart
// Create from map
NotificationPreferences.fromMap(Map<String, dynamic> map)

// Convert to map
Map<String, dynamic> toMap()

// Create modified copy
NotificationPreferences copyWith({
  String? memberId,
  List<NotificationChannel>? enabledChannels,
  List<NotificationEvent>? enabledEventTypes,
  DateTime? updatedAt,
})
```

#### Example

```dart
final prefs = NotificationPreferences(
  memberId: userId,
  enabledChannels: [
    NotificationChannel.EMAIL,
    NotificationChannel.IN_APP,
    NotificationChannel.PUSH,
  ],
  enabledEventTypes: [
    NotificationEvent.COACH_SESSION_CREATED,
    NotificationEvent.SESSION_SPOT_AVAILABLE,
    NotificationEvent.BOOKING_CONFIRMED,
  ],
  updatedAt: DateTime.now(),
);
```

---

## NotificationController

State management for notifications.

### Properties

```dart
// Getters
List<NotificationData> get notifications          // All notifications
int get unreadCount                               // Count of unread
bool get isLoading                                // Loading state
String? get error                                 // Error message (if any)
```

### Methods

#### initialize(String userId)

Initialize the controller for a user. **Must be called once when user logs in.**

```dart
Future<void> initialize(String userId)
```

**Parameters:**
- `userId` (String) - The authenticated user's ID (UUID)

**Returns:**
- `Future<void>` - Completes when initialization is done

**Throws:**
- `Exception` - If initialization fails

**Example:**
```dart
@override
void initState() {
  super.initState();
  final userId = context.read<AuthController>().user?.id;
  if (userId != null) {
    context.read<NotificationController>().initialize(userId);
  }
}
```

---

#### fetchNotifications({int limit = 20, int offset = 0})

Fetch all notifications for current user.

```dart
Future<void> fetchNotifications({
  int limit = 20,
  int offset = 0,
})
```

**Parameters:**
- `limit` (int, default: 20) - Number of notifications to fetch
- `offset` (int, default: 0) - Pagination offset

**Returns:**
- `Future<void>` - Updates `notifications` list

**Example:**
```dart
// Load initial notifications
await controller.fetchNotifications();

// Load more with pagination
await controller.fetchNotifications(limit: 20, offset: 20);
```

---

#### fetchUnreadNotifications({int limit = 20, int offset = 0})

Fetch only unread notifications.

```dart
Future<void> fetchUnreadNotifications({
  int limit = 20,
  int offset = 0,
})
```

**Parameters:**
- `limit` (int, default: 20) - Number of notifications to fetch
- `offset` (int, default: 0) - Pagination offset

**Returns:**
- `Future<void>` - Updates `notifications` list

**Example:**
```dart
// Show only unread
await controller.fetchUnreadNotifications();
```

---

#### markAsRead(String notificationId)

Mark a single notification as read.

```dart
Future<void> markAsRead(String notificationId)
```

**Parameters:**
- `notificationId` (String) - ID of notification to mark as read

**Returns:**
- `Future<void>` - Completes when updated

**Example:**
```dart
final controller = context.read<NotificationController>();
await controller.markAsRead(notification.id);
```

---

#### markMultipleAsRead(List<String> notificationIds)

Mark multiple notifications as read in one call.

```dart
Future<void> markMultipleAsRead(List<String> notificationIds)
```

**Parameters:**
- `notificationIds` (List<String>) - IDs to mark as read

**Returns:**
- `Future<void>` - Completes when all updated

**Example:**
```dart
// Mark 5 notifications as read
await controller.markMultipleAsRead([
  'notif-1',
  'notif-2',
  'notif-3',
  'notif-4',
  'notif-5',
]);
```

---

#### deleteNotification(String notificationId)

Delete a single notification.

```dart
Future<void> deleteNotification(String notificationId)
```

**Parameters:**
- `notificationId` (String) - ID of notification to delete

**Returns:**
- `Future<void>` - Completes when deleted

**Example:**
```dart
await controller.deleteNotification(notification.id);
```

---

#### deleteReadNotifications()

Delete all read notifications for current user.

```dart
Future<void> deleteReadNotifications()
```

**Returns:**
- `Future<void>` - Completes when all read notifications deleted

**Example:**
```dart
// Clean up read notifications
await controller.deleteReadNotifications();
```

---

#### getUnreadCount()

Get count of unread notifications.

```dart
int getUnreadCount()
```

**Returns:**
- `int` - Number of unread notifications

**Example:**
```dart
final count = controller.getUnreadCount();
print('You have $count unread notifications');
```

---

## FollowController

State management for coach following.

### Properties

```dart
// Getters
Set<String> get followedCoachIds              // IDs of followed coaches
Map<String, int> get coachFollowerCounts      // Follower counts by coach
bool get isLoading                             // Loading state
String? get error                              // Error message (if any)
```

### Methods

#### initialize(String userId)

Initialize the controller for a user. **Must be called once when user logs in.**

```dart
Future<void> initialize(String userId)
```

**Parameters:**
- `userId` (String) - The authenticated user's ID (UUID)

**Returns:**
- `Future<void>` - Completes when initialization is done

**Example:**
```dart
final userId = context.read<AuthController>().user?.id;
if (userId != null) {
  context.read<FollowController>().initialize(userId);
}
```

---

#### fetchMyFollowedCoaches()

Get all coaches followed by current user.

```dart
Future<void> fetchMyFollowedCoaches()
```

**Returns:**
- `Future<void>` - Updates `followedCoachIds` set

**Example:**
```dart
await controller.fetchMyFollowedCoaches();
final followedIds = controller.followedCoachIds;
```

---

#### followCoach(String coachId)

Follow a coach.

```dart
Future<void> followCoach(String coachId)
```

**Parameters:**
- `coachId` (String) - ID of coach to follow (UUID)

**Returns:**
- `Future<void>` - Completes when follow created

**Example:**
```dart
await controller.followCoach(coachId);
// User will now receive notifications from this coach
```

---

#### unfollowCoach(String coachId)

Unfollow a coach.

```dart
Future<void> unfollowCoach(String coachId)
```

**Parameters:**
- `coachId` (String) - ID of coach to unfollow (UUID)

**Returns:**
- `Future<void>` - Completes when follow deleted

**Example:**
```dart
await controller.unfollowCoach(coachId);
// User will no longer receive notifications from this coach
```

---

#### isCoachFollowed(String coachId)

Check if user follows a coach.

```dart
bool isCoachFollowed(String coachId)
```

**Parameters:**
- `coachId` (String) - ID of coach to check

**Returns:**
- `bool` - true if followed, false otherwise

**Example:**
```dart
if (controller.isCoachFollowed(coachId)) {
  print('You follow this coach');
} else {
  print('You do not follow this coach');
}
```

---

#### getFollowerCount(String coachId)

Get follower count for a coach.

```dart
int getFollowerCount(String coachId)
```

**Parameters:**
- `coachId` (String) - ID of coach

**Returns:**
- `int` - Number of followers

**Example:**
```dart
final count = controller.getFollowerCount(coachId);
print('This coach has $count followers');
```

---

#### getCoachFollowers(String coachId)

Get list of followers for a coach.

```dart
Future<List<Map<String, dynamic>>> getCoachFollowers(
  String coachId, {
  int limit = 50,
  int offset = 0,
})
```

**Parameters:**
- `coachId` (String) - ID of coach
- `limit` (int, default: 50) - Number of followers to fetch
- `offset` (int, default: 0) - Pagination offset

**Returns:**
- `Future<List<Map<String, dynamic>>>` - List of follower profiles

**Example:**
```dart
final followers = await controller.getCoachFollowers(
  coachId,
  limit: 20,
);
for (final follower in followers) {
  print(follower['name']);
}
```

---

## MultiChannelNotificationService

Main orchestrator for sending notifications across all channels.

### Methods

#### initialize()

Initialize the service.

```dart
Future<void> initialize()
```

**Returns:**
- `Future<void>` - Completes when initialized

**Example:**
```dart
final service = MultiChannelNotificationService();
await service.initialize();
```

---

#### notifySessionCreated()

Send notification when coach creates session.

```dart
Future<void> notifySessionCreated({
  required String memberId,
  required String coachName,
  required String sessionTitle,
  required DateTime sessionTime,
  required String sessionId,
})
```

**Parameters:**
- `memberId` (String) - Recipient user ID (UUID)
- `coachName` (String) - Name of coach
- `sessionTitle` (String) - Session title
- `sessionTime` (DateTime) - When session starts
- `sessionId` (String) - Session ID for navigation

**Returns:**
- `Future<void>` - Completes when sent to all enabled channels

**Example:**
```dart
await notificationService.notifySessionCreated(
  memberId: followerId,
  coachName: 'Coach John',
  sessionTitle: 'Pilates Advanced',
  sessionTime: DateTime(2025, 5, 22, 18, 0),
  sessionId: sessionId,
);
```

---

#### notifySpotAvailable()

Send notification when spot becomes available.

```dart
Future<void> notifySpotAvailable({
  required String memberId,
  required String sessionTitle,
  required DateTime sessionTime,
  int spotsAvailable = 1,
  String? sessionId,
})
```

**Parameters:**
- `memberId` (String) - Recipient user ID
- `sessionTitle` (String) - Session title
- `sessionTime` (DateTime) - When session starts
- `spotsAvailable` (int, default: 1) - Number of spots available
- `sessionId` (String?, optional) - Session ID for navigation

**Returns:**
- `Future<void>` - Completes when sent

**Example:**
```dart
await notificationService.notifySpotAvailable(
  memberId: memberId,
  sessionTitle: 'Pilates Beginner',
  sessionTime: DateTime(2025, 5, 20, 18, 0),
  spotsAvailable: 1,
  sessionId: sessionId,
);
```

---

#### notifyWaitlistAvailable()

Send notification when member moves up on waitlist.

```dart
Future<void> notifyWaitlistAvailable({
  required String memberId,
  required String sessionTitle,
  required DateTime sessionTime,
  int position = 1,
  String? sessionId,
})
```

**Parameters:**
- `memberId` (String) - Recipient user ID
- `sessionTitle` (String) - Session title
- `sessionTime` (DateTime) - When session starts
- `position` (int, default: 1) - Current position on waitlist
- `sessionId` (String?, optional) - Session ID

**Returns:**
- `Future<void>` - Completes when sent

**Example:**
```dart
await notificationService.notifyWaitlistAvailable(
  memberId: memberId,
  sessionTitle: 'Pilates Beginner',
  sessionTime: DateTime(2025, 5, 20, 18, 0),
  position: 1,
  sessionId: sessionId,
);
```

---

#### notifySessionCancelled()

Send notification when session is cancelled.

```dart
Future<void> notifySessionCancelled({
  required String memberId,
  required String sessionTitle,
  required DateTime sessionTime,
  String reason = 'Coach unavailable',
})
```

**Parameters:**
- `memberId` (String) - Recipient user ID
- `sessionTitle` (String) - Session title
- `sessionTime` (DateTime) - When session was scheduled
- `reason` (String) - Why session was cancelled

**Returns:**
- `Future<void>` - Completes when sent

**Example:**
```dart
await notificationService.notifySessionCancelled(
  memberId: memberId,
  sessionTitle: 'Pilates Advanced',
  sessionTime: DateTime(2025, 5, 22, 18, 0),
  reason: 'Coach sick leave',
);
```

---

#### notifyBookingConfirmed()

Send confirmation when booking is confirmed.

```dart
Future<void> notifyBookingConfirmed({
  required String memberId,
  required String sessionTitle,
  required DateTime sessionTime,
  String? location,
  String? coachName,
})
```

**Parameters:**
- `memberId` (String) - Recipient user ID
- `sessionTitle` (String) - Session title
- `sessionTime` (DateTime) - When session starts
- `location` (String?, optional) - Session location
- `coachName` (String?, optional) - Coach name

**Returns:**
- `Future<void>` - Completes when sent

**Example:**
```dart
await notificationService.notifyBookingConfirmed(
  memberId: memberId,
  sessionTitle: 'Pilates Beginner',
  sessionTime: DateTime(2025, 5, 20, 18, 0),
  location: 'Studio A',
  coachName: 'Sarah',
);
```

---

#### sendNotification()

Send a custom notification.

```dart
Future<bool> sendNotification({
  required String memberId,
  required String title,
  required String body,
  NotificationEvent eventType = NotificationEvent.CUSTOM,
  Map<String, dynamic> data = const {},
  String? sessionId,
})
```

**Parameters:**
- `memberId` (String) - Recipient user ID
- `title` (String) - Notification title
- `body` (String) - Notification body
- `eventType` (NotificationEvent) - Type of event
- `data` (Map) - Custom data payload
- `sessionId` (String?, optional) - Related session

**Returns:**
- `Future<bool>` - true if sent successfully

**Example:**
```dart
final success = await notificationService.sendNotification(
  memberId: userId,
  title: 'Special Offer',
  body: 'Get 20% off your next 10 sessions',
  eventType: NotificationEvent.CUSTOM,
  data: {
    'coupon_code': 'SAVE20',
    'expiry': '2025-12-31',
  },
);
```

---

#### markAsRead()

Mark notification as read.

```dart
Future<bool> markAsRead(String notificationId)
```

**Parameters:**
- `notificationId` (String) - Notification ID to mark as read

**Returns:**
- `Future<bool>` - true if successful

**Example:**
```dart
await service.markAsRead(notificationId);
```

---

#### getNotifications()

Get all notifications for user.

```dart
Future<List<NotificationData>> getNotifications({
  int limit = 20,
  int offset = 0,
})
```

**Parameters:**
- `limit` (int, default: 20) - Number to fetch
- `offset` (int, default: 0) - Pagination offset

**Returns:**
- `Future<List<NotificationData>>` - List of notifications

**Example:**
```dart
final notifications = await service.getNotifications(limit: 50);
```

---

#### getUnreadNotifications()

Get only unread notifications for user.

```dart
Future<List<NotificationData>> getUnreadNotifications({
  int limit = 20,
  int offset = 0,
})
```

**Parameters:**
- `limit` (int, default: 20) - Number to fetch
- `offset` (int, default: 0) - Pagination offset

**Returns:**
- `Future<List<NotificationData>>` - List of unread notifications

**Example:**
```dart
final unread = await service.getUnreadNotifications();
```

---

#### getUnreadCount()

Get count of unread notifications.

```dart
Future<int> getUnreadCount(String memberId)
```

**Parameters:**
- `memberId` (String) - User ID

**Returns:**
- `Future<int>` - Count of unread

**Example:**
```dart
final count = await service.getUnreadCount(userId);
```

---

#### deleteNotification()

Delete a notification.

```dart
Future<bool> deleteNotification(String notificationId)
```

**Parameters:**
- `notificationId` (String) - Notification ID to delete

**Returns:**
- `Future<bool>` - true if deleted

**Example:**
```dart
await service.deleteNotification(notificationId);
```

---

## InAppNotificationService

Manages in-app notifications stored in Supabase.

### Methods

#### createInAppNotification()

Create a new in-app notification.

```dart
Future<bool> createInAppNotification({
  required String memberId,
  required String title,
  required String body,
  String? sessionId,
  String eventType = 'CUSTOM',
  Map<String, dynamic> data = const {},
})
```

**Parameters:**
- `memberId` (String) - Recipient user ID
- `title` (String) - Notification title
- `body` (String) - Notification body
- `sessionId` (String?, optional) - Related session
- `eventType` (String) - Type of event
- `data` (Map) - Custom data

**Returns:**
- `Future<bool>` - true if created

**Example:**
```dart
await inAppService.createInAppNotification(
  memberId: userId,
  title: 'New Session',
  body: 'Coach created Pilates Advanced',
  eventType: 'COACH_SESSION_CREATED',
);
```

---

#### getNotifications()

Get paginated notifications.

```dart
Future<List<NotificationData>> getNotifications(
  String memberId, {
  int limit = 20,
  int offset = 0,
})
```

**Parameters:**
- `memberId` (String) - User ID
- `limit` (int, default: 20) - Number to fetch
- `offset` (int, default: 0) - Pagination offset

**Returns:**
- `Future<List<NotificationData>>` - List of notifications

---

#### getUnreadCount()

Get count of unread notifications.

```dart
Future<int> getUnreadCount(String memberId)
```

**Parameters:**
- `memberId` (String) - User ID

**Returns:**
- `Future<int>` - Count of unread

---

#### markAsRead()

Mark single notification as read.

```dart
Future<bool> markAsRead(String notificationId)
```

**Parameters:**
- `notificationId` (String) - Notification ID

**Returns:**
- `Future<bool>` - true if successful

---

#### markMultipleAsRead()

Mark multiple notifications as read.

```dart
Future<bool> markMultipleAsRead(List<String> notificationIds)
```

**Parameters:**
- `notificationIds` (List<String>) - Notification IDs

**Returns:**
- `Future<bool>` - true if successful

---

#### deleteNotification()

Delete a notification.

```dart
Future<bool> deleteNotification(String notificationId)
```

**Parameters:**
- `notificationId` (String) - Notification ID

**Returns:**
- `Future<bool>` - true if deleted

---

#### deleteAllNotificationsForUser()

Delete all notifications for a user.

```dart
Future<bool> deleteAllNotificationsForUser(String memberId)
```

**Parameters:**
- `memberId` (String) - User ID

**Returns:**
- `Future<bool>` - true if all deleted

---

## MailtrapService

Sends email notifications via Mailtrap API.

### Methods

#### initialize()

Initialize the service with configuration validation.

```dart
Future<void> initialize()
```

**Throws:**
- `Exception` - If MAILTRAP_API_TOKEN not set in .env

**Example:**
```dart
final mailtrap = MailtrapService();
await mailtrap.initialize();
```

---

#### sendEmail()

Send an email using Mailtrap API.

```dart
Future<bool> sendEmail({
  required String to,
  String? toName,
  required String subject,
  required String templateId,
  Map<String, String> variables = const {},
  bool isHtml = true,
  String? replyTo,
})
```

**Parameters:**
- `to` (String) - Recipient email address
- `toName` (String?, optional) - Recipient name
- `subject` (String) - Email subject
- `templateId` (String) - Template ID from Mailtrap
- `variables` (Map) - Template variables for substitution
- `isHtml` (bool, default: true) - Whether body is HTML
- `replyTo` (String?, optional) - Reply-to address

**Returns:**
- `Future<bool>` - true if sent successfully, false if failed

**Example:**
```dart
final success = await mailtrap.sendEmail(
  to: 'user@example.com',
  toName: 'John Doe',
  subject: 'New Session Available',
  templateId: 'session_created',
  variables: {
    'member_name': 'John',
    'coach_name': 'Sarah',
    'session_title': 'Pilates Advanced',
    'session_date': '2025-05-22',
    'session_time': '18:00',
  },
);

if (success) {
  print('Email sent successfully');
} else {
  print('Failed to send email');
}
```

---

#### Reference
For more details on Mailtrap API:
[Mailtrap Official Documentation](https://mailtrap.io/api-documentation/)

---

## PushNotificationService

Manages push notifications via Firebase Cloud Messaging.

### Methods

#### initialize()

Initialize push notification service.

```dart
Future<void> initialize()
```

**Returns:**
- `Future<void>` - Completes when initialized

---

#### sendPushNotification()

Send push notification to a device.

```dart
Future<bool> sendPushNotification({
  required String deviceToken,
  required String title,
  required String body,
  Map<String, String> data = const {},
})
```

**Parameters:**
- `deviceToken` (String) - Device's FCM token
- `title` (String) - Notification title
- `body` (String) - Notification body
- `data` (Map) - Custom data payload

**Returns:**
- `Future<bool>` - true if sent successfully

---

#### sendPushNotificationsToMultiple()

Send push notification to multiple devices.

```dart
Future<bool> sendPushNotificationsToMultiple({
  required List<String> deviceTokens,
  required String title,
  required String body,
  Map<String, String> data = const {},
})
```

**Parameters:**
- `deviceTokens` (List<String>) - List of FCM tokens
- `title` (String) - Notification title
- `body` (String) - Notification body
- `data` (Map) - Custom data payload

**Returns:**
- `Future<bool>` - true if all sent successfully

---

#### subscribeToTopic()

Subscribe device to a topic for broadcast notifications.

```dart
Future<bool> subscribeToTopic({
  required String deviceToken,
  required String topic,
})
```

**Parameters:**
- `deviceToken` (String) - Device FCM token
- `topic` (String) - Topic name (e.g., 'coach_sessions')

**Returns:**
- `Future<bool>` - true if subscribed

**Example:**
```dart
// Subscribe member to coach's session topic
await pushService.subscribeToTopic(
  deviceToken: token,
  topic: 'coach_${coachId}_sessions',
);
```

---

#### unsubscribeFromTopic()

Unsubscribe device from a topic.

```dart
Future<bool> unsubscribeFromTopic({
  required String deviceToken,
  required String topic,
})
```

**Parameters:**
- `deviceToken` (String) - Device FCM token
- `topic` (String) - Topic name

**Returns:**
- `Future<bool>` - true if unsubscribed

---

## Error Codes

### HTTP Status Codes (Mailtrap)

| Code | Meaning | Action |
|------|---------|--------|
| 200 | OK | Email sent successfully |
| 400 | Bad Request | Check email format and template variables |
| 401 | Unauthorized | Verify MAILTRAP_API_TOKEN |
| 403 | Forbidden | Check account permissions |
| 422 | Unprocessable Entity | Email/template validation failed |
| 429 | Too Many Requests | Rate limited - retry after delay |
| 500 | Server Error | Mailtrap service error - retry later |

### Firebase Status Codes

| Code | Meaning | Action |
|------|---------|--------|
| 200 | OK | Push sent successfully |
| 401 | Unauthorized | Check Firebase credentials |
| 400 | Bad Request | Check device token validity |
| 401 | Not Found | Device token invalid or expired |

### Supabase Error Codes

| Code | Meaning | Action |
|------|---------|--------|
| 401 | Unauthorized | User not authenticated |
| 403 | Forbidden | RLS policy violation |
| 400 | Bad Request | Invalid data format |
| 409 | Conflict | Unique constraint violation |
| 500 | Server Error | Database error - contact support |

### Custom Error Codes

```dart
// Notification not found
'NOTIFICATION_NOT_FOUND'

// User not found
'USER_NOT_FOUND'

// Preferences not found
'PREFERENCES_NOT_FOUND'

// Permission denied
'PERMISSION_DENIED'

// Invalid input
'INVALID_INPUT'

// Network error
'NETWORK_ERROR'

// Service unavailable
'SERVICE_UNAVAILABLE'
```

---

## Common Patterns

### Pattern 1: Send to All Followers

```dart
final service = MultiChannelNotificationService();

// Get all followers
final followers = await followService.getCoachFollowers(coachId);

// Send to each
for (final follower in followers) {
  await service.notifySessionCreated(
    memberId: follower['id'],
    coachName: coachName,
    sessionTitle: sessionTitle,
    sessionTime: sessionTime,
    sessionId: sessionId,
  );
}
```

### Pattern 2: Check User Preferences Before Sending

```dart
final service = MultiChannelNotificationService();

// Get preferences
final prefs = await service.getUserPreferences(userId);

// Check if user wants this type of notification
if (prefs.enabledEventTypes.contains(NotificationEvent.COACH_SESSION_CREATED)) {
  await service.notifySessionCreated(...);
}
```

### Pattern 3: Batch Mark as Read

```dart
final controller = context.read<NotificationController>();

// Get unread IDs
final unreadIds = controller.notifications
    .where((n) => !n.isRead)
    .map((n) => n.id)
    .toList();

// Mark all at once
if (unreadIds.isNotEmpty) {
  await controller.markMultipleAsRead(unreadIds);
}
```

### Pattern 4: Listen to Real-Time Updates

```dart
// Supabase realtime listener (already set up in controller)
final subscription = supabaseClient
    .from('notifications')
    .on(RealtimeListenTypes.allEvents, (payload) {
      if (payload.eventType == 'INSERT') {
        // New notification received
        controller.fetchNotifications();
      }
    })
    .subscribe();
```

---

## Migration Guide

### From No Notifications → With Notifications

**Step 1**: Add controllers to main.dart providers
**Step 2**: Call initialize() in home screen
**Step 3**: Add UI components
**Step 4**: Add notification triggers in services

---

## Versioning

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2024 | Initial release |

---

**Last Updated**: 2024  
**Status**: Complete and documented  
**Support**: See troubleshooting in NOTIFICATION_SYSTEM_INTEGRATION_GUIDE.md
