import 'package:flutter/material.dart';

import '../models/notification_model.dart';
import '../services/in_app_notification_service.dart';
import '../services/multi_channel_notification_service.dart';
import '../services/supabase_service.dart';

/// State management controller for notifications using Provider pattern
/// Manages notification list, unread count, and real-time updates
class NotificationController extends ChangeNotifier {
  final _client = SupabaseService.instance.client;
  final _notificationService = MultiChannelNotificationService();
  final _inAppService = InAppNotificationService();

  // State variables
  List<NotificationData> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;
  String? _currentUserId;

  // Getters
  List<NotificationData> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Initialize controller for a specific user
  Future<void> initialize(String userId) async {
    try {
      _currentUserId = userId;
      _setLoading(true);

      // Initialize notification service
      await _notificationService.initialize();

      // Load initial notifications
      await fetchNotifications();

      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch all notifications for current user
  Future<void> fetchNotifications({int limit = 50, int offset = 0}) async {
    if (_currentUserId == null) {
      return;
    }

    try {
      _setLoading(true);

      _notifications = await _notificationService.getNotifications(
        _currentUserId!,
        limit: limit,
        offset: offset,
      );

      await _updateUnreadCount();
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch unread notifications only
  Future<void> fetchUnreadNotifications() async {
    if (_currentUserId == null) {
      return;
    }

    try {
      _setLoading(true);

      _notifications = await _notificationService.getUnreadNotifications(
        _currentUserId!,
      );

      await _updateUnreadCount();
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Mark a single notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      // Update local state immediately
      _notifications = _notifications.map((n) {
        if (n.id == notificationId) {
          return n.copyWith(
            isRead: true,
            readAt: DateTime.now(),
          );
        }
        return n;
      }).toList();

      // Update in database
      await _notificationService.markAsRead(notificationId);

      await _updateUnreadCount();
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Mark all unread notifications as read
  Future<void> markAllAsRead() async {
    if (_currentUserId == null) {
      return;
    }

    try {
      final unreadIds =
          _notifications.where((n) => !n.isRead).map((n) => n.id).toList();

      if (unreadIds.isEmpty) {
        return;
      }

      // Update local state immediately
      _notifications = _notifications.map((n) {
        if (unreadIds.contains(n.id)) {
          return n.copyWith(
            isRead: true,
            readAt: DateTime.now(),
          );
        }
        return n;
      }).toList();

      // Update in database
      await _inAppService.markMultipleAsRead(unreadIds);

      _unreadCount = 0;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      // Remove from local state immediately
      _notifications =
          _notifications.where((n) => n.id != notificationId).toList();

      // Delete from database
      await _notificationService.deleteNotification(notificationId);

      await _updateUnreadCount();
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Delete all read notifications
  Future<void> deleteAllReadNotifications() async {
    if (_currentUserId == null) {
      return;
    }

    try {
      // Remove read notifications from local state
      _notifications = _notifications.where((n) => !n.isRead).toList();

      // Delete from database
      await _inAppService.deleteReadNotificationsForUser(_currentUserId!);

      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Get notifications of a specific event type
  List<NotificationData> getNotificationsByEventType(
      NotificationEvent eventType) {
    return _notifications.where((n) => n.eventType == eventType).toList();
  }

  /// Get unread notifications count by event type
  int getUnreadCountByEventType(NotificationEvent eventType) {
    return _notifications
        .where((n) => n.eventType == eventType && !n.isRead)
        .length;
  }

  /// Search notifications by title or body
  List<NotificationData> searchNotifications(String query) {
    final lowerQuery = query.toLowerCase();
    return _notifications
        .where((n) =>
            n.title.toLowerCase().contains(lowerQuery) ||
            n.body.toLowerCase().contains(lowerQuery))
        .toList();
  }

  /// Filter notifications by date range
  List<NotificationData> filterByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _notifications
        .where((n) =>
            n.createdAt.isAfter(startDate) && n.createdAt.isBefore(endDate))
        .toList();
  }

  /// Filter unread notifications only
  List<NotificationData> getUnreadNotifications() {
    return _notifications.where((n) => !n.isRead).toList();
  }

  /// Clear all notifications (both local and from database)
  Future<void> clearAllNotifications() async {
    if (_currentUserId == null) {
      return;
    }

    try {
      _notifications = [];
      _unreadCount = 0;

      await _inAppService.deleteAllNotificationsForUser(_currentUserId!);

      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Refresh notifications from server
  Future<void> refreshNotifications() async {
    await fetchNotifications();
  }

  /// Update user notification preferences
  Future<void> updateNotificationPreferences(
      NotificationPreferences preferences) async {
    try {
      await _notificationService.saveUserPreferences(preferences);

      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Get user notification preferences
  Future<NotificationPreferences> getUserPreferences(String userId) async {
    return await _notificationService.getUserPreferences(userId);
  }

  // Private helpers

  /// Update unread count
  Future<void> _updateUnreadCount() async {
    if (_currentUserId == null) {
      return;
    }

    _unreadCount = await _notificationService.getUnreadCount(_currentUserId!);
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
  }

  /// Clear controller state
  @override
  void dispose() {
    _notifications = [];
    _unreadCount = 0;
    _isLoading = false;
    _error = null;
    _currentUserId = null;
    super.dispose();
  }
}
