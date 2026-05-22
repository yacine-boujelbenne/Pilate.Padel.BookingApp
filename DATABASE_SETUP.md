# Notification System - Database Setup Guide

## Overview
This guide provides SQL scripts to set up the database tables required for the notification system in Supabase.

## Prerequisites
- Access to Supabase project SQL editor
- Admin privileges on the database
- Existing `profiles` table (for user references)
- Existing `sessions` table (for session references)

## Required Tables

### 1. notification_preferences Table

This table stores user notification preferences.

```sql
-- Create notification_preferences table
CREATE TABLE public.notification_preferences (
  member_id UUID NOT NULL PRIMARY KEY,
  email_enabled BOOLEAN NOT NULL DEFAULT true,
  in_app_enabled BOOLEAN NOT NULL DEFAULT true,
  push_enabled BOOLEAN NOT NULL DEFAULT true,
  session_notifications_enabled BOOLEAN NOT NULL DEFAULT true,
  coach_updates_enabled BOOLEAN NOT NULL DEFAULT true,
  waitlist_alerts_enabled BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  CONSTRAINT fk_member_id FOREIGN KEY (member_id) REFERENCES profiles(id) ON DELETE CASCADE
);

-- Create index for faster lookups
CREATE INDEX idx_notification_preferences_member_id ON public.notification_preferences(member_id);

-- Enable Row Level Security
ALTER TABLE public.notification_preferences ENABLE ROW LEVEL SECURITY;

-- Create RLS policy for users to read/update their own preferences
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

### 2. notifications Table Extension

The `notifications` table should already exist from the existing system. Verify it has the following structure and make adjustments if needed:

```sql
-- Create notifications table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.notifications (
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

-- Create indexes for better query performance
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

-- Create policy for system to insert notifications
CREATE POLICY "System can insert notifications"
  ON public.notifications FOR INSERT
  WITH CHECK (true);
```

### 3. user_devices Table (for Push Notifications)

This table tracks device tokens for push notifications:

```sql
-- Create user_devices table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.user_devices (
  installation_id TEXT NOT NULL PRIMARY KEY,
  user_id UUID NOT NULL,
  platform TEXT NOT NULL, -- 'android', 'ios', 'web'
  push_provider TEXT NOT NULL DEFAULT 'fcm', -- Firebase Cloud Messaging
  device_token TEXT NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT true,
  last_seen_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  last_refreshed_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  deactivated_at TIMESTAMP WITH TIME ZONE,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  CONSTRAINT fk_user_id FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE
);

-- Create indexes
CREATE INDEX idx_user_devices_user_id ON public.user_devices(user_id);
CREATE INDEX idx_user_devices_is_active ON public.user_devices(is_active);
CREATE INDEX idx_user_devices_device_token ON public.user_devices(device_token);

-- Enable Row Level Security
ALTER TABLE public.user_devices ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view their own devices"
  ON public.user_devices FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own devices"
  ON public.user_devices FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "System can manage devices"
  ON public.user_devices FOR ALL
  WITH CHECK (true);
```

## Setup Instructions

### Step 1: Access Supabase SQL Editor
1. Go to your Supabase project
2. Navigate to SQL Editor
3. Click "New Query"

### Step 2: Create notification_preferences Table
1. Copy the SQL script for `notification_preferences` table
2. Paste into SQL editor
3. Click "Run"
4. Wait for confirmation

### Step 3: Verify/Extend notifications Table
1. Check if `notifications` table exists: `SELECT * FROM notifications LIMIT 1;`
2. If it doesn't exist or is missing columns, run the create script
3. Add any missing indexes

### Step 4: Create user_devices Table
1. Copy the SQL script for `user_devices` table
2. Paste into SQL editor
3. Click "Run"
4. Wait for confirmation

### Step 5: Verify Tables
```sql
-- Check if all tables exist
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('notification_preferences', 'notifications', 'user_devices');
```

Should return 3 rows.

## Verification Queries

### Check notification_preferences table
```sql
SELECT COUNT(*) FROM public.notification_preferences;
```

### Check notifications table structure
```sql
\d public.notifications
```

### Check user_devices table
```sql
SELECT COUNT(*) FROM public.user_devices WHERE is_active = true;
```

### View indexes
```sql
SELECT indexname FROM pg_indexes WHERE tablename = 'notification_preferences';
SELECT indexname FROM pg_indexes WHERE tablename = 'notifications';
SELECT indexname FROM pg_indexes WHERE tablename = 'user_devices';
```

## Data Migration (if needed)

If you have existing notifications without preferences, create default preferences:

```sql
-- Create default preferences for all existing users who don't have them
INSERT INTO public.notification_preferences (member_id)
SELECT DISTINCT id FROM profiles
WHERE id NOT IN (SELECT member_id FROM notification_preferences)
ON CONFLICT (member_id) DO NOTHING;
```

## Backup and Recovery

### Backup notification preferences
```sql
-- Export as CSV
\COPY (SELECT * FROM notification_preferences) TO '/path/to/notification_preferences.csv' WITH CSV HEADER;
```

### Restore from backup
```sql
-- Import from CSV
\COPY notification_preferences FROM '/path/to/notification_preferences.csv' WITH CSV HEADER;
```

## Testing

After setup, test with sample data:

```sql
-- Insert test user notification
INSERT INTO public.notifications (member_id, title, body, event_type, is_read, data)
VALUES (
  'test-user-id-here',
  'Test Notification',
  'This is a test notification',
  'CUSTOM',
  false,
  '{"test": true}'
);

-- Verify it was created
SELECT * FROM public.notifications 
WHERE title = 'Test Notification';

-- Check preferences for a user
SELECT * FROM public.notification_preferences 
WHERE member_id = 'test-user-id-here';
```

## Troubleshooting

### Permission Denied Errors
- Ensure your Supabase account has admin privileges
- Check if user exists in profiles table before creating preferences

### Foreign Key Constraint Errors
- Verify profiles table exists
- Verify sessions table exists
- Check that referenced user IDs/session IDs exist

### Index Already Exists Errors
- Check if indexes were already created
- Use `IF NOT EXISTS` clause in creation scripts

### RLS Policy Issues
- Verify RLS is enabled on tables
- Check if auth.uid() is working correctly
- Test with system role if needed during setup

## Performance Optimization

### For High-Volume Applications

Add partitioning to notifications table (optional):

```sql
-- Convert notifications to time-partitioned table
-- WARNING: This is an advanced operation, back up data first

CREATE TABLE public.notifications_new (
  id UUID NOT NULL DEFAULT gen_random_uuid(),
  member_id UUID NOT NULL,
  session_id UUID,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  event_type TEXT,
  data JSONB DEFAULT '{}',
  is_read BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  delivered_at TIMESTAMP WITH TIME ZONE,
  read_at TIMESTAMP WITH TIME ZONE
) PARTITION BY RANGE (created_at);

-- Create partitions by month
CREATE TABLE notifications_2024_01 PARTITION OF public.notifications_new
  FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

-- Add current month partition and forward...
```

## Monitoring

Set up alerts for notification system health:

```sql
-- Check for stuck/undelivered notifications
SELECT COUNT(*) as undelivered_count 
FROM public.notifications 
WHERE created_at < NOW() - INTERVAL '24 hours' 
AND delivered_at IS NULL;

-- Check for user devices needing refresh
SELECT COUNT(*) as stale_devices 
FROM public.user_devices 
WHERE last_refreshed_at < NOW() - INTERVAL '30 days' 
AND is_active = true;
```

## Next Steps

1. ✅ Run all SQL scripts in order
2. ✅ Verify tables exist and have correct structure
3. ✅ Test with sample data
4. ✅ Enable Row Level Security policies
5. ✅ Set up monitoring queries
6. ✅ Configure backups in Supabase
7. ✅ Ready to integrate with application code

---

**Last Updated**: 2024
**Status**: Ready for production
