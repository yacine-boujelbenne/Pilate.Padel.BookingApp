import 'package:flutter/foundation.dart';

import 'supabase_service.dart';

class SessionNotificationService {
  static final SessionNotificationService _instance =
      SessionNotificationService._();

  factory SessionNotificationService() => _instance;

  SessionNotificationService._();

  final _client = SupabaseService.instance.client;

  /// Notify all members enrolled in a session that it has been cancelled.
  /// Fetches all confirmed bookings for the session and creates notification records.
  Future<void> notifySessionCancelled({
    required String sessionId,
    required String sessionTitle,
  }) async {
    try {
      // Fetch all confirmed bookings for this session
      final bookingsRes = await _client
          .from('bookings')
          .select('member_id')
          .eq('session_id', sessionId)
          .eq('status', 'confirmed');

      final bookingsList = bookingsRes as List? ?? [];
      if (bookingsList.isEmpty) {
        if (kDebugMode) {
          debugPrint('No members to notify for cancelled session $sessionId');
        }
        return;
      }

      // Extract unique member IDs
      final memberIds = <String>{};
      for (final booking in bookingsList) {
        final memberId = booking['member_id'];
        if (memberId != null) {
          memberIds.add(memberId as String);
        }
      }

      if (memberIds.isEmpty) {
        if (kDebugMode) {
          debugPrint('No members found for cancelled session $sessionId');
        }
        return;
      }

      // Create notification records for each member
      final notifications = memberIds.map((memberId) {
        return {
          'member_id': memberId,
          'session_id': sessionId,
          'title': 'Session Cancelled',
          'body':
              '$sessionTitle has been cancelled. Your payment will be refunded.',
          'is_read': false,
        };
      }).toList();

      await _client.from('notifications').insert(notifications);

      if (kDebugMode) {
        debugPrint(
            'Session $sessionId cancelled: notified ${memberIds.length} members');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error notifying members of cancelled session: $e');
      }
      rethrow;
    }
  }

  /// Fetch notifications for the current user
  Future<List<Map<String, dynamic>>> fetchUserNotifications(
      String userId) async {
    try {
      final res = await _client
          .from('notifications')
          .select()
          .eq('member_id', userId)
          .order('created_at', ascending: false);

      return (res as List).cast<Map<String, dynamic>>();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching notifications: $e');
      }
      return [];
    }
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _client
          .from('notifications')
          .update({'is_read': true}).eq('id', notificationId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error marking notification as read: $e');
      }
      rethrow;
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _client.from('notifications').delete().eq('id', notificationId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting notification: $e');
      }
      rethrow;
    }
  }
}
