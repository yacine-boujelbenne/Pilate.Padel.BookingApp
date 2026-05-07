import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile.dart';
import '../services/supabase_service.dart';

class AuthController extends ChangeNotifier {
  final _client = SupabaseService.instance.client;
  final _passwordRecoveryController = StreamController<void>.broadcast();
  Stream<void> get passwordRecoveryStream => _passwordRecoveryController.stream;

  User? _user;
  Profile? _profile;
  bool _profileLoaded = false;
  bool _loading = false;
  String? _error;

  User? get user => _user;
  Profile? get profile => _profile;
  bool get profileLoaded => _profileLoaded;
  bool get isLoading => _loading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  void listenAuthState() {
    _user = _client.auth.currentUser;
    _client.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      _user = data.session?.user;
      _profileLoaded = false;
      if (event == AuthChangeEvent.passwordRecovery) {
        _passwordRecoveryController.add(null);
      } else {
        if (_user != null) {
          await getCurrentProfile();
        } else {
          _profile = null;
          _profileLoaded = true;
        }
      }
      notifyListeners();
    });
  }

  Future<void> signIn({required String email, required String password}) async {
    _setLoading(true);
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
      _user = _client.auth.currentUser;
      await getCurrentProfile();
      if (_profile?.isBlocked == true) {
        await signOut();
        throw Exception('Your account has been suspended');
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
  }) async {
    _setLoading(true);
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'role': 'member',
          'first_name': firstName,
          'last_name': lastName,
          'phone': phone,
          'member_tier': 'standard',
        },
      );
      final userId = response.user?.id;
      if (userId == null) {
        throw Exception('Unable to create account');
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> createCoachAccount({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String speciality,
  }) async {
    _setLoading(true);
    try {
      final response =
          await _client.functions.invoke('create-coach-account', body: {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'phone': phone,
        'speciality': speciality,
      });
      _error = null;
      final data = response.data;
      if (data is Map && data['temp_password'] is String) {
        return data['temp_password'] as String;
      }
      return null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> getCurrentProfile() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      _profile = null;
      _profileLoaded = true;
      notifyListeners();
      return;
    }
    final data =
        await _client.from('profiles').select().eq('id', uid).maybeSingle();
    if (data == null) {
      final metadata = _client.auth.currentUser?.userMetadata ?? {};
      final role = (metadata['role'] as String?) ?? 'member';
      final firstName = (metadata['first_name'] as String?) ?? 'Member';
      final lastName = (metadata['last_name'] as String?) ?? '';

      await _client.from('profiles').insert({
        'id': uid,
        'role': role,
        'first_name': firstName,
        'last_name': lastName,
        'phone': metadata['phone'] as String?,
        'speciality': metadata['speciality'] as String?,
        'member_tier': (metadata['member_tier'] as String?) ?? 'standard',
      });

      final created =
          await _client.from('profiles').select().eq('id', uid).maybeSingle();
      _profile = created == null ? null : Profile.fromMap(created);
    } else {
      _profile = Profile.fromMap(data);
    }
    _profileLoaded = true;
    notifyListeners();
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    _setLoading(true);
    try {
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo:
            'https://fxpbjztsyucdujwgrhji.supabase.co/functions/v1/auth-redirect',
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updatePassword({required String newPassword}) async {
    _setLoading(true);
    try {
      await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    _user = null;
    _profile = null;
    _profileLoaded = true;
    notifyListeners();
  }

  Future<void> updateProfileNames({
    required String firstName,
    required String lastName,
  }) async {
    _setLoading(true);
    try {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) {
        throw Exception('Not authenticated');
      }

      await _client.from('profiles').update({
        'first_name': firstName,
        'last_name': lastName,
      }).eq('id', uid);

      await _client.auth.updateUser(UserAttributes(data: {
        'first_name': firstName,
        'last_name': lastName,
      }));

      await getCurrentProfile();
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}
