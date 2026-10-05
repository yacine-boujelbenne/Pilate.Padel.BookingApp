import 'package:flutter/material.dart';

import '../models/session_model.dart';
import '../services/supabase_service.dart';

class SessionController extends ChangeNotifier {
  final _client = SupabaseService.instance.client;

  int _fetchGeneration = 0;
  bool _disposed = false;
  DateTime? loadedDate;
  bool _loading = false;
  String? _error;
  List<SessionModel> _sessions = [];
  List<Map<String, dynamic>> _editRequests = [];

  bool get isLoading => _loading;
  String? get error => _error;
  List<SessionModel> get sessions => _sessions;
  List<Map<String, dynamic>> get editRequests => _editRequests;

  Future<void> fetchSessionsByDate(DateTime date) async {
    final generation = ++_fetchGeneration;
    _setLoading(true);
    try {
      final localStart = DateTime(date.year, date.month, date.day);
      final localEnd = DateTime(date.year, date.month, date.day + 1);
      final res = await _client
          .from('sessions')
          .select('*, profiles!coach_id(first_name,last_name), studios(name)')
          .eq('status', 'scheduled')
          .gte('start_at', localStart.toUtc().toIso8601String())
          .lt('start_at', localEnd.toUtc().toIso8601String())
          .order('start_at');
      if (generation != _fetchGeneration) return;
      _sessions = res.map((row) => SessionModel.fromMap(row)).toList();
      loadedDate = date;
      _error = null;
    } catch (e) {
      if (generation == _fetchGeneration) _error = e.toString();
    } finally {
      if (generation == _fetchGeneration) _setLoading(false);
    }
  }

  Future<void> fetchAllSessions() async {
    _setLoading(true);
    try {
      final res = await _client
          .from('sessions')
          .select('*, profiles!coach_id(first_name,last_name), studios(name)')
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

  Future<void> fetchPendingEditRequests() async {
    _setLoading(true);
    try {
      final res = await _client
          .from('session_edit_requests')
          .select()
          .order('created_at', ascending: false);

      // Filter for pending status with case-insensitive comparison
      _editRequests = (res as List)
          .where(
            (e) =>
                (e as Map<String, dynamic>)['status']
                    .toString()
                    .toLowerCase()
                    .trim() ==
                'pending',
          )
          .cast<Map<String, dynamic>>()
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
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> proposeSessionEdit({
    required String sessionId,
    required String coachId,
    required Map<String, dynamic> changes,
  }) async {
    _setLoading(true);
    try {
      await _client.from('session_edit_requests').insert({
        'session_id': sessionId,
        'coach_id': coachId,
        ...changes,
      });
      _error = null;
      await fetchPendingEditRequests();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> approveEditRequest(Map<String, dynamic> request) async {
    _setLoading(true);
    try {
      final requestId = request['id'] as String?;
      if (requestId == null) throw Exception('Invalid edit request');
      await _client.rpc(
        'approve_session_edit',
        params: {'target_request_id': requestId},
      );

      _error = null;
      await fetchAllSessions();
      await fetchPendingEditRequests();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> rejectEditRequest(String requestId) async {
    _setLoading(true);
    try {
      await _client
          .from('session_edit_requests')
          .update({'status': 'rejected'}).eq('id', requestId);
      _error = null;
      await fetchPendingEditRequests();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
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
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> cancelSession(String id) async {
    // The database emits notifications atomically with the status update.
    await updateSession(id, {'status': 'cancelled'});
  }

  Future<void> approveSession(String id) async {
    await updateSession(id, {'status': 'scheduled'});
  }

  @override
  void dispose() {
    _disposed = true;
    _fetchGeneration++;
    super.dispose();
  }

  void _setLoading(bool value) {
    if (_disposed) return;
    _loading = value;
    notifyListeners();
  }
}
