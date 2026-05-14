import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/session_model.dart';
import '../services/session_notification_service.dart';
import '../services/supabase_service.dart';

class SessionController extends ChangeNotifier {
  final _client = SupabaseService.instance.client;

  bool _loading = false;
  String? _error;
  List<SessionModel> _sessions = [];
  List<Map<String, dynamic>> _editRequests = [];

  bool get isLoading => _loading;
  String? get error => _error;
  List<SessionModel> get sessions => _sessions;
  List<Map<String, dynamic>> get editRequests => _editRequests;

  Future<void> fetchSessionsByDate(DateTime date) async {
    _setLoading(true);
    try {
      final dayStart = DateFormat('yyyy-MM-dd').format(date);
      final dayEnd =
          DateFormat('yyyy-MM-dd').format(date.add(const Duration(days: 1)));
      final res = await _client
          .from('sessions')
          .select()
          .gte('start_at', dayStart)
          .lt('start_at', dayEnd)
          .order('start_at');

      // Filter for scheduled status with case-insensitive comparison
      _sessions = (res as List)
          .where((e) =>
              (e as Map<String, dynamic>)['status']
                  .toString()
                  .toLowerCase()
                  .trim() ==
              'scheduled')
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

  Future<void> fetchPendingEditRequests() async {
    _setLoading(true);
    try {
      final res = await _client
          .from('session_edit_requests')
          .select()
          .order('created_at', ascending: false);

      // Filter for pending status with case-insensitive comparison
      _editRequests = (res as List)
          .where((e) =>
              (e as Map<String, dynamic>)['status']
                  .toString()
                  .toLowerCase()
                  .trim() ==
              'pending')
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
      final sessionId = request['session_id'] as String?;
      final requestId = request['id'] as String?;
      if (sessionId == null || requestId == null) {
        throw Exception('Invalid edit request');
      }

      final updates = <String, dynamic>{};
      if (request['proposed_title'] != null) {
        updates['title'] = request['proposed_title'];
      }
      if (request['proposed_start_at'] != null) {
        updates['start_at'] = request['proposed_start_at'];
      }
      if (request['proposed_end_at'] != null) {
        updates['end_at'] = request['proposed_end_at'];
      }
      if (request['proposed_max_participants'] != null) {
        updates['max_participants'] = request['proposed_max_participants'];
      }
      if (request['proposed_price_tnd'] != null) {
        updates['price_tnd'] = request['proposed_price_tnd'];
      }
      if (request['proposed_level'] != null) {
        updates['level'] = request['proposed_level'];
      }

      if (updates.isNotEmpty) {
        await _client.from('sessions').update(updates).eq('id', sessionId);
      }

      await _client
          .from('session_edit_requests')
          .update({'status': 'approved'}).eq('id', requestId);

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
    // Find the session to get its title for the notification
    final session = _sessions.firstWhere(
      (s) => s.id == id,
      orElse: () => SessionModel(
        id: id,
        coachName: 'Coach',
        studioName: 'Studio',
        title: 'Session',
        level: 'all',
        startAt: DateTime.now(),
        endAt: DateTime.now(),
        maxParticipants: 0,
        bookedCount: 0,
        priceTnd: 0,
        status: 'scheduled',
      ),
    );

    // Notify all enrolled members before cancelling
    try {
      await SessionNotificationService().notifySessionCancelled(
        sessionId: id,
        sessionTitle: session.title,
      );
    } catch (e) {
      debugPrint('Failed to notify members of session cancellation: $e');
      // Continue with cancellation even if notification fails
    }

    await updateSession(id, {'status': 'cancelled'});
  }

  Future<void> approveSession(String id) async {
    await updateSession(id, {'status': 'scheduled'});
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}
