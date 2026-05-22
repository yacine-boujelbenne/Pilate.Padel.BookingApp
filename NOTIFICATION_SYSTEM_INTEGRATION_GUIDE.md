# Notification System Integration Guide

**Complete Step-by-Step Guide for Implementing the Multi-Channel Notification System**

---

## 📑 Table of Contents

1. [Overview](#overview)
2. [System Architecture](#system-architecture)
3. [Prerequisites](#prerequisites)
4. [Step 1: Database Setup](#step-1-database-setup)
5. [Step 2: Environment Configuration](#step-2-environment-configuration)
6. [Step 3: Flutter Dependencies](#step-3-flutter-dependencies)
7. [Step 4: Theme Integration](#step-4-theme-integration)
8. [Step 5: Service Initialization](#step-5-service-initialization)
9. [Step 6: UI Integration](#step-6-ui-integration)
10. [Step 7: Testing the System](#step-7-testing-the-system)
11. [Advanced: Triggering Notifications](#advanced-triggering-notifications)
12. [Troubleshooting](#troubleshooting)
13. [Related Documentation](#related-documentation)

---

## Overview

The **Multi-Channel Notification System** provides a robust, scalable solution for sending notifications through multiple channels (Email, In-App, Push) with user preference management and real-time delivery tracking.

### ✨ Key Features

- **Multi-Channel Support**: Email, In-App, and Push notifications
- **User Preferences**: Complete control over notification channels and event types
- **Real-Time Updates**: Supabase realtime integration for instant notifications
- **Event-Driven**: Triggered by specific events (session created, booking confirmed, etc.)
- **Preference-Based Routing**: Respects user preferences before sending
- **Modern UI**: Beautiful, responsive notification center and preferences screen
- **Error Handling**: Comprehensive error handling and recovery
- **Scalable Architecture**: Easy to add new notification types and channels

### 📊 System Components

```
┌─────────────────────────────────────────────────────────┐
│                  Notification System                     │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  ┌──────────────────────────────────────────────────┐   │
│  │  UI Layer (Widgets & Screens)                    │   │
│  ├──────────────────────────────────────────────────┤   │
│  │ • NotificationBanner      • FollowButton         │   │
│  │ • NotificationCenter      • FollowersBadge       │   │
│  │ • NotificationPreferences • FollowersList        │   │
│  └──────────────────────────────────────────────────┘   │
│                           ▲                              │
│                           │                              │
│  ┌──────────────────────────────────────────────────┐   │
│  │  State Management (Controllers)                  │   │
│  ├──────────────────────────────────────────────────┤   │
│  │ • NotificationController (UI state)              │   │
│  │ • FollowController (Follow/Follower state)       │   │
│  └──────────────────────────────────────────────────┘   │
│                           ▲                              │
│                           │                              │
│  ┌──────────────────────────────────────────────────┐   │
│  │  Service Layer                                   │   │
│  ├──────────────────────────────────────────────────┤   │
│  │ • MultiChannelNotificationService (Orchestrator) │   │
│  │ • InAppNotificationService (Database)            │   │
│  │ • MailtrapService (Email delivery)               │   │
│  │ • PushNotificationService (FCM)                  │   │
│  │ • NotificationService (Firebase/FCM setup)       │   │
│  └──────────────────────────────────────────────────┘   │
│                           ▲                              │
│                           │                              │
│  ┌──────────────────────────────────────────────────┐   │
│  │  Data Layer                                      │   │
│  ├──────────────────────────────────────────────────┤   │
│  │ • Supabase (notifications table)                 │   │
│  │ • Supabase (notification_preferences table)      │   │
│  │ • Supabase (coach_follows table)                 │   │
│  └──────────────────────────────────────────────────┘   │
│                                                           │
└─────────────────────────────────────────────────────────┘
```

---

## System Architecture

### Data Models

**NotificationData** (`lib/models/notification_model.dart`)
```
NotificationData
├── id: UUID
├── memberId: UUID (receiver)
├── sessionId: UUID? (optional context)
├── title: String
├── body: String
├── eventType: NotificationEvent (enum)
├── data: Map<String, dynamic> (custom fields)
├── createdAt: DateTime
├── deliveredAt: DateTime?
├── readAt: DateTime?
└── isRead: bool
```

**NotificationPreferences** (`lib/models/notification_model.dart`)
```
NotificationPreferences
├── memberId: UUID
├── enabledChannels: List<NotificationChannel>
│   ├── EMAIL
│   ├── IN_APP
│   └── PUSH
├── enabledEventTypes: List<NotificationEvent>
│   ├── COACH_SESSION_CREATED
│   ├── SESSION_SPOT_AVAILABLE
│   ├── WAITLIST_AVAILABLE
│   ├── SESSION_CANCELLED
│   └── BOOKING_CONFIRMED
└── updatedAt: DateTime
```

### Notification Events

| Event | Triggered When | Example |
|-------|---|---|
| `COACH_SESSION_CREATED` | Coach creates new session | "Coach John created Pilates Advanced" |
| `SESSION_SPOT_AVAILABLE` | Spot opens on followed coach's session | "Spot available in Monday 6pm class" |
| `WAITLIST_AVAILABLE` | Member moves up on waitlist | "You're 1st on the waitlist" |
| `SESSION_CANCELLED` | Session is cancelled | "Monday 6pm class cancelled" |
| `BOOKING_CONFIRMED` | Member's booking confirmed | "Your booking for Monday is confirmed" |
| `CUSTOM` | Custom event | Custom messages |

---

## Prerequisites

Before starting, ensure you have:

- ✅ Flutter 3.19.0+ installed
- ✅ Supabase project created with:
  - `profiles` table (user accounts)
  - `sessions` table (pilates sessions)
  - `bookings` table (session bookings)
- ✅ Mailtrap account (for email notifications)
- ✅ Firebase project configured (for push notifications)
- ✅ `.env` file in your project root
- ✅ Familiarity with Flutter, Provider state management, and Supabase

### Required Packages (Already in pubspec.yaml)

```yaml
supabase_flutter: ^2.3.0        # Database & Auth
provider: ^6.1.0                # State management
firebase_core: ^4.7.0           # Firebase setup
firebase_messaging: ^16.2.0     # Push notifications
flutter_local_notifications: ^17.0.0  # Local notifications
http: ^1.1.0                    # HTTP requests (Mailtrap)
flutter_dotenv: ^5.1.0          # Environment variables
shared_preferences: ^2.2.0      # Local storage
```

---

## Step 1: Database Setup

### 1.1 Create Tables in Supabase

Open your Supabase project's SQL Editor and run these migrations:

#### 1.1.1 Create notifications Table

```sql
-- Create notifications table for storing all notifications
CREATE TABLE public.notifications (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  member_id UUID NOT NULL,
  session_id UUID,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  event_type TEXT,
  data JSONB DEFAULT '{}',
  is_read BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  delivered_at TIMESTAMP WITH TIME ZONE,
  read_at TIMESTAMP WITH TIME ZONE,
  CONSTRAINT fk_member_id FOREIGN KEY (member_id) REFERENCES profiles(id) ON DELETE CASCADE,
  CONSTRAINT fk_session_id FOREIGN KEY (session_id) REFERENCES sessions(id) ON DELETE SET NULL
);

-- Create indexes for better performance
CREATE INDEX idx_notifications_member_id ON public.notifications(member_id);
CREATE INDEX idx_notifications_created_at ON public.notifications(created_at DESC);
CREATE INDEX idx_notifications_is_read ON public.notifications(is_read);
CREATE INDEX idx_notifications_member_read ON public.notifications(member_id, is_read);
CREATE INDEX idx_notifications_event_type ON public.notifications(event_type);

-- Enable Row Level Security
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view their own notifications"
  ON public.notifications FOR SELECT
  USING (auth.uid() = member_id);

CREATE POLICY "Users can update their own notifications"
  ON public.notifications FOR UPDATE
  USING (auth.uid() = member_id);

CREATE POLICY "Users can delete their own notifications"
  ON public.notifications FOR DELETE
  USING (auth.uid() = member_id);

CREATE POLICY "System can insert notifications"
  ON public.notifications FOR INSERT
  WITH CHECK (true);
```

#### 1.1.2 Create notification_preferences Table

```sql
-- Create notification_preferences table for user settings
CREATE TABLE public.notification_preferences (
  member_id UUID NOT NULL PRIMARY KEY,
  enabled_channels TEXT[] DEFAULT ARRAY['EMAIL', 'IN_APP', 'PUSH'],
  enabled_event_types TEXT[] DEFAULT ARRAY[
    'COACH_SESSION_CREATED',
    'SESSION_SPOT_AVAILABLE',
    'WAITLIST_AVAILABLE',
    'SESSION_CANCELLED',
    'BOOKING_CONFIRMED'
  ],
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  CONSTRAINT fk_member_id FOREIGN KEY (member_id) REFERENCES profiles(id) ON DELETE CASCADE
);

-- Create index for faster lookups
CREATE INDEX idx_notification_preferences_member_id ON public.notification_preferences(member_id);

-- Enable Row Level Security
ALTER TABLE public.notification_preferences ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view their own preferences"
  ON public.notification_preferences FOR SELECT
  USING (auth.uid() = member_id);

CREATE POLICY "Users can update their own preferences"
  ON public.notification_preferences FOR UPDATE
  USING (auth.uid() = member_id);

CREATE POLICY "Users can insert their own preferences"
  ON public.notification_preferences FOR INSERT
  WITH CHECK (auth.uid() = member_id);
```

#### 1.1.3 Create coach_follows Table (For Follow Notifications)

```sql
-- Create coach_follows table for coach following feature
CREATE TABLE public.coach_follows (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  member_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  coach_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  UNIQUE(member_id, coach_id)
);

-- Create indexes
CREATE INDEX coach_follows_member_id ON coach_follows(member_id);
CREATE INDEX coach_follows_coach_id ON coach_follows(coach_id);

-- Enable Row Level Security
ALTER TABLE public.coach_follows ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view coach follows"
  ON coach_follows FOR SELECT
  USING (member_id = auth.uid() OR coach_id = auth.uid());

CREATE POLICY "Users can create their own follows"
  ON coach_follows FOR INSERT
  WITH CHECK (member_id = auth.uid());

CREATE POLICY "Users can delete their own follows"
  ON coach_follows FOR DELETE
  USING (member_id = auth.uid());
```

### 1.2 Verify Tables

After running migrations, verify in Supabase:
- [ ] `notifications` table created with all columns
- [ ] `notification_preferences` table created
- [ ] `coach_follows` table created
- [ ] All indexes created
- [ ] RLS enabled and policies applied

---

## Step 2: Environment Configuration

### 2.1 Get Mailtrap Credentials

1. Go to [Mailtrap.io](https://mailtrap.io)
2. Sign up or log in to your account
3. Create a new account (if not already done)
4. Go to **Sending Domains** → **Integrations**
5. Select **Official Mailtrap API**
6. Get your API token (looks like: `1a2b3c4d5e6f7g8h9i0j`)

**Reference**: [Mailtrap Official Docs](https://mailtrap.io/api-documentation/)

### 2.2 Update .env File

Add these variables to your `.env` file in the project root:

```env
# Supabase Configuration
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here

# Mailtrap Configuration
MAILTRAP_API_TOKEN=your-api-token-here
MAILTRAP_API_URL=https://send.api.mailtrap.io/api/send
MAILTRAP_FROM_EMAIL=notifications@flexpilates.app
MAILTRAP_FROM_NAME=Flex Pilates Studio

# Firebase Configuration (Optional - for push notifications)
FIREBASE_API_KEY=your-firebase-api-key
FIREBASE_PROJECT_ID=your-project-id
```

### 2.3 Configure pubspec.yaml

Make sure `.env` is included in assets:

```yaml
flutter:
  assets:
    - .env
```

### 2.4 Test Configuration

Run this command to verify environment variables are loaded:

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load(fileName: '.env');
  print('Mailtrap Token: ${dotenv.get('MAILTRAP_API_TOKEN')}');
}
```

---

## Step 3: Flutter Dependencies

### 3.1 Verify Dependencies

All required packages should already be in `pubspec.yaml`. Verify:

```bash
flutter pub get
```

### 3.2 Check Package Versions

Required packages:
- ✅ `provider: ^6.1.0` - State management
- ✅ `supabase_flutter: ^2.3.0` - Database
- ✅ `firebase_core: ^4.7.0` - Firebase setup
- ✅ `firebase_messaging: ^16.2.0` - Push notifications
- ✅ `flutter_local_notifications: ^17.0.0` - Local notifications
- ✅ `http: ^1.1.0` - HTTP client
- ✅ `flutter_dotenv: ^5.1.0` - .env loading
- ✅ `shared_preferences: ^2.2.0` - Local storage

### 3.3 Platform-Specific Setup

#### For Android (android/app/build.gradle)

```gradle
android {
    compileSdkVersion 33  // or higher
    
    defaultConfig {
        minSdkVersion 21   // Required for Firebase
    }
}
```

#### For iOS (ios/Podfile)

```ruby
target 'Runner' do
  post_install do |installer|
    installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
          '$(inherited)',
          'PERMISSION_NOTIFICATIONS=1',
        ]
      end
    end
  end
end
```

---

## Step 4: Theme Integration

### 4.1 Update main.dart

Add notification system initialization to your app's bootstrap:

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'controllers/notification_controller.dart';
import 'controllers/follow_controller.dart';
import 'services/notification_service.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: '.env');
  
  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );
  
  // Initialize Firebase (if not web)
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp();
    } catch (_) {
      // Firebase initialization is optional
    }
  }
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    try {
      // Initialize push notification service
      await NotificationService.instance.initialize();
    } catch (e) {
      debugPrint('Notification initialization failed: $e');
      // Notifications are optional, don't fail app startup
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ... existing providers
        
        // Add notification providers
        ChangeNotifierProvider(
          create: (_) => NotificationController(),
        ),
        ChangeNotifierProvider(
          create: (_) => FollowController(),
        ),
        
        // ... other providers
      ],
      child: MaterialApp(
        title: 'Flex Pilates Studio',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
```

### 4.2 Add Theme Colors for Notifications

In your `lib/app/theme.dart`:

```dart
class AppColors {
  // Notification colors
  static const Color notificationBg = Color(0xFFF0F8FF); // Light blue
  static const Color notificationBorder = Color(0xFF4A90E2); // Blue
  static const Color notificationText = Color(0xFF1A1A1A); // Dark text
  
  // Status colors
  static const Color unreadNotification = Color(0xFFE8F4F8);
  static const Color readNotification = Color(0xFFFAFAFA);
  static const Color successNotification = Color(0xFFE8F5E9); // Green
  static const Color warningNotification = Color(0xFFFFF3E0); // Orange
  static const Color errorNotification = Color(0xFFFFEBEE); // Red
}

class AppTextStyles {
  static const TextStyle notificationTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.notificationText,
  );
  
  static const TextStyle notificationBody = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Color(0xFF666666),
  );
  
  static const TextStyle notificationTimestamp = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: Color(0xFF999999),
  );
}
```

---

## Step 5: Service Initialization

### 5.1 Initialize MultiChannelNotificationService

Create or update `lib/services/notification_service_init.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'multi_channel_notification_service.dart';
import 'mailtrap_service.dart';
import 'supabase_service.dart';

class NotificationServiceInitializer {
  static final NotificationServiceInitializer _instance = 
    NotificationServiceInitializer._internal();

  factory NotificationServiceInitializer() {
    return _instance;
  }

  NotificationServiceInitializer._internal();

  /// Initialize all notification services
  /// Must be called once during app bootstrap
  Future<void> initialize() async {
    try {
      debugPrint('🔔 Initializing Notification Services...');
      
      // Initialize Mailtrap for email notifications
      await _initializeMailtrap();
      
      // Initialize MultiChannelNotificationService
      await _initializeMultiChannel();
      
      debugPrint('✅ Notification services initialized successfully');
    } catch (e) {
      debugPrint('❌ Notification initialization error: $e');
      rethrow;
    }
  }

  Future<void> _initializeMailtrap() async {
    try {
      final mailtrap = MailtrapService();
      await mailtrap.initialize();
      debugPrint('✅ Mailtrap initialized');
    } catch (e) {
      debugPrint('⚠️  Mailtrap initialization warning: $e');
      // Email is optional, don't fail
    }
  }

  Future<void> _initializeMultiChannel() async {
    try {
      final service = MultiChannelNotificationService();
      await service.initialize();
      debugPrint('✅ MultiChannelNotificationService initialized');
    } catch (e) {
      debugPrint('❌ MultiChannelNotificationService error: $e');
      rethrow;
    }
  }

  /// Get the notification service instance
  MultiChannelNotificationService getNotificationService() {
    return MultiChannelNotificationService();
  }
}
```

### 5.2 Initialize Controllers in Home Screen

When user logs in, initialize the notification controllers:

```dart
// In your home screen or main authenticated screen
class MemberHomeScreen extends StatefulWidget {
  @override
  State<MemberHomeScreen> createState() => _MemberHomeScreenState();
}

class _MemberHomeScreenState extends State<MemberHomeScreen> {
  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    final authController = context.read<AuthController>();
    final userId = authController.user?.id;
    
    if (userId != null) {
      try {
        // Initialize notification controller
        await context.read<NotificationController>().initialize(userId);
        debugPrint('✅ NotificationController initialized');
        
        // Initialize follow controller
        await context.read<FollowController>().initialize(userId);
        debugPrint('✅ FollowController initialized');
      } catch (e) {
        debugPrint('❌ Controller initialization error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        actions: [
          // Notification badge
          Consumer<NotificationController>(
            builder: (context, notificationController, _) {
              return Badge(
                label: Text('${notificationController.unreadCount}'),
                isLabelVisible: notificationController.unreadCount > 0,
                child: IconButton(
                  icon: const Icon(Icons.notifications),
                  onPressed: () {
                    context.go('/member/notifications');
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Text('Home Screen'),
      ),
    );
  }
}
```

---

## Step 6: UI Integration

### 6.1 Add Notification Banner to Screens

Use the pre-built `NotificationBanner` widget to display important notifications:

```dart
import 'widgets/notification_banner.dart';

class SessionListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Your content
          SingleChildScrollView(
            child: Column(
              children: [
                // Session list
              ],
            ),
          ),
          
          // Notification banner at top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: NotificationBanner(
              title: 'Spot Available!',
              subtitle: 'Monday 6pm Pilates Advanced',
              onBook: () {
                // Navigate to booking
                context.go('/sessions/booking');
              },
              onDismiss: () {
                // Remove banner
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

### 6.2 Add Notification Center Screen

The `NotificationCenterScreen` is pre-built. Add to your navigation:

```dart
// In lib/app/router.dart
GoRoute(
  path: '/member/notifications',
  builder: (context, state) => const NotificationCenterScreen(),
),
```

### 6.3 Add Notification Preferences Screen

The `NotificationPreferencesScreen` is pre-built. Add to your navigation:

```dart
// In lib/app/router.dart
GoRoute(
  path: '/notification-preferences',
  builder: (context, state) => const NotificationPreferencesScreen(),
),
```

### 6.4 Add Follow Button to Coach Cards

```dart
import 'widgets/follow_button.dart';

class CoachCard extends StatelessWidget {
  final Coach coach;

  const CoachCard({required this.coach});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          // Coach image and info
          ListTile(
            title: Text(coach.name),
            subtitle: Text(coach.specialty),
            trailing: FollowButton(
              coachId: coach.id,
              size: 48,
            ),
          ),
          // Rest of card
        ],
      ),
    );
  }
}
```

### 6.5 Add Followers Badge to Coach Detail

```dart
import 'widgets/followers_badge.dart';
import 'widgets/followers_list.dart';

class CoachDetailScreen extends StatelessWidget {
  final String coachId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Coach header
          GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => FollowersListModal(
                  coachId: coachId,
                  coachName: 'Coach Name',
                ),
              );
            },
            child: FollowersBadge(
              coachId: coachId,
              showLabel: true,
            ),
          ),
          // Rest of screen
        ],
      ),
    );
  }
}
```

### 6.6 Add Notification Link to Settings

```dart
// In settings_screen.dart
class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: ListView(
        children: [
          // ... other settings
          
          ListTile(
            leading: Icon(Icons.notifications),
            title: Text('Notification Preferences'),
            subtitle: Text('Email, push, and in-app'),
            onTap: () {
              context.go('/notification-preferences');
            },
          ),
          
          Divider(),
          
          ListTile(
            leading: Icon(Icons.mail),
            title: Text('Notification Center'),
            subtitle: Text('View all notifications'),
            onTap: () {
              context.go('/member/notifications');
            },
          ),
        ],
      ),
    );
  }
}
```

---

## Step 7: Testing the System

### 7.1 Unit Testing

Create `test/services/notification_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flex_pilates_studio/models/notification_model.dart';

void main() {
  group('NotificationData', () {
    test('creates notification from map', () {
      final map = {
        'id': '123',
        'member_id': 'user-123',
        'title': 'Test',
        'body': 'Test Body',
        'event_type': 'COACH_SESSION_CREATED',
        'data': {},
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      };

      final notification = NotificationData.fromMap(map);
      
      expect(notification.id, '123');
      expect(notification.title, 'Test');
      expect(notification.isRead, false);
    });

    test('converts to map correctly', () {
      final notification = NotificationData(
        id: '123',
        memberId: 'user-123',
        title: 'Test',
        body: 'Test Body',
        eventType: NotificationEvent.COACH_SESSION_CREATED,
        data: {},
        createdAt: DateTime.now(),
      );

      final map = notification.toMap();
      
      expect(map['id'], '123');
      expect(map['title'], 'Test');
      expect(map['is_read'], false);
    });
  });
}
```

### 7.2 Manual Testing Checklist

#### Test Notification Creation
- [ ] Create a session as coach
- [ ] Check `notifications` table in Supabase
- [ ] Verify notification record created
- [ ] Check event_type matches

#### Test Email Delivery
- [ ] Configure Mailtrap sandbox domain
- [ ] Trigger a notification
- [ ] Check Mailtrap inbox
- [ ] Verify email formatting

#### Test In-App Notifications
- [ ] Open notification center screen
- [ ] Trigger a notification
- [ ] Verify it appears in list
- [ ] Mark as read
- [ ] Verify read status updates

#### Test Push Notifications
- [ ] Install app on physical device
- [ ] Grant notification permissions
- [ ] Trigger a notification
- [ ] Verify push notification appears
- [ ] Tap notification
- [ ] Verify it navigates correctly

#### Test Preferences
- [ ] Go to notification preferences
- [ ] Toggle email channel
- [ ] Trigger notification
- [ ] Verify email not sent
- [ ] Toggle back on
- [ ] Verify email sent

#### Test Follow System
- [ ] Follow a coach
- [ ] Verify `coach_follows` entry created
- [ ] View followers list
- [ ] Unfollow coach
- [ ] Verify entry deleted

#### Test Edge Cases
- [ ] Send notification with no preferences
- [ ] Send notification with all channels disabled
- [ ] Send notification with no data
- [ ] Test with very long title/body
- [ ] Test with special characters

### 7.3 Debug Commands

Enable debug logging:

```dart
// In main.dart
bool _debugLogging = true;

// In notification services
void _log(String message) {
  if (kDebugMode) {
    debugPrint('🔔 Notification: $message');
  }
}
```

Monitor Supabase in real-time:

```dart
// Subscribe to notifications
final sub = supabaseClient
    .from('notifications')
    .on(RealtimeListenTypes.allEvents, (payload) {
      print('Notification event: ${payload.eventType}');
      print('New data: ${payload.newRecord}');
    })
    .subscribe();
```

---

## Advanced: Triggering Notifications

### 8.1 In Session Creation (Coach)

```dart
// In coach_controller.dart or session_controller.dart
Future<void> createSession(SessionModel session) async {
  try {
    // Create session in database
    final response = await supabaseClient
        .from('sessions')
        .insert(session.toMap())
        .select()
        .single();

    final sessionId = response['id'] as String;

    // Trigger notifications for all followers
    final notificationService = MultiChannelNotificationService();
    
    // Get all followers of this coach
    final followers = await supabaseClient
        .from('coach_follows')
        .select()
        .eq('coach_id', currentCoachId);

    // Send notification to each follower
    for (final follower in followers) {
      final memberId = follower['member_id'] as String;
      
      await notificationService.notifySessionCreated(
        memberId: memberId,
        coachName: currentCoachName,
        sessionTitle: session.title,
        sessionTime: session.startTime,
        sessionId: sessionId,
      );
    }
  } catch (e) {
    debugPrint('Error creating session: $e');
    rethrow;
  }
}
```

### 8.2 In Spot Availability Check

```dart
// When spots open up in a session
Future<void> checkAndNotifySpotAvailability(String sessionId) async {
  try {
    // Get session details
    final session = await supabaseClient
        .from('sessions')
        .select()
        .eq('id', sessionId)
        .single();

    final availableSpots = session['spots_available'] as int;

    if (availableSpots > 0) {
      // Get all members interested in this session type
      final notificationService = MultiChannelNotificationService();
      
      // Get waitlist members
      final waitlistMembers = await supabaseClient
          .from('session_waitlist')
          .select()
          .eq('session_id', sessionId);

      for (final member in waitlistMembers) {
        final memberId = member['member_id'] as String;
        
        await notificationService.notifySpotAvailable(
          memberId: memberId,
          sessionTitle: session['title'],
          sessionTime: session['start_time'],
          spotsAvailable: availableSpots,
          sessionId: sessionId,
        );
      }
    }
  } catch (e) {
    debugPrint('Error checking spot availability: $e');
  }
}
```

### 8.3 In Session Cancellation

```dart
// When session is cancelled
Future<void> cancelSession(String sessionId) async {
  try {
    // Update session status
    await supabaseClient
        .from('sessions')
        .update({'status': 'cancelled'})
        .eq('id', sessionId);

    // Get session details
    final session = await supabaseClient
        .from('sessions')
        .select()
        .eq('id', sessionId)
        .single();

    // Get all booked members
    final bookings = await supabaseClient
        .from('bookings')
        .select()
        .eq('session_id', sessionId);

    final notificationService = MultiChannelNotificationService();

    // Notify each member
    for (final booking in bookings) {
      final memberId = booking['member_id'] as String;
      
      await notificationService.notifySessionCancelled(
        memberId: memberId,
        sessionTitle: session['title'],
        sessionTime: session['start_time'],
        reason: 'Coach unavailable',
      );
    }
  } catch (e) {
    debugPrint('Error cancelling session: $e');
    rethrow;
  }
}
```

---

## Troubleshooting

### Issue: Notifications Not Appearing

**Problem**: Notifications created but not showing in the app

**Solutions**:
1. ✅ Verify `NotificationController.initialize()` called
2. ✅ Check notification preferences are enabled for event type
3. ✅ Verify RLS policies allow read access
4. ✅ Check Supabase connectivity
5. ✅ Look for errors in debug console

```dart
// Debug check
final controller = context.read<NotificationController>();
print('Notifications: ${controller.notifications.length}');
print('Unread count: ${controller.unreadCount}');
print('Error: ${controller.error}');
```

### Issue: Emails Not Sending

**Problem**: Mailtrap configured but emails not received

**Solutions**:
1. ✅ Verify Mailtrap API token in `.env`
2. ✅ Check API URL is correct
3. ✅ Verify email is from authorized sender
4. ✅ Check Mailtrap inbox (not spam folder)
5. ✅ Review Mailtrap logs for error details

```dart
// Test Mailtrap directly
final mailtrap = MailtrapService();
await mailtrap.initialize();
final success = await mailtrap.sendEmail(
  to: 'test@example.com',
  subject: 'Test',
  templateId: 'test',
  variables: {},
);
print('Email sent: $success');
```

### Issue: Database RLS Errors

**Problem**: "new row violates row-level security policy"

**Solutions**:
1. ✅ Verify RLS policies are correct
2. ✅ Check that INSERT policy allows system operations
3. ✅ Verify member_id matches auth.uid()
4. ✅ Check foreign key constraints

```sql
-- Verify RLS policies
SELECT * FROM pg_policies WHERE schemaname = 'public';

-- Check notifications table
SELECT * FROM information_schema.role_table_grants 
WHERE table_name='notifications';
```

### Issue: Push Notifications Not Working

**Problem**: Firebase configured but push notifications not received

**Solutions**:
1. ✅ Verify Firebase project ID
2. ✅ Check device has valid FCM token
3. ✅ Verify notification permission granted
4. ✅ Test on physical device (not simulator)
5. ✅ Check Firebase console for errors

```dart
// Get and log FCM token
final token = await FirebaseMessaging.instance.getToken();
print('FCM Token: $token');

// Test notification permission
final setting = await FirebaseMessaging.instance.requestPermission();
print('Permission granted: ${setting.isEnabled}');
```

### Issue: Controllers Not Updating UI

**Problem**: NotificationController changes don't trigger widget rebuild

**Solutions**:
1. ✅ Verify `notifyListeners()` called after state changes
2. ✅ Use `Consumer` or `watch` provider to listen
3. ✅ Check Provider is in widget tree
4. ✅ Verify stream subscriptions are active

```dart
// Check provider is set up
final controller = context.read<NotificationController>();
print('Controller hash: ${controller.hashCode}');

// Use consumer to listen
Consumer<NotificationController>(
  builder: (context, controller, _) {
    print('Rebuilding with ${controller.notifications.length} notifications');
    return Text('${controller.unreadCount} unread');
  },
)
```

### Issue: "MAILTRAP_API_TOKEN is not set"

**Problem**: Mailtrap service throws initialization error

**Solutions**:
1. ✅ Verify `.env` file exists in project root
2. ✅ Check `MAILTRAP_API_TOKEN=` line has value
3. ✅ Reload app after .env changes
4. ✅ Verify `flutter_dotenv` in pubspec.yaml
5. ✅ Check `.env` is in assets section of pubspec.yaml

```yaml
flutter:
  assets:
    - .env  # Make sure this line exists
```

---

## Related Documentation

### Core Documentation
- 📘 [Notification System Architecture](ARCHITECTURE_OVERVIEW.md)
- 📋 [API Reference Guide](API_REFERENCE.md)
- 🚀 [Quick Start Guide](QUICKSTART_INTEGRATION.md)
- ✅ [Implementation Checklist](CHECKLIST_IMPLEMENTATION.md)

### Integration Guides
- 🔧 [Updating Existing Screens](UPDATING_EXISTING_SCREENS.md)
- 🎨 [UI Components Reference](MODERN_UI_GUIDE.md)
- 📊 [Database Setup](DATABASE_SETUP.md)

### External References
- 🔗 [Mailtrap API Documentation](https://mailtrap.io/api-documentation/)
- 🔗 [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
- 🔗 [Supabase Realtime](https://supabase.com/docs/guides/realtime)
- 🔗 [Flutter Provider Package](https://pub.dev/packages/provider)

---

## Quick Reference

### Common Methods

```dart
// NotificationController
final controller = context.read<NotificationController>();
controller.fetchNotifications()           // Load all notifications
controller.markAsRead(notificationId)     // Mark single as read
controller.deleteNotification(id)         // Delete notification
controller.getUnreadCount()               // Get unread count

// MultiChannelNotificationService
final service = MultiChannelNotificationService();
service.notifySessionCreated(...)         // Session created event
service.notifySpotAvailable(...)          // Spot available event
service.notifyWaitlistAvailable(...)      // Waitlist event
service.notifySessionCancelled(...)       // Cancellation event
service.notifyBookingConfirmed(...)       // Booking event
```

### Navigation

```dart
// Navigate to notification center
context.go('/member/notifications');

// Navigate to preferences
context.go('/notification-preferences');

// Navigate to my coaches
context.go('/member/my-coaches');
```

### State Access

```dart
// Get notifications count
final unreadCount = context.watch<NotificationController>().unreadCount;

// Check if loading
final isLoading = context.watch<NotificationController>().isLoading;

// Get error message
final error = context.watch<NotificationController>().error;
```

---

## Next Steps

1. ✅ Complete [Database Setup](#step-1-database-setup)
2. ✅ Complete [Environment Configuration](#step-2-environment-configuration)
3. ✅ Complete [Service Initialization](#step-5-service-initialization)
4. ✅ Integrate [UI Components](#step-6-ui-integration)
5. ✅ Run [Testing Checklist](#step-7-testing-the-system)
6. ✅ Deploy to production

---

**Status**: Complete Integration Guide  
**Last Updated**: 2024  
**Version**: 1.0  

For questions, refer to troubleshooting section or check related documentation files.
