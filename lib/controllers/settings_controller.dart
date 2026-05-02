import 'package:flutter/material.dart';

import '../services/supabase_service.dart';

class SettingsController extends ChangeNotifier {
  final _client = SupabaseService.instance.client;

  bool _loading = false;
  String? _error;
  bool _pushEnabled = true;
  bool _emailEnabled = true;
  bool _smsEnabled = false;

  bool get isLoading => _loading;
  String? get error => _error;
  bool get pushEnabled => _pushEnabled;
  bool get emailEnabled => _emailEnabled;
  bool get smsEnabled => _smsEnabled;

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
      } else {
        _pushEnabled = (res['push_enabled'] as bool?) ?? true;
        _emailEnabled = (res['email_enabled'] as bool?) ?? true;
        _smsEnabled = (res['sms_enabled'] as bool?) ?? false;
      }

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateSettings({
    bool? pushEnabled,
    bool? emailEnabled,
    bool? smsEnabled,
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

      await _client.from('user_settings').upsert({
        'user_id': uid,
        'push_enabled': _pushEnabled,
        'email_enabled': _emailEnabled,
        'sms_enabled': _smsEnabled,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}
