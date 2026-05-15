import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const _installationIdKey = 'push.installation_id';
  static const _androidChannelId = 'push_notifications';
  static const _androidChannelName = 'Push notifications';
  static const _androidChannelDescription =
      'Transactional and realtime notification alerts';

  final SupabaseClient _client = SupabaseService.instance.client;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  StreamSubscription<AuthState>? _authSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _realtimeSubscription;
  final Set<String> _seenNotificationIds = <String>{};

  bool _initialized = false;
  String? _activeUserId;
  String? _currentToken;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;

    await _configureLocalNotifications();

    if (!kIsWeb) {
      try {
        await _messaging.requestPermission(
            alert: true, badge: true, sound: true);
        await _messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      } catch (_) {
        // Push permissions are best-effort during local development.
      }
    }

    _authSubscription = _client.auth.onAuthStateChange.listen((state) async {
      final userId = state.session?.user.id;
      if (userId == null) {
        await _handleSignedOut();
      } else {
        await _handleSignedIn(userId);
      }
    });

    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId != null) {
      await _handleSignedIn(currentUserId);
    }
  }

  Future<void> setPushEnabled(bool enabled) async {
    if (enabled) {
      final userId = _client.auth.currentUser?.id;
      if (userId != null) {
        await _registerCurrentDevice(userId);
      }
      return;
    }

    await _deactivateCurrentDevice();
  }

  Future<void> _handleSignedIn(String userId) async {
    if (_activeUserId == userId) {
      return;
    }

    _activeUserId = userId;
    await _registerCurrentDevice(userId);
    await _subscribeToRealtimeNotifications(userId);

    if (!kIsWeb) {
      await _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription =
          _messaging.onTokenRefresh.listen((token) async {
        _currentToken = token;
        await _upsertDeviceToken(userId, token);
      });
    }
  }

  Future<void> _handleSignedOut() async {
    _activeUserId = null;
    _seenNotificationIds.clear();
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
    await _clearRealtimeSubscription();
    await _deactivateCurrentDevice();
  }

  Future<void> _registerCurrentDevice(String userId) async {
    if (kIsWeb) {
      await _subscribeToRealtimeNotifications(userId);
      return;
    }

    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return;
      }

      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) {
        return;
      }

      _currentToken = token;
      await _upsertDeviceToken(userId, token);
    } catch (_) {
      // Token registration is optional on simulators and local dev builds.
    }
  }

  Future<void> _upsertDeviceToken(String userId, String token) async {
    final prefs = await SharedPreferences.getInstance();
    final installationId = await _getOrCreateInstallationId(prefs);
    final platform = _platformLabel();
    final now = DateTime.now().toUtc().toIso8601String();

    await _client.from('user_devices').upsert({
      'installation_id': installationId,
      'user_id': userId,
      'platform': platform,
      'push_provider': 'fcm',
      'device_token': token,
      'is_active': true,
      'last_seen_at': now,
      'last_refreshed_at': now,
      'updated_at': now,
    }, onConflict: 'installation_id');
  }

  Future<void> _deactivateCurrentDevice() async {
    if (kIsWeb) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final installationId = prefs.getString(_installationIdKey);
    if (installationId == null || installationId.isEmpty) {
      return;
    }

    try {
      await _client.from('user_devices').update({
        'is_active': false,
        'deactivated_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('installation_id', installationId);
    } catch (_) {
      // If the row does not exist yet, there is nothing to clean up.
    }
  }

  Future<void> _subscribeToRealtimeNotifications(String userId) async {
    await _clearRealtimeSubscription();

    try {
      final existing = await _client
          .from('notifications')
          .select('id')
          .eq('member_id', userId)
          .order('created_at', ascending: false)
          .limit(100);

      for (final row in (existing as List<dynamic>)) {
        final id = row['id']?.toString();
        if (id != null) {
          _seenNotificationIds.add(id);
        }
      }

      _realtimeSubscription = _client
          .from('notifications')
          .stream(primaryKey: ['id'])
          .eq('member_id', userId)
          .listen((rows) async {
            for (final row in rows) {
              final notificationId = row['id']?.toString();
              if (notificationId == null ||
                  !_seenNotificationIds.add(notificationId)) {
                continue;
              }

              await _showLocalNotification(
                title: row['title']?.toString() ?? 'Notification',
                body: row['body']?.toString() ?? '',
                payload: row,
              );
            }
          });
    } catch (_) {
      // Realtime is best-effort and can be unavailable during first-run setup.
    }
  }

  Future<void> _clearRealtimeSubscription() async {
    await _realtimeSubscription?.cancel();
    _realtimeSubscription = null;
  }

  Future<void> _configureLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    await _localNotificationsPlugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    required Map<String, dynamic> payload,
  }) async {
    final notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        _androidChannelId,
        _androidChannelName,
        channelDescription: _androidChannelDescription,
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _localNotificationsPlugin.show(
      _nextNotificationId(),
      title,
      body,
      notificationDetails,
      payload: jsonEncode(payload),
    );
  }

  int _nextNotificationId() {
    return DateTime.now().millisecondsSinceEpoch % 2147483647;
  }

  Future<String> _getOrCreateInstallationId(SharedPreferences prefs) async {
    final existing = prefs.getString(_installationIdKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final created = _generateInstallationId();
    await prefs.setString(_installationIdKey, created);
    return created;
  }

  String _generateInstallationId() {
    final random = Random.secure();
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final nonce = random.nextInt(1 << 32);
    return '$timestamp-$nonce';
  }

  String _platformLabel() {
    if (kIsWeb) {
      return 'web';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'ios';
      case TargetPlatform.linux:
        return 'android';
      case TargetPlatform.windows:
        return 'android';
      case TargetPlatform.fuchsia:
        return 'android';
    }
  }
}
