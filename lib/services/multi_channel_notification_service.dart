import 'package:flutter/foundation.dart';

import '../models/notification_model.dart';
import 'in_app_notification_service.dart';
import 'push_notification_service.dart';
import 'supabase_service.dart';

/// Comprehensive multi-channel notification service
/// Supports Email, In-App, and Push notifications with preference checking
class MultiChannelNotificationService {
  static final MultiChannelNotificationService _instance =
      MultiChannelNotificationService._();

  factory MultiChannelNotificationService() => _instance;

  MultiChannelNotificationService._();

  final _client = SupabaseService.instance.client;
  final _inAppService = InAppNotificationService();
  final _pushService = PushNotificationService();

  bool _initialized = false;

  /// Initialize all notification channels
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    try {
      if (kDebugMode) {
        debugPrint('Initializing MultiChannelNotificationService...');
      }

      // Initialize push notification service
      await _pushService.initialize();

      _initialized = true;

      if (kDebugMode) {
        debugPrint('MultiChannelNotificationService initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error initializing notification service: $e');
      }
      rethrow;
    }
  }

  /// Fetch user notification preferences
  /// Returns default preferences if not found
  Future<NotificationPreferences> getUserPreferences(String userId) async {
    try {
      final response = await _client
          .from('notification_preferences')
          .select()
          .eq('member_id', userId)
          .maybeSingle();

      if (response != null) {
        return NotificationPreferences.fromMap(response);
      }

      // Return default preferences if not found
      return NotificationPreferences(
        memberId: userId,
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching user preferences: $e');
      }

      // Return default preferences on error
      return NotificationPreferences(
        memberId: userId,
        updatedAt: DateTime.now(),
      );
    }
  }

  /// Save user notification preferences
  Future<void> saveUserPreferences(NotificationPreferences preferences) async {
    try {
      await _client
          .from('notification_preferences')
          .upsert(preferences.toMap(), onConflict: 'member_id');

      if (kDebugMode) {
        debugPrint(
            'Notification preferences saved for ${preferences.memberId}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error saving notification preferences: $e');
      }
      rethrow;
    }
  }

  /// Main method to send notifications across multiple channels
  /// Checks user preferences before sending
  Future<void> sendNotification({
    required String title,
    required String body,
    required NotificationEvent eventType,
    String? sessionId,
    Map<String, dynamic>? data,
    List<NotificationChannel>? channels,
    List<String>? recipientIds,
    List<String>? recipientRoles,
  }) async {
    try {
      if ((recipientIds == null || recipientIds.isEmpty) &&
          (recipientRoles == null || recipientRoles.isEmpty)) {
        if (kDebugMode) {
          debugPrint('No recipients specified for notification');
        }
        return;
      }

      // Resolve recipient IDs from roles if needed
      final finalRecipientIds = await _resolveRecipientIds(
        recipientIds: recipientIds,
        recipientRoles: recipientRoles,
      );

      if (finalRecipientIds.isEmpty) {
        if (kDebugMode) {
          debugPrint('No recipients resolved for notification');
        }
        return;
      }

      // Determine channels to use
      final channelsToUse = channels ??
          [
            NotificationChannel.IN_APP,
            NotificationChannel.PUSH,
            NotificationChannel.EMAIL,
          ];

      // Send to each recipient
      for (final recipientId in finalRecipientIds) {
        await _sendToRecipient(
          recipientId: recipientId,
          title: title,
          body: body,
          eventType: eventType,
          sessionId: sessionId,
          data: data ?? {},
          channels: channelsToUse,
        );
      }

      if (kDebugMode) {
        debugPrint(
            'Notification sent to ${finalRecipientIds.length} recipients');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error sending notification: $e');
      }
      rethrow;
    }
  }

  /// Send notification for a new session created by coach
  /// Notifies followers of the coach
  Future<void> notifySessionCreated({
    required String sessionId,
    required String sessionTitle,
    required String coachId,
    required List<String> coachFollowerIds,
  }) async {
    try {
      final data = {
        'session_id': sessionId,
        'coach_id': coachId,
        'action': 'view_session',
      };

      await sendNotification(
        title: 'New Session Available',
        body: '$sessionTitle is now available for booking!',
        eventType: NotificationEvent.COACH_SESSION_CREATED,
        sessionId: sessionId,
        data: data,
        recipientIds: coachFollowerIds,
      );

      if (kDebugMode) {
        debugPrint(
            'Session created notification sent for session $sessionId to ${coachFollowerIds.length} followers');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error notifying session created: $e');
      }
      rethrow;
    }
  }

  /// Send notification when a spot becomes available in a session
  /// Notifies users on the waitlist
  Future<void> notifySpotAvailable({
    required String sessionId,
    required String sessionTitle,
    required List<String> waitlistMemberIds,
  }) async {
    try {
      final data = {
        'session_id': sessionId,
        'action': 'book_session',
      };

      await sendNotification(
        title: 'Spot Available!',
        body: 'A spot is now available in $sessionTitle',
        eventType: NotificationEvent.SESSION_SPOT_AVAILABLE,
        sessionId: sessionId,
        data: data,
        recipientIds: waitlistMemberIds,
      );

      if (kDebugMode) {
        debugPrint(
            'Spot available notification sent for session $sessionId to ${waitlistMemberIds.length} waitlist members');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error notifying spot available: $e');
      }
      rethrow;
    }
  }

  /// Send notification for waitlist availability
  /// Sent when user is moved from waitlist to bookable
  Future<void> notifyWaitlistAvailable({
    required String sessionId,
    required String sessionTitle,
    required String userId,
  }) async {
    try {
      final data = {
        'session_id': sessionId,
        'action': 'view_waitlist_status',
      };

      await sendNotification(
        title: 'Waitlist Updated',
        body: 'Your waitlist position for $sessionTitle has changed',
        eventType: NotificationEvent.WAITLIST_AVAILABLE,
        sessionId: sessionId,
        data: data,
        recipientIds: [userId],
      );

      if (kDebugMode) {
        debugPrint('Waitlist notification sent for session $sessionId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error notifying waitlist available: $e');
      }
      rethrow;
    }
  }

  /// Send notification when a session is cancelled
  /// Notifies all confirmed bookings
  Future<void> notifySessionCancelled({
    required String sessionId,
    required String sessionTitle,
    required List<String> bookedMemberIds,
  }) async {
    try {
      final data = {
        'session_id': sessionId,
        'action': 'check_refund_status',
      };

      await sendNotification(
        title: 'Session Cancelled',
        body:
            '$sessionTitle has been cancelled. Your payment will be refunded.',
        eventType: NotificationEvent.SESSION_CANCELLED,
        sessionId: sessionId,
        data: data,
        recipientIds: bookedMemberIds,
      );

      if (kDebugMode) {
        debugPrint(
            'Session cancelled notification sent for session $sessionId to ${bookedMemberIds.length} members');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error notifying session cancelled: $e');
      }
      rethrow;
    }
  }

  /// Send booking confirmation notification
  Future<void> notifyBookingConfirmed({
    required String bookingId,
    required String sessionTitle,
    required String userId,
    required double amount,
  }) async {
    try {
      final data = {
        'booking_id': bookingId,
        'amount': amount.toString(),
        'action': 'view_booking',
      };

      await sendNotification(
        title: 'Booking Confirmed',
        body: 'Your booking for $sessionTitle is confirmed!',
        eventType: NotificationEvent.BOOKING_CONFIRMED,
        data: data,
        recipientIds: [userId],
      );

      if (kDebugMode) {
        debugPrint(
            'Booking confirmation notification sent for booking $bookingId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error notifying booking confirmed: $e');
      }
      rethrow;
    }
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _inAppService.markAsRead(notificationId);

      if (kDebugMode) {
        debugPrint('Notification marked as read: $notificationId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error marking notification as read: $e');
      }
      rethrow;
    }
  }

  /// Get notifications for a user with pagination
  Future<List<NotificationData>> getNotifications(
    String userId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      return await _inAppService.getNotifications(
        userId,
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching notifications: $e');
      }
      return [];
    }
  }

  /// Get unread notifications for a user
  Future<List<NotificationData>> getUnreadNotifications(String userId) async {
    try {
      return await _inAppService.getUnreadNotifications(userId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching unread notifications: $e');
      }
      return [];
    }
  }

  /// Get unread notification count for a user
  Future<int> getUnreadCount(String userId) async {
    try {
      return await _inAppService.getUnreadCount(userId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting unread count: $e');
      }
      return 0;
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _inAppService.deleteNotification(notificationId);

      if (kDebugMode) {
        debugPrint('Notification deleted: $notificationId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting notification: $e');
      }
      rethrow;
    }
  }

  /// Private helper: Send to individual recipient
  Future<void> _sendToRecipient({
    required String recipientId,
    required String title,
    required String body,
    required NotificationEvent eventType,
    String? sessionId,
    required Map<String, dynamic> data,
    required List<NotificationChannel> channels,
  }) async {
    try {
      // Get user preferences
      final preferences = await getUserPreferences(recipientId);

      // Send through each channel based on preferences
      for (final channel in channels) {
        if (channel == NotificationChannel.IN_APP && preferences.inAppEnabled) {
          await _inAppService.createInAppNotification(
            memberId: recipientId,
            title: title,
            body: body,
            sessionId: sessionId,
            eventType: eventType,
            data: data,
          );
        } else if (channel == NotificationChannel.EMAIL &&
            preferences.emailEnabled) {
          // TODO: Integrate with email service (Mailtrap, SendGrid, etc.)
          if (kDebugMode) {
            debugPrint(
                'Email notification would be sent to $recipientId (email service integration pending)');
          }
        } else if (channel == NotificationChannel.PUSH &&
            preferences.pushEnabled) {
          // Get user device tokens
          await _sendPushToUser(recipientId, title, body, data);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error sending notification to recipient $recipientId: $e');
      }
    }
  }

  /// Private helper: Send push notification to user's devices
  Future<void> _sendPushToUser(
    String userId,
    String title,
    String body,
    Map<String, dynamic> data,
  ) async {
    try {
      // Fetch user's active devices
      final devices = await _client
          .from('user_devices')
          .select('device_token')
          .eq('user_id', userId)
          .eq('is_active', true);

      if (devices.isNotEmpty) {
        final tokens =
            devices.map((device) => device['device_token'] as String).toList();

        await _pushService.sendPushNotificationsToMultiple(
          tokens: tokens,
          title: title,
          body: body,
          data: data,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error sending push notification to user: $e');
      }
    }
  }

  /// Private helper: Resolve recipient IDs from roles
  Future<List<String>> _resolveRecipientIds({
    List<String>? recipientIds,
    List<String>? recipientRoles,
  }) async {
    final resolved = <String>{};

    // Add direct recipient IDs
    if (recipientIds != null) {
      resolved.addAll(recipientIds);
    }

    // Resolve roles to member IDs
    if (recipientRoles != null && recipientRoles.isNotEmpty) {
      for (final role in recipientRoles) {
        try {
          final members =
              await _client.from('profiles').select('id').eq('role', role);

          for (final member in members) {
            final id = member['id'] as String?;
            if (id != null) {
              resolved.add(id);
            }
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Error resolving role $role: $e');
          }
        }
      }
    }

    return resolved.toList();
  }

  /// Check if service is initialized
  bool get isInitialized => _initialized;
}
