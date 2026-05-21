import 'package:flutter/foundation.dart';

import '../models/notification_model.dart';
import 'supabase_service.dart';

/// Service for managing in-app notifications stored in Supabase
class InAppNotificationService {
  static final InAppNotificationService _instance =
      InAppNotificationService._();

  factory InAppNotificationService() => _instance;

  InAppNotificationService._();

  final _client = SupabaseService.instance.client;

  /// Creates an in-app notification record in Supabase
  /// This notification will be displayed to users when they open the app
  Future<String?> createInAppNotification({
    required String memberId,
    required String title,
    required String body,
    String? sessionId,
    required NotificationEvent eventType,
    Map<String, dynamic>? data,
  }) async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();

      final response = await _client.from('notifications').insert({
        'member_id': memberId,
        'session_id': sessionId,
        'title': title,
        'body': body,
        'event_type': eventType.toString().split('.').last,
        'data': data ?? {},
        'is_read': false,
        'created_at': now,
        'delivered_at': now,
      }).select();

      if (response is List && response.isNotEmpty) {
        final notificationId = response[0]['id'];
        if (kDebugMode) {
          debugPrint(
              'In-app notification created: $notificationId for member $memberId');
        }
        return notificationId;
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error creating in-app notification: $e');
      }
      rethrow;
    }
  }

  /// Fetches all unread notifications for a user
  Future<List<NotificationData>> getUnreadNotifications(String userId) async {
    try {
      final response = await _client
          .from('notifications')
          .select()
          .eq('member_id', userId)
          .eq('is_read', false)
          .order('created_at', ascending: false);

      if (response is List) {
        return response
            .map((notification) =>
                NotificationData.fromMap(notification as Map<String, dynamic>))
            .toList();
      }

      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching unread notifications: $e');
      }
      return [];
    }
  }

  /// Gets the count of unread notifications for a user
  Future<int> getUnreadCount(String userId) async {
    try {
      final response = await _client
          .from('notifications')
          .select('id')
          .eq('member_id', userId)
          .eq('is_read', false);

      if (response is List) {
        return response.length;
      }

      return 0;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting unread notification count: $e');
      }
      return 0;
    }
  }

  /// Marks a notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();

      await _client.from('notifications').update({
        'is_read': true,
        'read_at': now,
      }).eq('id', notificationId);

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

  /// Marks multiple notifications as read
  Future<void> markMultipleAsRead(List<String> notificationIds) async {
    try {
      if (notificationIds.isEmpty) {
        return;
      }

      final now = DateTime.now().toUtc().toIso8601String();

      await _client
          .from('notifications')
          .update({
            'is_read': true,
            'read_at': now,
          })
          .inFilter('id', notificationIds);

      if (kDebugMode) {
        debugPrint('${notificationIds.length} notifications marked as read');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error marking multiple notifications as read: $e');
      }
      rethrow;
    }
  }

  /// Fetches all notifications for a user with pagination
  Future<List<NotificationData>> getNotifications(
    String userId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _client
          .from('notifications')
          .select()
          .eq('member_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      if (response is List) {
        return response
            .map((notification) =>
                NotificationData.fromMap(notification as Map<String, dynamic>))
            .toList();
      }

      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching notifications: $e');
      }
      return [];
    }
  }

  /// Deletes a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _client.from('notifications').delete().eq('id', notificationId);

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

  /// Deletes all notifications for a user
  Future<void> deleteAllNotificationsForUser(String userId) async {
    try {
      await _client.from('notifications').delete().eq('member_id', userId);

      if (kDebugMode) {
        debugPrint('All notifications deleted for user: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting all notifications: $e');
      }
      rethrow;
    }
  }

  /// Deletes all read notifications for a user
  Future<void> deleteReadNotificationsForUser(String userId) async {
    try {
      await _client
          .from('notifications')
          .delete()
          .eq('member_id', userId)
          .eq('is_read', true);

      if (kDebugMode) {
        debugPrint('All read notifications deleted for user: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting read notifications: $e');
      }
      rethrow;
    }
  }
}
