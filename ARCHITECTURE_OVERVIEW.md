# Architecture Overview

**System Architecture, Data Flow, and Component Relationships**

---

## Table of Contents

1. [System Architecture Diagram](#system-architecture-diagram)
2. [Component Relationships](#component-relationships)
3. [Data Flow](#data-flow)
4. [Database Schema](#database-schema)
5. [Service Layer](#service-layer)
6. [Notification Lifecycle](#notification-lifecycle)
7. [User Journey](#user-journey)
8. [Error Handling](#error-handling)

---

## System Architecture Diagram

### High-Level Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        Flex Pilates App                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                    UI Layer                              │   │
│  ├──────────────────────────────────────────────────────────┤   │
│  │                                                            │   │
│  │  ┌───────────────┐  ┌──────────────┐  ┌──────────────┐  │   │
│  │  │ Home Screen   │  │ Notification │  │   Settings   │  │   │
│  │  │               │  │    Center    │  │    Screen    │  │   │
│  │  │  - Badge      │  │              │  │              │  │   │
│  │  │  - Banner     │  │  - List      │  │  - Prefs     │  │   │
│  │  └───────────────┘  │  - Mark Read │  │  - Links     │  │   │
│  │                      │  - Delete    │  └──────────────┘  │   │
│  │  ┌───────────────┐   └──────────────┘                     │   │
│  │  │ Coach Cards   │   ┌────────────────────────────────┐  │   │
│  │  │               │   │  Coach Detail Screen           │  │   │
│  │  │ - Follow Btn  │   │                                │  │   │
│  │  │ - Badge       │   │ - Followers Badge             │  │   │
│  │  │ - Count       │   │ - Follow Button               │  │   │
│  │  └───────────────┘   │ - Followers Modal             │  │   │
│  │                       └────────────────────────────────┘  │   │
│  │                                                            │   │
│  └──────────────────────────────────────────────────────────┘   │
│                           │                                      │
│                           │ Uses                                 │
│                           ▼                                      │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │        State Management Layer (Provider)                 │   │
│  ├──────────────────────────────────────────────────────────┤   │
│  │                                                            │   │
│  │  ┌─────────────────────┐    ┌─────────────────────────┐ │   │
│  │  │ NotificationCtrl    │    │  FollowController       │ │   │
│  │  │                     │    │                         │ │   │
│  │  │ - notifications[]   │    │ - followedCoachIds{}    │ │   │
│  │  │ - unreadCount       │    │ - coachFollowerCounts{} │ │   │
│  │  │ - isLoading         │    │ - isLoading             │ │   │
│  │  │ - error             │    │ - error                 │ │   │
│  │  │                     │    │                         │ │   │
│  │  │ Methods:            │    │ Methods:                │ │   │
│  │  │ + initialize()      │    │ + initialize()          │ │   │
│  │  │ + fetchNotifs()     │    │ + fetchFollowedCoaches()│   │
│  │  │ + markAsRead()      │    │ + followCoach()         │ │   │
│  │  │ + deleteNotif()     │    │ + unfollowCoach()       │ │   │
│  │  │ + getUnreadCount()  │    │ + getFollowers()        │ │   │
│  │  └─────────────────────┘    └─────────────────────────┘ │   │
│  │                                                            │   │
│  └──────────────────────────────────────────────────────────┘   │
│                           │                                      │
│                           │ Uses                                 │
│                           ▼                                      │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │           Service Layer                                  │   │
│  ├──────────────────────────────────────────────────────────┤   │
│  │                                                            │   │
│  │  ┌────────────────────────────────────────────────────┐  │   │
│  │  │ MultiChannelNotificationService (Orchestrator)     │  │   │
│  │  │                                                     │  │   │
│  │  │ - Routes notifications to channels                │  │   │
│  │  │ - Checks user preferences                          │  │   │
│  │  │ - Coordinates sending                              │  │   │
│  │  │                                                     │  │   │
│  │  │ Methods:                                            │  │   │
│  │  │ + initialize()          + sendNotification()       │  │   │
│  │  │ + notifySessionCreated() + markAsRead()            │  │   │
│  │  │ + notifySpotAvailable() + getNotifications()       │  │   │
│  │  │ + notifyWaitlistAvailable() + deleteNotification()│  │   │
│  │  │ + notifySessionCancelled() + getUnreadCount()      │  │   │
│  │  │ + notifyBookingConfirmed()                          │  │   │
│  │  │                                                     │  │   │
│  │  └────────────────────────────────────────────────────┘  │   │
│  │                           │                               │   │
│  │                 ┌─────────┼──────────┬─────────────┐     │   │
│  │                 │         │          │             │     │   │
│  │                 ▼         ▼          ▼             ▼     │   │
│  │  ┌────────────────────┐ ┌──────────────────────────────┐ │   │
│  │  │ InAppNotif         │ │ MailtrapService (Email)      │ │   │
│  │  │ Service            │ │                              │ │   │
│  │  │                    │ │ - sendEmail()                │ │   │
│  │  │ - Store in DB      │ │ - uses template ID           │ │   │
│  │  │ - Track delivery   │ │ - Mailtrap API               │ │   │
│  │  │ - Mark as read     │ │ - Returns success/failure    │ │   │
│  │  └────────────────────┘ └──────────────────────────────┘ │   │
│  │                                                            │   │
│  │  ┌────────────────────┐  ┌──────────────────────────────┐ │   │
│  │  │ PushNotification   │  │ NotificationService (Firebase)│ │   │
│  │  │ Service            │  │                              │ │   │
│  │  │                    │  │ - Configure FCM              │ │   │
│  │  │ - Send via FCM     │  │ - Handle tokens              │ │   │
│  │  │ - Topic subscr.    │  │ - Listen for messages        │ │   │
│  │  │ - Device tokens    │  │ - Show local notifications   │ │   │
│  │  └────────────────────┘  └──────────────────────────────┘ │   │
│  │                                                            │   │
│  └──────────────────────────────────────────────────────────┘   │
│                           │                                      │
│                           │ Uses                                 │
│                           ▼                                      │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │            Data Access Layer                             │   │
│  ├──────────────────────────────────────────────────────────┤   │
│  │                                                            │   │
│  │  ┌──────────────┐         ┌──────────────────────────┐   │   │
│  │  │ Supabase     │         │  External Services       │   │   │
│  │  │ Client       │         │                          │   │   │
│  │  │              │         │ - Mailtrap API           │   │   │
│  │  │ Tables:      │         │ - Firebase FCM           │   │   │
│  │  │              │         │ - Realtime updates       │   │   │
│  │  │ - notifics   │         │                          │   │   │
│  │  │ - prefs      │         └──────────────────────────┘   │   │
│  │  │ - follows    │                                         │   │
│  │  │ - profiles   │                                         │   │
│  │  │ - sessions   │                                         │   │
│  │  └──────────────┘                                         │   │
│  │                                                            │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Component Relationships

### Dependency Graph

```
┌─────────────────────────────────────────────┐
│         UI Layer Components                 │
├─────────────────────────────────────────────┤
│                                              │
│  Widgets:                                    │
│  - NotificationBanner (stateless)            │
│  - FollowButton (consumer)                   │
│  - FollowersBadge (consumer)                 │
│  - FollowersListModal (consumer)             │
│                                              │
│  Screens:                                    │
│  - NotificationCenterScreen                  │
│  - NotificationPreferencesScreen             │
│  - MyCoachesScreen                           │
│                                              │
│         ▲                                    │
│         │                                    │
│         │ Depends on                         │
│         │                                    │
├─────────┼──────────────────────────────────┤
│         │    Controllers                    │
│         │                                   │
│    ┌────┴────────────────────────────────┐  │
│    │ NotificationController              │  │
│    │ FollowController                    │  │
│    │                                     │  │
│    │   ▲                                 │  │
│    │   │ Uses                            │  │
│    │   │                                 │  │
│    └────┼────────────────────────────────┘  │
│         │                                   │
├─────────┼──────────────────────────────────┤
│         │    Services                      │
│         │                                  │
│    ┌────┴────────────────────────────────┐ │
│    │ MultiChannelNotificationService     │ │
│    │ FollowService (in FollowController) │ │
│    │                                     │ │
│    │   ▲                                 │ │
│    │   │ Delegates to                    │ │
│    │   │                                 │ │
│    └─┬─┼────────────────────────────────┐ │
│      │ │                                │ │
│   ┌──┴─┴─────────────┬──────────────┬──┘ │
│   │                  │              │    │
│   ▼                  ▼              ▼    │
│ InAppNotif      MailtrapService    Push  │
│ Service         (Email)             Notif│
│                                     Svc  │
│   │                  │              │    │
├───┼──────────────────┼──────────────┼───┤
│   │                  │              │    │
│   ▼                  ▼              ▼    │
│ Supabase        External API      FCM   │
│ Database        (Mailtrap)        Server │
└───────────────────────────────────────────┘
```

### File Structure

```
lib/
├── models/
│   └── notification_model.dart
│       ├── NotificationData
│       ├── NotificationPreferences
│       ├── NotificationEvent (enum)
│       └── NotificationChannel (enum)
│
├── services/
│   ├── notification_service.dart (Firebase setup)
│   ├── multi_channel_notification_service.dart (Orchestrator)
│   ├── in_app_notification_service.dart (Database)
│   ├── mailtrap_service.dart (Email)
│   ├── push_notification_service.dart (FCM)
│   └── supabase_service.dart (Database client)
│
├── controllers/
│   ├── notification_controller.dart
│   └── follow_controller.dart
│
├── views/
│   ├── widgets/
│   │   ├── notification_banner.dart
│   │   ├── follow_button.dart
│   │   ├── followers_badge.dart
│   │   └── followers_list.dart
│   │
│   └── screens/
│       ├── member/
│       │   ├── notification_center_screen.dart
│       │   └── my_coaches_screen.dart
│       │
│       └── common/
│           └── notification_preferences_screen.dart
│
└── main.dart (providers setup)
```

---

## Data Flow

### Notification Creation Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                    1. TRIGGER EVENT                                 │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  Trigger: Coach creates new session                                  │
│                                                                       │
│  Code:                                                               │
│  ```dart                                                            │
│  // In SessionController or SessionService                          │
│  final session = await createSessionInDB(sessionData);              │
│  await notificationService.notifySessionCreated(                    │
│    memberId: followerId,                                            │
│    coachName: 'John',                                               │
│    sessionTitle: 'Pilates Advanced',                                │
│    sessionTime: DateTime.now(),                                     │
│    sessionId: session.id,                                           │
│  );                                                                  │
│  ```                                                                │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│        2. ORCHESTRATOR (MultiChannelNotificationService)            │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  notifySessionCreated() called with:                                 │
│  - memberId (recipient)                                             │
│  - coachName, sessionTitle, sessionTime, sessionId (context)        │
│                                                                       │
│  Process:                                                            │
│  1. Get user preferences from DB                                    │
│  2. Check if EMAIL channel enabled                                  │
│  3. Check if COACH_SESSION_CREATED event enabled                    │
│  4. Build notification data                                         │
│  5. Create NotificationData object                                  │
│  6. Route to each enabled channel                                   │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              │ Routes to channels
                              │
                 ┌────────────┼────────────┐
                 │            │            │
                 ▼            ▼            ▼
        (if EMAIL)    (if IN_APP)    (if PUSH)
                 │            │            │
┌───────────────────┐  ┌──────────────┐  ┌──────────────┐
│ 3a. EMAIL         │  │ 3b. IN-APP   │  │ 3c. PUSH     │
├───────────────────┤  ├──────────────┤  ├──────────────┤
│                   │  │              │  │              │
│ MailtrapService   │  │ InAppNotif   │  │ PushNotif    │
│ .sendEmail()      │  │ Service      │  │ Service      │
│                   │  │ .create()    │  │ .send()      │
│ - Build HTML      │  │              │  │              │
│ - Send API req    │  │ - Insert DB  │  │ - Get token  │
│ - Track delivery  │  │ - Track time │  │ - Send FCM   │
│                   │  │              │  │ - Handle err │
│                   │  │              │  │              │
│ Returns:          │  │ Returns:     │  │ Returns:     │
│ success: bool     │  │ notif: id    │  │ success: bool│
│                   │  │              │  │              │
└───────────────────┘  └──────────────┘  └──────────────┘
         │                    │                   │
         │ Mailtrap API       │ Supabase         │ Firebase FCM
         │ Response           │ Insert OK        │ Response
         │                    │                  │
         └────────────────────┼──────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │ NOTIFICATIONS    │
                    │ DELIVERED        │
                    └──────────────────┘
                              │
                              │ Real-time sync
                              ▼
                    ┌──────────────────┐
                    │ Supabase         │
                    │ Realtime         │
                    │ (watches)        │
                    └──────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │ NotificationCtrl │
                    │ (listens)        │
                    └──────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │ UI Updates       │
                    │ (rebuilds)       │
                    └──────────────────┘
```

### Notification Display Flow

```
┌─────────────────────────────────────────┐
│  User opens NotificationCenterScreen    │
├─────────────────────────────────────────┤
│                                          │
│  initState():                            │
│  1. Get NotificationController           │
│  2. Call controller.fetchNotifications()│
│                                          │
└─────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│  NotificationController                 │
├─────────────────────────────────────────┤
│                                          │
│  fetchNotifications() {                  │
│    - Call MultiChannelService           │
│    - Service calls                       │
│      InAppNotificationService           │
│    - Query Supabase                      │
│      SELECT * FROM notifications        │
│      WHERE member_id = userId            │
│      ORDER BY created_at DESC            │
│      LIMIT 20                            │
│    - Parse response                      │
│    - notifyListeners()                   │
│  }                                       │
│                                          │
└─────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│  UI Rebuilds (Consumer)                 │
├─────────────────────────────────────────┤
│                                          │
│  Consumer<NotificationController>:      │
│  - Get notifications list                │
│  - Build ListView                        │
│  - Show:                                 │
│    * Title and body                      │
│    * Timestamp                           │
│    * Read/unread indicator              │
│    * Delete button                       │
│                                          │
└─────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│  User Interaction                       │
├─────────────────────────────────────────┤
│                                          │
│  Option 1: Tap to mark as read           │
│  - Call controller.markAsRead(id)        │
│  - Updates in Supabase                   │
│  - UI updates via realtime               │
│                                          │
│  Option 2: Swipe to delete               │
│  - Call controller.deleteNotification()  │
│  - Deletes from Supabase                 │
│  - Removed from list immediately         │
│                                          │
│  Option 3: Just view                     │
│  - Reads notification                    │
│  - Can navigate to related content      │
│                                          │
└─────────────────────────────────────────┘
```

---

## Database Schema

### notifications Table

```sql
CREATE TABLE notifications (
  id UUID PRIMARY KEY,                 -- Unique identifier
  member_id UUID NOT NULL,             -- Recipient user ID
  session_id UUID,                     -- Related session (optional)
  title TEXT NOT NULL,                 -- Short title
  body TEXT NOT NULL,                  -- Full message
  event_type TEXT,                     -- Event that triggered this
  data JSONB DEFAULT '{}',             -- Custom data payload
  is_read BOOLEAN DEFAULT false,       -- Read status
  created_at TIMESTAMP,                -- When created
  delivered_at TIMESTAMP,              -- When delivered
  read_at TIMESTAMP,                   -- When marked as read
  
  -- Relationships
  CONSTRAINT fk_member 
    FOREIGN KEY (member_id) 
    REFERENCES profiles(id),
  CONSTRAINT fk_session 
    FOREIGN KEY (session_id) 
    REFERENCES sessions(id)
);

-- Indexes for queries
INDEX idx_member_created       -- Query by user and date
INDEX idx_member_is_read      -- Query unread for user
INDEX idx_created_at          -- Sort by date
INDEX idx_event_type          -- Filter by event
```

### notification_preferences Table

```sql
CREATE TABLE notification_preferences (
  member_id UUID PRIMARY KEY,          -- User who owns preferences
  enabled_channels TEXT[] DEFAULT [...], -- EMAIL, IN_APP, PUSH
  enabled_event_types TEXT[] DEFAULT [...], -- Which events trigger
  created_at TIMESTAMP,                -- Account creation
  updated_at TIMESTAMP,                -- Last preference change
  
  -- Relationships
  CONSTRAINT fk_member 
    FOREIGN KEY (member_id) 
    REFERENCES profiles(id)
);

-- Index for lookups
INDEX idx_member_id            -- Get preferences for user
```

### coach_follows Table

```sql
CREATE TABLE coach_follows (
  id UUID PRIMARY KEY,                 -- Unique identifier
  member_id UUID NOT NULL,             -- The follower
  coach_id UUID NOT NULL,              -- The coach being followed
  created_at TIMESTAMP,                -- When followed
  
  -- Constraint: Each member can only follow each coach once
  UNIQUE(member_id, coach_id),
  
  -- Relationships
  CONSTRAINT fk_member 
    FOREIGN KEY (member_id) 
    REFERENCES profiles(id),
  CONSTRAINT fk_coach 
    FOREIGN KEY (coach_id) 
    REFERENCES profiles(id)
);

-- Indexes for queries
INDEX idx_member_id            -- Get all coaches followed by member
INDEX idx_coach_id             -- Get all followers of coach
```

### Data Relationships

```
┌──────────────┐
│   profiles   │
│   (users)    │
├──────────────┤
│ id (UUID)    │
│ name         │
│ email        │
│ role         │
└──────────────┘
      ▲
      │ member_id
      │ coach_id
      │
      ├─────────────────────────┐
      │                         │
┌─────┴──────────────┐    ┌────┴──────────────┐
│ notifications      │    │ coach_follows      │
├────────────────────┤    ├────────────────────┤
│ id (UUID)          │    │ id (UUID)          │
│ member_id (FK) ───┬┘    │ member_id (FK) ───┬┘
│ title              │    │ coach_id (FK) ───┬─┐
│ body               │    │ created_at        │ │
│ is_read            │    └────────────────────┘ │
│ created_at         │      (many-to-many       │
│ read_at            │       relationship)       │
└────────────────────┘                          │
      ▲                                          │
      │ member_id                                │
      │                                          │
┌─────┴──────────────────────────────────────────┘
│
├──────────────────────────────┐
│ notification_preferences     │
├──────────────────────────────┤
│ member_id (FK, PK)           │
│ enabled_channels[]           │
│ enabled_event_types[]        │
│ created_at                   │
│ updated_at                   │
└──────────────────────────────┘
```

---

## Service Layer

### MultiChannelNotificationService (Orchestrator)

```
Purpose: Central coordination point for all notifications

┌──────────────────────────────────────────────────┐
│  MultiChannelNotificationService                 │
├──────────────────────────────────────────────────┤
│                                                   │
│  Public Interface:                               │
│  ├─ initialize()                                 │
│  ├─ sendNotification()                           │
│  ├─ notifySessionCreated()                       │
│  ├─ notifySpotAvailable()                        │
│  ├─ notifyWaitlistAvailable()                    │
│  ├─ notifySessionCancelled()                     │
│  ├─ notifyBookingConfirmed()                     │
│  ├─ markAsRead()                                 │
│  ├─ getNotifications()                           │
│  ├─ getUnreadNotifications()                     │
│  ├─ getUnreadCount()                             │
│  └─ deleteNotification()                         │
│                                                   │
│  Key Methods:                                    │
│                                                   │
│  notifySessionCreated(memberId, ...) {           │
│    1. Create NotificationData                    │
│    2. Get user preferences                       │
│    3. If EMAIL enabled:                          │
│       → MailtrapService.sendEmail()              │
│    4. If IN_APP enabled:                         │
│       → InAppNotificationService.create()        │
│    5. If PUSH enabled:                           │
│       → PushNotificationService.send()           │
│  }                                               │
│                                                   │
│  markAsRead(notificationId) {                    │
│    1. Find notification in DB                    │
│    2. Set read_at = now()                        │
│    3. Set is_read = true                         │
│    4. Update in Supabase                         │
│    5. Return success                             │
│  }                                               │
│                                                   │
└──────────────────────────────────────────────────┘
```

### InAppNotificationService (Database)

```
Purpose: Manage in-app notifications stored in Supabase

├─ createInAppNotification()  
│  └─ Insert into notifications table
│
├─ getNotifications()
│  └─ SELECT * FROM notifications WHERE member_id = ? 
│     LIMIT ? OFFSET ?
│
├─ getUnreadCount()
│  └─ SELECT COUNT(*) FROM notifications 
│     WHERE member_id = ? AND is_read = false
│
├─ markAsRead()
│  └─ UPDATE notifications SET is_read = true, read_at = now()
│
└─ deleteNotification()
   └─ DELETE FROM notifications WHERE id = ?
```

### MailtrapService (Email)

```
Purpose: Send email notifications via Mailtrap API

├─ initialize()
│  └─ Validate API token and configuration
│
├─ sendEmail()
│  ├─ Build email payload
│  ├─ POST to Mailtrap API
│  ├─ Parse response
│  └─ Return success/failure
│
└─ Parameters:
   ├─ to: recipient email
   ├─ subject: email subject
   ├─ templateId: template to use
   ├─ variables: template variables
   └─ replyTo: optional reply-to address
```

### PushNotificationService (FCM)

```
Purpose: Send push notifications via Firebase Cloud Messaging

├─ initialize()
│  └─ Configure FCM
│
├─ sendPushNotification()
│  ├─ Get device tokens for user
│  ├─ Send to Firebase
│  └─ Handle response
│
├─ sendPushNotificationsToMultiple()
│  └─ Batch send to multiple devices
│
├─ subscribeToTopic()
│  └─ Subscribe device to topic
│
└─ unsubscribeFromTopic()
   └─ Unsubscribe device from topic
```

---

## Notification Lifecycle

### Complete Lifecycle Diagram

```
                        ┌─────────────────┐
                        │  NOTIFICATION   │
                        │  CREATED        │
                        └────────┬────────┘
                                 │
                 ┌───────────────┼───────────────┐
                 │               │               │
                 ▼               ▼               ▼
           ┌─────────┐     ┌─────────┐     ┌──────────┐
           │ EMAIL   │     │ IN_APP  │     │ PUSH     │
           │ CHANNEL │     │ CHANNEL │     │ CHANNEL  │
           └────┬────┘     └────┬────┘     └────┬─────┘
                │               │               │
        ┌───────┴───────┐   ┌───┴────┐     ┌───┴────┐
        │               │   │        │     │        │
   Mailtrap API    Supabase DB  Firebase FCM
   Success/Fail   Insert OK    Success/Fail
        │               │         │
        └───────┬───────┴────────┘
                │
                ▼
        ┌──────────────────┐
        │ NOTIFICATION     │
        │ DELIVERED        │
        │ (sent to user)   │
        └────────┬─────────┘
                 │
      ┌──────────┴──────────┐
      │                     │
      ▼                     ▼
┌──────────────┐    ┌────────────────┐
│ USER NOT YET │    │  USER VIEWS    │
│  OPENED APP  │    │  NOTIFICATION  │
└──────┬───────┘    └────────┬───────┘
       │                     │
       │                  ┌──┴──┐
       │                  │     │
       │          ┌───────┘     └──────────┐
       │          │                       │
       ▼          ▼                       ▼
   ┌────────┐ ┌─────────┐           ┌────────────┐
   │ PUSH   │ │MARK AS  │           │ DISMISS    │
   │NOTIF   │ │READ     │           │ (DELETE)   │
   │ARRIVES │ │         │           │            │
   └────┬───┘ └────┬────┘           └─────┬──────┘
        │          │                      │
        │          ▼                      ▼
        │    ┌──────────────┐      ┌────────────┐
        │    │NOTIFICATION │      │NOTIFICATION│
        │    │STATUS:      │      │DELETED     │
        │    │IS_READ=true │      │FROM LIST   │
        │    │READ_AT=now()│      └────────────┘
        │    └──────────────┘
        │
        ▼
   ┌──────────────┐
   │ USER TAPS    │
   │ PUSH NOTIF   │
   └──────┬───────┘
          │
          ▼
   ┌──────────────┐
   │APP OPENS /   │
   │NAVIGATES TO  │
   │RELATED ITEM  │
   │(E.G. SESSION)│
   └──────────────┘
```

### State Transitions

```
State Machine for Notification

Initial State: NOT_DELIVERED

NOT_DELIVERED
  │
  ├─ All channels fail
  │  └─> DELIVERY_FAILED (retry later)
  │
  ├─ Some channels succeed
  │  └─> PARTIALLY_DELIVERED
  │
  └─> All channels succeed
     └─> DELIVERED

DELIVERED
  │
  ├─ User reads notification
  │  └─> READ (is_read = true, read_at = now)
  │
  ├─ User deletes notification
  │  └─> DELETED (removed from list)
  │
  └─ User ignores
     └─> UNREAD (no action taken)

READ
  │
  └─ User deletes
     └─> DELETED

UNREAD
  │
  ├─ User reads
  │  └─> READ
  │
  └─ User deletes
     └─> DELETED

DELETED
  (terminal state)
```

---

## User Journey

### User Journey 1: Member Follows Coach & Receives Notification

```
Actor: Member

Time: T0 - Browse Coach Directory
┌─────────────────────────────────┐
│ Member opens coach cards screen │
│ Sees list of available coaches  │
│ Taps "Follow" on coach card     │
└────────────┬────────────────────┘
             │
             ▼
Time: T1 - Follow Action
┌─────────────────────────────────┐
│ FollowButton.onPressed()        │
│ FollowController.followCoach()  │
│ Inserts into coach_follows      │
│ table                           │
│ UI updates: button shows filled │
└────────────┬────────────────────┘
             │
             ▼
Time: T2 - Coach Creates Session
┌─────────────────────────────────┐
│ Coach creates new session       │
│ System finds all followers      │
│ For each follower, triggers     │
│ notifySessionCreated()          │
└────────────┬────────────────────┘
             │
             ▼
Time: T3 - Notification Created & Sent
┌─────────────────────────────────┐
│ MultiChannelService routes to:  │
│ - Email (if enabled)            │
│ - In-App (if enabled)           │
│ - Push (if enabled)             │
│                                 │
│ Member receives email & push    │
│ In-app notification created     │
└────────────┬────────────────────┘
             │
             ▼
Time: T4 - Member Sees Notification
┌─────────────────────────────────┐
│ Member gets push notification   │
│ Taps it → Opens in-app          │
│ Notification center shows new   │
│ notification                    │
│ Badge on app shows 1 unread     │
└────────────┬────────────────────┘
             │
             ▼
Time: T5 - Member Interacts
┌─────────────────────────────────┐
│ Option A: Tap notification      │
│   → Marks as read               │
│   → Shows session details       │
│                                 │
│ Option B: Tap badge on home     │
│   → Goes to notification center │
│   → Views all notifications     │
│   → Marks as read               │
│                                 │
│ Option C: Dismiss               │
│   → Deletes notification        │
│   → Removed from list           │
└─────────────────────────────────┘
```

### User Journey 2: Customize Notification Preferences

```
Actor: Member

┌──────────────────────────────┐
│ Opens Settings screen        │
│ Taps "Notification Prefs"    │
└────────────┬─────────────────┘
             │
             ▼
┌──────────────────────────────┐
│ NotificationPreferencesScreen│
│ loads current preferences    │
│ Shows toggles for:           │
│ - Email channel              │
│ - In-App channel             │
│ - Push channel               │
│ - Each event type            │
└────────────┬─────────────────┘
             │
             ▼
┌──────────────────────────────┐
│ Member toggles:              │
│ - Disables Email             │
│ - Disables Session events    │
│ - Keeps In-App enabled       │
└────────────┬─────────────────┘
             │
             ▼
┌──────────────────────────────┐
│ Taps "Save" button           │
│ Controller.savePreferences() │
│ Updates database             │
│ Shows "Saved!" message       │
└────────────┬─────────────────┘
             │
             ▼
┌──────────────────────────────┐
│ Future notifications use:     │
│ - Only In-App channel        │
│ - Only non-session events    │
│ - Email never sent           │
└──────────────────────────────┘
```

---

## Error Handling

### Error Handling Strategy

```
┌──────────────────────────────────────────┐
│  Error Occurs                            │
├──────────────────────────────────────────┤
│                                          │
│  Error Types:                            │
│  ├─ Network errors                       │
│  ├─ Database errors                      │
│  ├─ API errors (Mailtrap)                │
│  ├─ FCM errors                           │
│  ├─ Invalid input                        │
│  └─ Permission errors (RLS)              │
│                                          │
└───────────┬──────────────────────────────┘
            │
            ▼
┌──────────────────────────────────────────┐
│  Error Recovery                          │
├──────────────────────────────────────────┤
│                                          │
│  Strategy by Error Type:                 │
│                                          │
│  Network Error:                          │
│  ├─ Log error                            │
│  ├─ Retry after delay (exponential)      │
│  ├─ Max retries: 3                       │
│  └─ Fail gracefully if all retries fail  │
│                                          │
│  Database Error:                         │
│  ├─ Log with full context                │
│  ├─ Don't retry (structural issue)       │
│  ├─ Return error to caller               │
│  └─ User sees error message              │
│                                          │
│  API Error (Mailtrap):                   │
│  ├─ Log response                         │
│  ├─ If rate limited: wait and retry      │
│  ├─ If auth error: notify admin          │
│  └─ Continue with other channels         │
│                                          │
│  Permission Error (RLS):                 │
│  ├─ Log detailed error                   │
│  ├─ Check auth.uid() matches             │
│  ├─ Verify RLS policies                  │
│  └─ User sees "access denied" message    │
│                                          │
│  Invalid Input:                          │
│  ├─ Validate in service                  │
│  ├─ Throw exception with details         │
│  ├─ Catch in controller                  │
│  └─ Show user-friendly error             │
│                                          │
└──────────────────────────────────────────┘
```

### Error Logging

```dart
// Errors logged at each level:

// Service Level
debugPrint('❌ MailtrapService: Failed to send email to $email: $error');

// Controller Level  
debugPrint('❌ NotificationController: Failed to fetch notifications: $error');

// UI Level
showErrorSnackbar(context, 'Failed to load notifications. Please try again.');

// Sentry/Firebase Logging (Optional)
FirebaseCrashlytics.instance.recordError(error, stackTrace);
```

---

## Performance Considerations

### Optimization Strategies

```
┌─────────────────────────────┐
│ Pagination                  │
├─────────────────────────────┤
│ Load 20 notifications       │
│ Load more on scroll         │
│ Prevents loading all at     │
│ once for users with many    │
│ notifications              │
└─────────────────────────────┘

┌─────────────────────────────┐
│ Caching                     │
├─────────────────────────────┤
│ Cache preferences locally   │
│ Cache follower counts       │
│ Reduces database queries    │
└─────────────────────────────┘

┌─────────────────────────────┐
│ Batch Operations            │
├─────────────────────────────┤
│ Mark multiple as read at    │
│ once vs. individual         │
│ Reduces database roundtrips │
└─────────────────────────────┘

┌─────────────────────────────┐
│ Lazy Loading                │
├─────────────────────────────┤
│ Load notification details   │
│ only when expanded          │
│ Faster initial display      │
└─────────────────────────────┘

┌─────────────────────────────┐
│ Real-time Updates           │
├─────────────────────────────┤
│ Use Supabase Realtime       │
│ Instant UI updates          │
│ No polling needed           │
└─────────────────────────────┘
```

---

## Summary

The notification system is built on:

1. **Layered Architecture**: UI → Controllers → Services → Database
2. **Multi-Channel Support**: Email, In-App, Push with preference control
3. **Real-Time Updates**: Supabase Realtime for instant UI sync
4. **Event-Driven**: Notifications triggered by specific system events
5. **Scalable**: Easy to add new event types or channels
6. **Robust**: Comprehensive error handling and recovery

For implementation details, see NOTIFICATION_SYSTEM_INTEGRATION_GUIDE.md
