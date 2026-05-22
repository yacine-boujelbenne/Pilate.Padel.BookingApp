# Updating Existing Screens Integration Guide

**How to add notification system components to your existing screens**

---

## Overview

This guide provides copy-paste code examples for adding notification components to your existing screens without breaking current functionality.

---

## 1. Adding Notification Badge to App Bar

### Where to Add
- Member home screen
- Any main navigation screen
- Coach directory screen

### Before Code

```dart
class MemberHomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        elevation: 0,
      ),
      body: // ... existing body
    );
  }
}
```

### After Code (Add Notification Badge)

```dart
import 'controllers/notification_controller.dart';

class MemberHomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        elevation: 0,
        actions: [
          // NEW: Add notification badge
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
                  tooltip: 'Notifications',
                ),
              );
            },
          ),
          SizedBox(width: 8),
        ],
      ),
      body: // ... existing body
    );
  }
}
```

### What Changed
- ✅ Added `Consumer<NotificationController>` wrapper
- ✅ Added `Badge` widget for unread count
- ✅ Added `onPressed` to navigate to notifications
- ✅ Badge only shows when count > 0

### Testing
```dart
// Test 1: Badge shows correct count
expect(find.byType(Badge), findsOneWidget);

// Test 2: Navigation works
await tester.tap(find.byIcon(Icons.notifications));
expect(find.byType(NotificationCenterScreen), findsOneWidget);
```

---

## 2. Adding Follow Button to Coach Cards

### Where to Add
- Coach directory cards
- Coach search results
- Coach recommendation widgets

### Before Code

```dart
class CoachCard extends StatelessWidget {
  final Coach coach;

  const CoachCard({required this.coach});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          // Coach avatar
          CircleAvatar(
            backgroundImage: NetworkImage(coach.photoUrl),
            radius: 40,
          ),
          SizedBox(height: 8),
          // Coach name
          Text(coach.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          // Coach specialty
          Text(coach.specialty, style: TextStyle(fontSize: 12, color: Colors.grey)),
          SizedBox(height: 8),
          // View profile button
          ElevatedButton(
            onPressed: () => navigateToCoachDetail(context, coach.id),
            child: Text('View Profile'),
          ),
        ],
      ),
    );
  }
}
```

### After Code (Add Follow Button)

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
          // Coach avatar with follow button
          Stack(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(coach.photoUrl),
                radius: 40,
              ),
              // NEW: Add follow button (top right)
              Positioned(
                top: 0,
                right: 0,
                child: FollowButton(
                  coachId: coach.id,
                  size: 36,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          // Coach name
          Text(coach.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          // Coach specialty
          Text(coach.specialty, style: TextStyle(fontSize: 12, color: Colors.grey)),
          SizedBox(height: 8),
          // View profile button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => navigateToCoachDetail(context, coach.id),
                child: Text('View Profile'),
              ),
              // NEW: Message button (optional)
              OutlinedButton(
                onPressed: () => startChat(context, coach.id),
                child: Text('Message'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

### What Changed
- ✅ Wrapped avatar in Stack
- ✅ Added `FollowButton` overlay on avatar
- ✅ Positioned button at top-right
- ✅ Set appropriate button size (36)

### Alternative: Side-by-Side Layout

```dart
// If you prefer follow button next to name instead of overlay
ListTile(
  leading: CircleAvatar(
    backgroundImage: NetworkImage(coach.photoUrl),
    radius: 20,
  ),
  title: Text(coach.name),
  subtitle: Text(coach.specialty),
  trailing: FollowButton(
    coachId: coach.id,
    size: 40,
  ),
  onTap: () => navigateToCoachDetail(context, coach.id),
)
```

### Testing
```dart
// Test 1: Follow button exists
expect(find.byType(FollowButton), findsWidgets);

// Test 2: Following works
await tester.tap(find.byType(FollowButton).first);
await tester.pumpAndSettle();
// Verify follow state changed
```

---

## 3. Adding Followers Badge to Coach Detail Screen

### Where to Add
- Coach detail header
- Coach profile screen
- Coach stats section

### Before Code

```dart
class CoachDetailScreen extends StatefulWidget {
  final String coachId;

  @override
  State<CoachDetailScreen> createState() => _CoachDetailScreenState();
}

class _CoachDetailScreenState extends State<CoachDetailScreen> {
  late Coach coach;

  @override
  void initState() {
    super.initState();
    _loadCoachDetails();
  }

  Future<void> _loadCoachDetails() async {
    // Load coach from API
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(coach.photoUrl, fit: BoxFit.cover),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                SizedBox(height: 16),
                Text(coach.name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text(coach.specialty, style: TextStyle(fontSize: 14, color: Colors.grey)),
                SizedBox(height: 16),
                // Session details
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

### After Code (Add Followers Badge and Stats)

```dart
import 'widgets/followers_badge.dart';
import 'widgets/followers_list.dart';

class CoachDetailScreen extends StatefulWidget {
  final String coachId;

  @override
  State<CoachDetailScreen> createState() => _CoachDetailScreenState();
}

class _CoachDetailScreenState extends State<CoachDetailScreen> {
  late Coach coach;

  @override
  void initState() {
    super.initState();
    _loadCoachDetails();
  }

  Future<void> _loadCoachDetails() async {
    // Load coach from API
  }

  // NEW: Show followers modal
  void _showFollowersList() {
    showDialog(
      context: context,
      builder: (_) => FollowersListModal(
        coachId: coach.id,
        coachName: coach.name,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(coach.photoUrl, fit: BoxFit.cover),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                SizedBox(height: 16),
                Text(coach.name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text(coach.specialty, style: TextStyle(fontSize: 14, color: Colors.grey)),
                
                // NEW: Add followers badge with stats
                SizedBox(height: 16),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Followers stat
                      GestureDetector(
                        onTap: _showFollowersList,
                        child: Column(
                          children: [
                            FollowersBadge(
                              coachId: coach.id,
                              showLabel: false,
                            ),
                            SizedBox(height: 4),
                            Text('Followers', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      
                      // Sessions stat
                      Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blue.withOpacity(0.1),
                            ),
                            child: Text('${coach.sessionCount}', 
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          ),
                          SizedBox(height: 4),
                          Text('Sessions', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      
                      // Rating stat
                      Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.amber.withOpacity(0.1),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.star, color: Colors.amber, size: 20),
                                Text('${coach.rating}', 
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          SizedBox(height: 4),
                          Text('Rating', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 16),
                // Session details
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

### What Changed
- ✅ Imported `FollowersBadge` and `FollowersListModal`
- ✅ Added `_showFollowersList()` method
- ✅ Added stats row with followers, sessions, rating
- ✅ Made followers section tappable (shows modal)
- ✅ Styled stats as circular badges

### Testing
```dart
// Test 1: Badge displays
expect(find.byType(FollowersBadge), findsOneWidget);

// Test 2: Tapping opens followers modal
await tester.tap(find.byType(FollowersBadge));
await tester.pumpAndSettle();
expect(find.byType(FollowersListModal), findsOneWidget);
```

---

## 4. Adding Notification Preferences to Settings Screen

### Where to Add
- Settings or account screen
- Preferences section
- Bottom of menu

### Before Code

```dart
class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.person),
            title: Text('Profile'),
            onTap: () => context.go('/profile'),
          ),
          ListTile(
            leading: Icon(Icons.lock),
            title: Text('Privacy'),
            onTap: () => context.go('/privacy'),
          ),
          ListTile(
            leading: Icon(Icons.help),
            title: Text('Help & Support'),
            onTap: () => context.go('/help'),
          ),
        ],
      ),
    );
  }
}
```

### After Code (Add Notification Links)

```dart
class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: ListView(
        children: [
          // Existing items
          ListTile(
            leading: Icon(Icons.person),
            title: Text('Profile'),
            onTap: () => context.go('/profile'),
          ),
          ListTile(
            leading: Icon(Icons.lock),
            title: Text('Privacy'),
            onTap: () => context.go('/privacy'),
          ),
          
          // NEW: Notification section divider
          SizedBox(height: 16),
          Padding(
            padding: EdgeInsets.only(left: 16, top: 8, bottom: 8),
            child: Text('NOTIFICATIONS', style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            )),
          ),
          
          // NEW: Notification preferences
          ListTile(
            leading: Icon(Icons.notifications_active),
            title: Text('Notification Preferences'),
            subtitle: Text('Email, push, and in-app settings'),
            trailing: Icon(Icons.chevron_right),
            onTap: () => context.go('/notification-preferences'),
          ),
          
          // NEW: Notification center
          ListTile(
            leading: Icon(Icons.mail),
            title: Text('Notification Center'),
            subtitle: Text('View all your notifications'),
            trailing: Icon(Icons.chevron_right),
            onTap: () => context.go('/member/notifications'),
          ),
          
          Divider(),
          
          // Existing items
          ListTile(
            leading: Icon(Icons.help),
            title: Text('Help & Support'),
            onTap: () => context.go('/help'),
          ),
        ],
      ),
    );
  }
}
```

### What Changed
- ✅ Added "NOTIFICATIONS" section header
- ✅ Added "Notification Preferences" link
- ✅ Added "Notification Center" link
- ✅ Added subtitles explaining each
- ✅ Added proper spacing and dividers

### Testing
```dart
// Test 1: Links visible
expect(find.text('Notification Preferences'), findsOneWidget);
expect(find.text('Notification Center'), findsOneWidget);

// Test 2: Navigation works
await tester.tap(find.text('Notification Preferences'));
await tester.pumpAndSettle();
expect(find.byType(NotificationPreferencesScreen), findsOneWidget);
```

---

## 5. Adding Notification Banner to Session/Home Screen

### Where to Add
- Home screen when spot available
- Session details screen
- Search results when special offer

### Before Code

```dart
class MemberHomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Banner or hero section
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.blue.shade100,
              child: Text('Welcome back!'),
            ),
            SizedBox(height: 16),
            // Session list
          ],
        ),
      ),
    );
  }
}
```

### After Code (Add Notification Banner)

```dart
import 'widgets/notification_banner.dart';

class MemberHomeScreen extends StatefulWidget {
  @override
  State<MemberHomeScreen> createState() => _MemberHomeScreenState();
}

class _MemberHomeScreenState extends State<MemberHomeScreen> {
  // NEW: Track if banner should show
  bool _showNotificationBanner = true;
  String? _bannerSessionId;

  @override
  void initState() {
    super.initState();
    _checkForNotifications();
  }

  // NEW: Check for important notifications
  Future<void> _checkForNotifications() async {
    // Example: Check if session spot just became available
    // In real app, subscribe to real-time updates
  }

  // NEW: Handle banner booking
  void _onBannerBook() {
    if (_bannerSessionId != null) {
      context.go('/sessions/$_bannerSessionId/booking');
    }
  }

  // NEW: Handle banner dismiss
  void _onBannerDismiss() {
    setState(() {
      _showNotificationBanner = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: Stack(
        children: [
          // Main content
          SingleChildScrollView(
            child: Column(
              children: [
                // Banner or hero section
                Container(
                  padding: EdgeInsets.all(16),
                  color: Colors.blue.shade100,
                  child: Text('Welcome back!'),
                ),
                SizedBox(height: 16),
                // Session list
              ],
            ),
          ),
          
          // NEW: Notification banner overlay (only if needed)
          if (_showNotificationBanner)
            Positioned(
              top: 80,
              left: 0,
              right: 0,
              child: NotificationBanner(
                title: 'Spot Available!',
                subtitle: 'Monday 6pm - Pilates Advanced',
                onBook: _onBannerBook,
                onDismiss: _onBannerDismiss,
              ),
            ),
        ],
      ),
    );
  }
}
```

### What Changed
- ✅ Added `NotificationBanner` widget
- ✅ Added state to track banner visibility
- ✅ Positioned banner overlay on top
- ✅ Added methods for book and dismiss
- ✅ Banner dismisses smoothly on tap

### Alternative: Inline Placement

```dart
// Instead of overlay, show banner as part of list
Column(
  children: [
    if (_showNotificationBanner)
      NotificationBanner(
        title: 'Spot Available!',
        subtitle: 'Monday 6pm',
        onBook: _onBannerBook,
        onDismiss: _onBannerDismiss,
      ),
    // Rest of content
  ],
)
```

### Testing
```dart
// Test 1: Banner shows
expect(find.byType(NotificationBanner), findsOneWidget);

// Test 2: Book button works
await tester.tap(find.text('Book'));
await tester.pumpAndSettle();
// Verify navigation to booking

// Test 3: Dismiss works
await tester.tap(find.text('Dismiss'));
await tester.pumpAndSettle();
expect(find.byType(NotificationBanner), findsNothing);
```

---

## 6. Complete Screen Example: Coach Directory with All Features

This is how a fully integrated coach directory screen looks:

```dart
import 'widgets/follow_button.dart';
import 'widgets/followers_badge.dart';
import 'widgets/followers_list.dart';
import 'controllers/follow_controller.dart';

class CoachDirectoryScreen extends StatefulWidget {
  @override
  State<CoachDirectoryScreen> createState() => _CoachDirectoryScreenState();
}

class _CoachDirectoryScreenState extends State<CoachDirectoryScreen> {
  late List<Coach> coaches;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCoaches();
  }

  Future<void> _loadCoaches() async {
    // Load coaches from API
    setState(() => isLoading = false);
  }

  void _showFollowersList(String coachId, String coachName) {
    showDialog(
      context: context,
      builder: (_) => FollowersListModal(
        coachId: coachId,
        coachName: coachName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Find Your Coach'),
        elevation: 0,
        actions: [
          // Notification badge in app bar
          Consumer<NotificationController>(
            builder: (context, notificationController, _) {
              return Badge(
                label: Text('${notificationController.unreadCount}'),
                isLabelVisible: notificationController.unreadCount > 0,
                child: IconButton(
                  icon: Icon(Icons.notifications),
                  onPressed: () => context.go('/member/notifications'),
                ),
              );
            },
          ),
          SizedBox(width: 8),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: coaches.length,
              itemBuilder: (context, index) {
                final coach = coaches[index];
                return Card(
                  margin: EdgeInsets.all(8),
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      children: [
                        // Coach header with follow button
                        Row(
                          children: [
                            // Avatar
                            Stack(
                              children: [
                                CircleAvatar(
                                  backgroundImage: NetworkImage(coach.photoUrl),
                                  radius: 32,
                                ),
                                // Follow button overlay
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: FollowButton(
                                    coachId: coach.id,
                                    size: 32,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(width: 12),
                            // Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    coach.name,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    coach.specialty,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.star, size: 16, color: Colors.amber),
                                      Text(
                                        '${coach.rating}',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      SizedBox(width: 8),
                                      // Followers
                                      GestureDetector(
                                        onTap: () => _showFollowersList(coach.id, coach.name),
                                        child: FollowersBadge(
                                          coachId: coach.id,
                                          showLabel: true,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Divider(),
                        SizedBox(height: 8),
                        // Action buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: () => context.go('/coach/${coach.id}'),
                              child: Text('View Profile'),
                            ),
                            OutlinedButton(
                              onPressed: () {
                                // Start chat with coach
                              },
                              child: Text('Message'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
```

---

## Migration Checklist

When updating each screen:

- [ ] Import all required widgets and controllers
- [ ] Add Consumer or watch for reactive updates
- [ ] Test navigation to new screens works
- [ ] Verify no UI breaking changes
- [ ] Check responsiveness on different screen sizes
- [ ] Test with slow network (throttle)
- [ ] Verify offline behavior if applicable
- [ ] Update any related unit tests
- [ ] Get code review from team

---

## Common Patterns

### Pattern 1: Show Badge with Count

```dart
Badge(
  label: Text('$count'),
  isLabelVisible: count > 0,
  child: Icon(Icons.notifications),
)
```

### Pattern 2: Tappable Stats

```dart
GestureDetector(
  onTap: () => showDialog(...),
  child: Column(
    children: [
      // Stat display
      Text('Stat'),
    ],
  ),
)
```

### Pattern 3: Overlay Button

```dart
Stack(
  children: [
    // Main content
    Container(),
    // Overlay button (top-right)
    Positioned(
      top: 0,
      right: 0,
      child: FollowButton(...),
    ),
  ],
)
```

### Pattern 4: Conditional Rendering

```dart
if (shouldShow)
  Widget()
else
  SizedBox.shrink()
```

---

## Styling Considerations

### Spacing
- Use `SizedBox` for consistent spacing
- Match existing app spacing (typically 8, 12, 16, 24)

### Colors
- Use existing theme colors where possible
- Add new notification colors to theme.dart if needed

### Typography
- Use existing TextStyle from theme
- Keep heading sizes consistent

### Animations
- Use smooth transitions
- Keep animations under 300ms
- Test on slower devices

---

## Testing Updated Screens

```dart
// Test that existing functionality still works
testWidgets('existing button still works', (WidgetTester tester) async {
  await tester.pumpWidget(MyApp());
  expect(find.text('Existing Button'), findsOneWidget);
  await tester.tap(find.text('Existing Button'));
  await tester.pumpAndSettle();
  // Verify action completes
});

// Test new notification features
testWidgets('notification badge shows', (WidgetTester tester) async {
  await tester.pumpWidget(MyApp());
  expect(find.byType(Badge), findsOneWidget);
  // Verify badge displays correct count
});
```

---

## Rollback Steps

If integration causes issues:

1. Revert the screen file to previous version
2. Remove new imports
3. Remove provider usage
4. Restart app
5. Verify functionality returns to normal
6. Investigate what went wrong
7. Re-integrate carefully

---

## Next Steps

After updating all necessary screens:

1. ✅ Run full test suite
2. ✅ Manual testing on devices
3. ✅ Code review
4. ✅ Update documentation
5. ✅ Deploy to production

---

**Status**: Ready for integration  
**Last Updated**: 2024  
**Difficulty**: Beginner-Intermediate

For more details, see NOTIFICATION_SYSTEM_INTEGRATION_GUIDE.md
