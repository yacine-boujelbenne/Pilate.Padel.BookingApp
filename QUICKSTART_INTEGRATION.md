# Quick Start Integration Guide

**Get the Notification System Running in 5 Minutes**

---

## ⚡ Super Quick Setup

### 1 min: Database Setup

Copy-paste these into Supabase SQL Editor:

```sql
-- Tables
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

CREATE INDEX idx_notifications_member_id ON public.notifications(member_id);
CREATE INDEX idx_notifications_created_at ON public.notifications(created_at DESC);
CREATE INDEX idx_notifications_is_read ON public.notifications(is_read);
CREATE INDEX idx_notifications_member_read ON public.notifications(member_id, is_read);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

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

-- Preferences Table
CREATE TABLE public.notification_preferences (
  member_id UUID NOT NULL PRIMARY KEY,
  enabled_channels TEXT[] DEFAULT ARRAY['EMAIL', 'IN_APP', 'PUSH'],
  enabled_event_types TEXT[] DEFAULT ARRAY['COACH_SESSION_CREATED', 'SESSION_SPOT_AVAILABLE', 'WAITLIST_AVAILABLE', 'SESSION_CANCELLED', 'BOOKING_CONFIRMED'],
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  CONSTRAINT fk_member_id FOREIGN KEY (member_id) REFERENCES profiles(id) ON DELETE CASCADE
);

CREATE INDEX idx_notification_preferences_member_id ON public.notification_preferences(member_id);
ALTER TABLE public.notification_preferences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own preferences"
  ON public.notification_preferences FOR SELECT
  USING (auth.uid() = member_id);

CREATE POLICY "Users can update their own preferences"
  ON public.notification_preferences FOR UPDATE
  USING (auth.uid() = member_id);

CREATE POLICY "Users can insert their own preferences"
  ON public.notification_preferences FOR INSERT
  WITH CHECK (auth.uid() = member_id);

-- Coach Follows
CREATE TABLE public.coach_follows (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  member_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  coach_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  UNIQUE(member_id, coach_id)
);

CREATE INDEX coach_follows_member_id ON coach_follows(member_id);
CREATE INDEX coach_follows_coach_id ON coach_follows(coach_id);

ALTER TABLE public.coach_follows ENABLE ROW LEVEL SECURITY;

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

### 1 min: Update .env

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
MAILTRAP_API_TOKEN=your-api-token-here
MAILTRAP_API_URL=https://send.api.mailtrap.io/api/send
MAILTRAP_FROM_EMAIL=notifications@flexpilates.app
MAILTRAP_FROM_NAME=Flex Pilates Studio
```

### 1 min: Update main.dart

```dart
import 'controllers/notification_controller.dart';
import 'controllers/follow_controller.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ... existing providers
        ChangeNotifierProvider(create: (_) => NotificationController()),
        ChangeNotifierProvider(create: (_) => FollowController()),
      ],
      child: MaterialApp(
        home: const HomeScreen(),
      ),
    );
  }
}
```

### 1 min: Add Provider Setup

In your home screen's `initState()`:

```dart
@override
void initState() {
  super.initState();
  final userId = context.read<AuthController>().user?.id;
  if (userId != null) {
    context.read<NotificationController>().initialize(userId);
    context.read<FollowController>().initialize(userId);
  }
}
```

### 1 min: Add Routes

Ensure routes exist in `lib/app/router.dart`:

```dart
GoRoute(
  path: '/member/notifications',
  builder: (context, state) => const NotificationCenterScreen(),
),
GoRoute(
  path: '/notification-preferences',
  builder: (context, state) => const NotificationPreferencesScreen(),
),
GoRoute(
  path: '/member/my-coaches',
  builder: (context, state) => const MyCoachesScreen(),
),
```

---

## 🎯 Copy-Paste Snippets

### Add Notification Badge to AppBar

```dart
AppBar(
  title: Text('Home'),
  actions: [
    Consumer<NotificationController>(
      builder: (context, notifier, _) => Badge(
        label: Text('${notifier.unreadCount}'),
        isLabelVisible: notifier.unreadCount > 0,
        child: IconButton(
          icon: Icon(Icons.notifications),
          onPressed: () => context.go('/member/notifications'),
        ),
      ),
    ),
  ],
)
```

### Add Follow Button to Coach Card

```dart
FollowButton(
  coachId: coach.id,
  size: 48,
  onFollowChanged: () {
    // Optional: refresh UI
  },
)
```

### Add Followers Badge

```dart
GestureDetector(
  onTap: () => showDialog(
    context: context,
    builder: (_) => FollowersListModal(
      coachId: coachId,
      coachName: coachName,
    ),
  ),
  child: FollowersBadge(
    coachId: coachId,
    showLabel: true,
  ),
)
```

### Add Settings Link

```dart
ListTile(
  leading: Icon(Icons.notifications),
  title: Text('Notifications'),
  onTap: () => context.go('/notification-preferences'),
),
```

### Add Notification Banner

```dart
NotificationBanner(
  title: 'Spot Available!',
  subtitle: 'Monday 6pm Class',
  onBook: () => context.go('/sessions/booking'),
  onDismiss: () => setState(() {}),
)
```

---

## ✅ Quick Test Checklist

- [ ] Database tables created in Supabase
- [ ] .env file has Mailtrap token
- [ ] pubspec.yaml has all dependencies
- [ ] Providers added to main.dart
- [ ] Controllers initialized in home screen
- [ ] Routes added to router.dart
- [ ] Notification badge shows on AppBar
- [ ] Can navigate to notification center
- [ ] Can open notification preferences
- [ ] Follow button works on coach cards
- [ ] Followers badge displays count

---

## 🐛 Quick Troubleshooting

**Notifications not showing?**
```dart
// Check if controller initialized
final ctrl = context.read<NotificationController>();
print('Notifications: ${ctrl.notifications.length}');
print('Error: ${ctrl.error}');
```

**Mailtrap error?**
```dart
// Verify .env is loaded
print(dotenv.get('MAILTRAP_API_TOKEN'));  // Should not be empty
```

**Routes not found?**
```dart
// Test navigation directly
context.go('/member/notifications');  // Should work
```

**Provider errors?**
```dart
// Ensure providers are above MaterialApp
MultiProvider(
  providers: [...],
  child: MaterialApp(...),
)
```

---

## 📱 Common Tasks

### Send Notification (From Backend)

```dart
final service = MultiChannelNotificationService();
await service.notifySessionCreated(
  memberId: userId,
  coachName: 'John',
  sessionTitle: 'Pilates Advanced',
  sessionTime: DateTime.now(),
  sessionId: sessionId,
);
```

### Mark Notification as Read

```dart
final controller = context.read<NotificationController>();
await controller.markAsRead(notificationId);
```

### Delete Notification

```dart
final controller = context.read<NotificationController>();
await controller.deleteNotification(notificationId);
```

### Get Unread Count

```dart
final count = context.watch<NotificationController>().unreadCount;
```

### Navigate to Notifications

```dart
context.go('/member/notifications');
```

---

## 🎨 Styling (Optional)

In `lib/app/theme.dart`:

```dart
class AppColors {
  static const Color notificationBg = Color(0xFFF0F8FF);
  static const Color notificationBorder = Color(0xFF4A90E2);
  static const Color successNotification = Color(0xFFE8F5E9);
  static const Color errorNotification = Color(0xFFFFEBEE);
}
```

---

## 📚 Need More Details?

See:
- 📘 [Full Integration Guide](NOTIFICATION_SYSTEM_INTEGRATION_GUIDE.md)
- 🏗️ [Architecture Overview](ARCHITECTURE_OVERVIEW.md)
- 📋 [API Reference](API_REFERENCE.md)
- ✅ [Complete Checklist](CHECKLIST_IMPLEMENTATION.md)
- 🔧 [Updating Screens](UPDATING_EXISTING_SCREENS.md)

---

**Status**: Ready to use in 5 minutes  
**For Production**: Run full integration guide after quick start  
**Questions**: Check troubleshooting or full documentation
