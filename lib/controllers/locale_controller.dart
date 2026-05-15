import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/supabase_service.dart';

class LocaleController extends ChangeNotifier {
  final _client = SupabaseService.instance.client;
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  Future<void> loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString('locale_code');

    if (savedCode != null) {
      _locale = Locale(savedCode);
      notifyListeners();
      return;
    }

    final uid = _client.auth.currentUser?.id;
    if (uid != null) {
      try {
        final res = await _client
            .from('user_settings')
            .select('language')
            .eq('user_id', uid)
            .maybeSingle();

        if (res != null && res['language'] != null) {
          _locale = Locale(res['language'] as String);
          notifyListeners();
        }
      } catch (_) {}
    }

    final deviceLocale = Locale(WidgetsBinding.instance.platformDispatcher.locale.languageCode);
    if (['en', 'fr'].contains(deviceLocale.languageCode)) {
      _locale = deviceLocale;
      notifyListeners();
    }
  }

  Future<void> setLocale(String languageCode) async {
    _locale = Locale(languageCode);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale_code', languageCode);

    final uid = _client.auth.currentUser?.id;
    if (uid != null) {
      try {
        await _client.from('user_settings').upsert({
          'user_id': uid,
          'language': languageCode,
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'user_id');
      } catch (_) {}
    }
  }

  String get currentLanguageCode => _locale.languageCode;
}