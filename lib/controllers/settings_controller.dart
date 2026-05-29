import 'package:flutter/material.dart';

import '../services/notification_service.dart';
import '../services/supabase_service.dart';

class SettingsController extends ChangeNotifier {
  final _client = SupabaseService.instance.client;

  bool _loading = false;
  String? _error;
  bool _pushEnabled = true;
  bool _emailEnabled = true;
  bool _smsEnabled = false;
  bool _remindersEnabled = true;

  bool get isLoading => _loading;
  String? get error => _error;
  bool get pushEnabled => _pushEnabled;
  bool get emailEnabled => _emailEnabled;
  bool get smsEnabled => _smsEnabled;
  bool get remindersEnabled => _remindersEnabled;

  Future<void> loadSettings() async {
    _setLoading(true);
    try {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) {
        throw Exception('Not authenticated');
      }

        final res = await _client
          .from('user_settings')
          .select()
          .eq('user_id', uid)
          .maybeSingle();

      if (res == null) {
        await _client.from('user_settings').insert({'user_id': uid});
        _pushEnabled = true;
        _emailEnabled = true;
        _smsEnabled = false;
        _remindersEnabled = true;
      } else {
        _pushEnabled = (res['push_enabled'] as bool?) ?? true;
        _emailEnabled = (res['email_enabled'] as bool?) ?? true;
        _smsEnabled = (res['sms_enabled'] as bool?) ?? false;
        _remindersEnabled = (res['reminders_enabled'] as bool?) ?? true;
      }

      await NotificationService.instance.setRemindersEnabled(_remindersEnabled);

      _error = null;
    } catch (e) {
      // Some environments may be missing the user_settings table.
      // Keep app behavior functional with defaults instead of hard-failing.
      if (_isMissingUserSettingsTableError(e)) {
        _pushEnabled = true;
        _emailEnabled = true;
        _smsEnabled = false;
        _remindersEnabled = true;
        await NotificationService.instance.setRemindersEnabled(_remindersEnabled);
        _error = null;
      } else {
        _error = e.toString();
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateSettings({
    bool? pushEnabled,
    bool? emailEnabled,
    bool? smsEnabled,
    bool? remindersEnabled,
  }) async {
    _setLoading(true);
    try {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) {
        throw Exception('Not authenticated');
      }

      _pushEnabled = pushEnabled ?? _pushEnabled;
      _emailEnabled = emailEnabled ?? _emailEnabled;
      _smsEnabled = smsEnabled ?? _smsEnabled;
      _remindersEnabled = remindersEnabled ?? _remindersEnabled;

      if (pushEnabled != null) {
        await NotificationService.instance.setPushEnabled(_pushEnabled);
      }

      if (remindersEnabled != null) {
        await NotificationService.instance.setRemindersEnabled(_remindersEnabled);
      }

      try {
        await _client.from('user_settings').upsert({
          'user_id': uid,
          'push_enabled': _pushEnabled,
          'email_enabled': _emailEnabled,
          'sms_enabled': _smsEnabled,
          'reminders_enabled': _remindersEnabled,
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'user_id');
      } catch (e) {
        if (!_isMissingUserSettingsTableError(e)) {
          rethrow;
        }
      }

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  bool _isMissingUserSettingsTableError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('public.user_settings') &&
        (message.contains('pgrst205') ||
            message.contains('does not exist') ||
            message.contains('schema cache'));
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}
