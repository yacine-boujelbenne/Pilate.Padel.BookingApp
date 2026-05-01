import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/session_model.dart';
import '../services/supabase_service.dart';

class SessionController extends ChangeNotifier {
  final _client = SupabaseService.instance.client;

  bool _loading = false;
  String? _error;
  List<SessionModel> _sessions = [];

  bool get isLoading => _loading;
  String? get error => _error;
  List<SessionModel> get sessions => _sessions;

  Future<void> fetchSessionsByDate(DateTime date) async {
    _setLoading(true);
    try {
      final dayStart = DateFormat('yyyy-MM-dd').format(date);
      final dayEnd =
          DateFormat('yyyy-MM-dd').format(date.add(const Duration(days: 1)));
      final res = await _client
          .from('sessions')
          .select()
          .eq('status', 'scheduled')
          .gte('start_at', dayStart)
          .lt('start_at', dayEnd)
          .order('start_at');
      _sessions = (res as List)
          .map((e) => SessionModel.fromMap(e as Map<String, dynamic>))
          .toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchAllSessions() async {
    _setLoading(true);
    try {
      final res = await _client.from('sessions').select().order('start_at');
      _sessions = (res as List)
          .map((e) => SessionModel.fromMap(e as Map<String, dynamic>))
          .toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createSession(Map<String, dynamic> payload) async {
    _setLoading(true);
    try {
      await _client.from('sessions').insert(payload);
      _error = null;
      await fetchAllSessions();
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> updateSession(String id, Map<String, dynamic> payload) async {
    _setLoading(true);
    try {
      await _client.from('sessions').update(payload).eq('id', id);
      _error = null;
      await fetchAllSessions();
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> cancelSession(String id) async {
    await updateSession(id, {'status': 'cancelled'});
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}
