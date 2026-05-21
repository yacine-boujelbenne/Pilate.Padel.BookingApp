# Implementation Checklist

**Complete checklist for implementing the notification system**

---

## Pre-Implementation

- [ ] Read the Overview in NOTIFICATION_SYSTEM_INTEGRATION_GUIDE.md
- [ ] Review System Architecture diagram
- [ ] Understand the components and data flow
- [ ] Check all team members have Supabase access
- [ ] Verify Mailtrap account is active
- [ ] Ensure Flutter environment is set up (3.19.0+)
- [ ] Clone latest repository code
- [ ] Back up current .env file

---

## Phase 1: Database Setup

### Create Tables in Supabase

- [ ] Open Supabase SQL Editor
- [ ] Create `notifications` table
  - [ ] Columns created correctly
  - [ ] Indexes created
  - [ ] Foreign keys set up
  - [ ] Check constraint is valid

- [ ] Create `notification_preferences` table
  - [ ] Columns created correctly
  - [ ] Default values set
  - [ ] Foreign keys set up
  
- [ ] Create `coach_follows` table
  - [ ] Columns created correctly
  - [ ] Unique constraint on (member_id, coach_id)
  - [ ] Indexes created

### Enable Row Level Security (RLS)

- [ ] Enable RLS on `notifications` table
  - [ ] SELECT policy created
  - [ ] UPDATE policy created
  - [ ] DELETE policy created
  - [ ] INSERT system policy created

- [ ] Enable RLS on `notification_preferences` table
  - [ ] SELECT policy created
  - [ ] UPDATE policy created
  - [ ] INSERT policy created

- [ ] Enable RLS on `coach_follows` table
  - [ ] SELECT policy created
  - [ ] INSERT policy created
  - [ ] DELETE policy created

### Verify Database Setup

- [ ] Run test query on each table
- [ ] Verify RLS policies are enforced
- [ ] Check indexes are created
- [ ] Test INSERT with Supabase client
- [ ] Test UPDATE with Supabase client
- [ ] Test DELETE with Supabase client

---

## Phase 2: Environment Configuration

### Mailtrap Setup

- [ ] Create Mailtrap account or log in
- [ ] Navigate to Integrations → Official Mailtrap API
- [ ] Copy API token
- [ ] Verify token format (long alphanumeric string)
- [ ] Test API token validity in Mailtrap console

### .env File Configuration

- [ ] Create or update `.env` file in project root
- [ ] Add SUPABASE_URL
  - [ ] Format: `https://your-project.supabase.co`
  - [ ] Verify correct project
  
- [ ] Add SUPABASE_ANON_KEY
  - [ ] Get from Supabase dashboard
  - [ ] Verify it's anon key (not service role)
  
- [ ] Add MAILTRAP_API_TOKEN
  - [ ] Paste token from Mailtrap
  - [ ] Remove any whitespace
  
- [ ] Add MAILTRAP_API_URL
  - [ ] Set to: `https://send.api.mailtrap.io/api/send`
  
- [ ] Add MAILTRAP_FROM_EMAIL
  - [ ] Set to your sender email
  - [ ] Must be verified in Mailtrap
  
- [ ] Add MAILTRAP_FROM_NAME
  - [ ] Set to company/app name

- [ ] Verify .env is in `.gitignore`
- [ ] Verify .env is NOT committed to git
- [ ] Test env loading with: `dotenv.get('MAILTRAP_API_TOKEN')`

### Firebase Setup (Optional - for Push Notifications)

- [ ] Go to Firebase Console
- [ ] Select your project
- [ ] Download google-services.json
- [ ] Place in `android/app/`
- [ ] Update AndroidManifest.xml if needed
- [ ] For iOS: Download GoogleService-Info.plist
- [ ] Place in `ios/Runner/`

---

## Phase 3: Flutter Dependencies

### Update pubspec.yaml

- [ ] Verify all notification packages present:
  - [ ] provider: ^6.1.0
  - [ ] supabase_flutter: ^2.3.0
  - [ ] firebase_core: ^4.7.0
  - [ ] firebase_messaging: ^16.2.0
  - [ ] flutter_local_notifications: ^17.0.0
  - [ ] http: ^1.1.0
  - [ ] flutter_dotenv: ^5.1.0
  - [ ] shared_preferences: ^2.2.0

- [ ] Verify .env is in assets section:
  ```yaml
  flutter:
    assets:
      - .env
  ```

### Install Packages

- [ ] Run `flutter pub get`
- [ ] Wait for installation to complete
- [ ] Check for any version conflicts
- [ ] Run `flutter doctor` to verify setup
- [ ] Resolve any warnings

### Platform-Specific Configuration

**Android (android/app/build.gradle)**
- [ ] compileSdkVersion is 33+
- [ ] minSdkVersion is 21+
- [ ] Verify Firebase plugin applied

**iOS (ios/Podfile)**
- [ ] Update pods: `cd ios && pod repo update && cd ..`
- [ ] Verify notification permissions in Runner settings

---

## Phase 4: Theme Integration

### Update main.dart

- [ ] Import NotificationService
- [ ] Import NotificationController
- [ ] Import FollowController
- [ ] Add dotenv.load() in main()
- [ ] Add Supabase.initialize() in main()
- [ ] Initialize Firebase if not web
- [ ] Add NotificationService.instance.initialize() in bootstrap

### Add Providers

- [ ] Add MultiProvider wrapper in main.dart
- [ ] Add ChangeNotifierProvider for NotificationController
- [ ] Add ChangeNotifierProvider for FollowController
- [ ] Verify all providers are in correct order
- [ ] Test app starts without errors

### Add Theme Colors (Optional)

- [ ] Update `lib/app/theme.dart`
- [ ] Add notification color palette
- [ ] Add notification text styles
- [ ] Verify colors match app design

---

## Phase 5: Service Initialization

### Initialize Services

- [ ] Create `lib/services/notification_service_init.dart`
- [ ] Implement NotificationServiceInitializer
- [ ] Initialize MailtrapService with error handling
- [ ] Initialize MultiChannelNotificationService
- [ ] Add initialization logging

### Home Screen Setup

- [ ] Open member home screen or main authenticated screen
- [ ] Add initState() override if not present
- [ ] Get userId from AuthController
- [ ] Call NotificationController.initialize(userId)
- [ ] Call FollowController.initialize(userId)
- [ ] Add error handling
- [ ] Test initialization completes without errors

### Controllers Updated

- [ ] NotificationController is properly initialized
- [ ] FollowController is properly initialized
- [ ] Both controllers fetch initial data
- [ ] Initial data loads without errors

---

## Phase 6: UI Integration

### Add Routes

- [ ] Open `lib/app/router.dart`
- [ ] Add route for `/member/notifications`
  - [ ] Points to NotificationCenterScreen
  - [ ] Path is correct
  
- [ ] Add route for `/notification-preferences`
  - [ ] Points to NotificationPreferencesScreen
  - [ ] Path is correct
  
- [ ] Add route for `/member/my-coaches`
  - [ ] Points to MyCoachesScreen
  - [ ] Path is correct
  
- [ ] Test routes are accessible
- [ ] Test navigation works correctly

### Update Existing Screens

#### Home/Dashboard Screen
- [ ] Add notification badge to AppBar
- [ ] Badge shows unread count
- [ ] Badge uses Consumer widget
- [ ] Tapping badge navigates to notifications
- [ ] Icon changes based on unread count

#### Coach Directory/Cards
- [ ] Add FollowButton to each coach card
- [ ] Button shows follow/unfollow state
- [ ] Button toggles state on tap
- [ ] Animation plays smoothly
- [ ] Follow state persists after navigation

#### Coach Detail Screen
- [ ] Add FollowersBadge near coach info
- [ ] Badge shows follower count
- [ ] Tapping badge opens followers list modal
- [ ] Modal shows list of followers
- [ ] Modal has working message/view profile buttons

#### Settings Screen
- [ ] Add "Notification Preferences" menu item
- [ ] Add "Notification Center" menu item
- [ ] Both links navigate correctly
- [ ] Icons are appropriate

#### Session Creation/Editing
- [ ] Add success notification when session created
- [ ] Notification mentions triggering coach followers
- [ ] Notification preferences shown to user

### Add Components

- [ ] NotificationBanner widget appears correctly
- [ ] NotificationBanner has working buttons
- [ ] NotificationBanner dismisses smoothly
- [ ] NotificationCenterScreen displays notifications
- [ ] NotificationPreferencesScreen has working toggles
- [ ] MyCoachesScreen displays followed coaches
- [ ] FollowersBadge displays counts correctly

---

## Phase 7: Testing the System

### Unit Tests

- [ ] Test NotificationData.fromMap() works
- [ ] Test NotificationData.toMap() works
- [ ] Test NotificationPreferences serialization
- [ ] Test event type parsing
- [ ] Run: `flutter test`
- [ ] All tests pass

### Manual Testing: Database

- [ ] [ ] Manually insert notification into Supabase
- [ ] Check notification appears in app
- [ ] Manually update notification is_read = true
- [ ] Check UI updates in real-time
- [ ] Delete notification from database
- [ ] Verify app removes it from list

### Manual Testing: Notifications Display

- [ ] Open notification center screen
- [ ] See list of notifications (or empty state)
- [ ] Notification shows title and body
- [ ] Notification shows timestamp
- [ ] Can scroll if many notifications
- [ ] Can tap notification to expand/view details
- [ ] Can mark as read (manual or on tap)
- [ ] Can delete notification (swipe or button)
- [ ] Empty state shown when no notifications

### Manual Testing: Notification Preferences

- [ ] Open notification preferences screen
- [ ] See all notification channels (EMAIL, IN_APP, PUSH)
- [ ] See all event types
- [ ] Can toggle each channel
- [ ] Can toggle each event type
- [ ] Save button works
- [ ] Success message shown
- [ ] Preferences persist on reload
- [ ] Settings apply to future notifications

### Manual Testing: Follow System

- [ ] Navigate to coach directory
- [ ] See Follow button on each coach
- [ ] Button shows outlined/unfilled initially
- [ ] Tap button to follow
- [ ] Button shows filled state
- [ ] Follow state persists on navigation
- [ ] Unfollow removes state
- [ ] Follower count updates on coach profile
- [ ] Followers modal shows followers

### Manual Testing: Email Notifications

- [ ] Set up test email template in Mailtrap
- [ ] Trigger notification that includes email
- [ ] Check Mailtrap inbox
- [ ] Email received with correct content
- [ ] Email formatting looks good
- [ ] Links in email work
- [ ] Disable email in preferences
- [ ] Trigger notification
- [ ] Email NOT sent to Mailtrap
- [ ] Re-enable and verify sends again

### Manual Testing: Edge Cases

- [ ] Send notification with empty body
- [ ] Send notification with very long body
- [ ] Send notification with special characters
- [ ] Test with all preferences disabled
- [ ] Test with no preferences saved
- [ ] Rapid notifications (stress test)
- [ ] Notifications with no data field
- [ ] Delete notification while reading
- [ ] Network error handling
- [ ] App crash recovery

### Device Testing

- [ ] Test on Android phone
- [ ] Test on Android tablet
- [ ] Test on iOS phone
- [ ] Test on iOS tablet
- [ ] Test in portrait orientation
- [ ] Test in landscape orientation
- [ ] Test with slow network (throttle)
- [ ] Test going offline then online
- [ ] Test app backgrounding/foregrounding

---

## Phase 8: Advanced Features (Optional)

### Implement Notification Triggers

- [ ] Trigger on session creation
  - [ ] Test coach creates session
  - [ ] Followers receive notification
  - [ ] Email sent if enabled
  
- [ ] Trigger on spot availability
  - [ ] Test spot opens in session
  - [ ] Waitlist members notified
  - [ ] In-app notification appears
  
- [ ] Trigger on session cancellation
  - [ ] Test cancel session
  - [ ] Booked members notified
  - [ ] Notification sent via all channels
  
- [ ] Trigger on booking confirmation
  - [ ] Test booking created
  - [ ] Confirmation notification sent
  - [ ] Email includes booking details

- [ ] Implement coach follow notifications
  - [ ] Member follows coach
  - [ ] Follow confirmed notification
  - [ ] Email sent if applicable

### Analytics (Optional)

- [ ] Track notification open rates
- [ ] Track notification click rates
- [ ] Track preference changes
- [ ] Monitor email delivery rates
- [ ] Monitor push delivery rates

---

## Phase 9: Performance & Optimization

### Performance Testing

- [ ] [ ] Measure app startup time
- [ ] Measure notification loading time
- [ ] Measure list scroll performance (100+ notifications)
- [ ] Measure email send time
- [ ] Memory usage with many notifications
- [ ] CPU usage during real-time updates

### Optimize If Needed

- [ ] Implement pagination for notifications
- [ ] Add caching for notifications
- [ ] Optimize database queries
- [ ] Use lazy loading for lists
- [ ] Debounce preference updates
- [ ] Batch email sends

---

## Phase 10: Deployment Preparation

### Code Review

- [ ] Code reviewed by team lead
- [ ] All TODOs addressed
- [ ] Error handling comprehensive
- [ ] Comments are clear and helpful
- [ ] No debug logging in production code
- [ ] Security review completed

### Documentation

- [ ] Integration guide is complete
- [ ] API documentation is accurate
- [ ] Architecture documentation is clear
- [ ] Troubleshooting guide is helpful
- [ ] Team trained on system

### Staging Testing

- [ ] Deploy to staging environment
- [ ] Full testing cycle on staging
- [ ] Load test with multiple users
- [ ] Test with realistic data volumes
- [ ] Verify Mailtrap sandbox emails
- [ ] Verify database performance

### Production Deployment

- [ ] Create database migration script
- [ ] Backup production database
- [ ] Deploy to production
- [ ] Verify all features working
- [ ] Monitor for errors in first hour
- [ ] Have rollback plan ready
- [ ] Notify team of deployment

### Post-Deployment

- [ ] Monitor error logs for 24 hours
- [ ] Check email delivery rates
- [ ] Verify notification performance
- [ ] Get user feedback
- [ ] Document any issues found
- [ ] Schedule follow-up review

---

## Sign-Off Checklist

### For Developers

- [ ] All code written and tested
- [ ] All features working as designed
- [ ] Documentation complete
- [ ] No blockers or technical debt
- [ ] Ready for code review

### For QA

- [ ] All test cases passed
- [ ] No critical bugs found
- [ ] Edge cases tested
- [ ] Performance acceptable
- [ ] Security verified
- [ ] Ready for deployment

### For Product

- [ ] Features meet requirements
- [ ] UI/UX acceptable
- [ ] Performance acceptable
- [ ] Analytics in place
- [ ] Ready for launch

---

## Common Issues & Resolutions

### Issue: Migrations failed
- [ ] Check for syntax errors in SQL
- [ ] Verify table doesn't already exist
- [ ] Check foreign key references exist
- [ ] Verify column types are correct
- **Resolution**: Drop tables and retry

### Issue: Notifications not appearing
- [ ] Check NotificationController initialized
- [ ] Verify RLS policies correct
- [ ] Check database has notification records
- [ ] Verify preferences not blocking
- **Resolution**: Enable debug logging and check console

### Issue: Emails not sending
- [ ] Verify Mailtrap token is valid
- [ ] Check email address is verified
- [ ] Verify API URL is correct
- [ ] Check network connectivity
- **Resolution**: Test Mailtrap API directly

### Issue: Performance degradation
- [ ] Check database query performance
- [ ] Verify indexes created
- [ ] Check for N+1 queries
- [ ] Monitor memory usage
- **Resolution**: Implement pagination/caching

### Issue: RLS policy errors
- [ ] Verify policies created correctly
- [ ] Check auth.uid() is available
- [ ] Verify member_id matches auth.uid()
- [ ] Check INSERT policy for system
- **Resolution**: Review and fix RLS policies

---

## Final Checklist

- [ ] All 10 phases completed
- [ ] All tests passing
- [ ] All documentation complete
- [ ] Team trained and ready
- [ ] Deployment plan ready
- [ ] Rollback plan in place
- [ ] Production environment ready
- [ ] Monitoring and alerts configured
- [ ] Support team trained
- [ ] Ready to go live! 🚀

---

**Status**: Complete checklist available  
**Last Updated**: 2024  
**Next Step**: Start Phase 1!

For detailed guidance on each phase, refer to NOTIFICATION_SYSTEM_INTEGRATION_GUIDE.md
