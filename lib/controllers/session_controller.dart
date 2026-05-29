import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/session_model.dart';
import '../services/follow_notification_service.dart';
import '../services/session_notification_service.dart';
import '../services/supabase_service.dart';

class SessionController extends ChangeNotifier {
  final _client = SupabaseService.instance.client;

  bool _loading = false;
  String? _error;
  List<SessionModel> _sessions = [];
  List<SessionModel> _allSessions = [];
  List<Map<String, dynamic>> _editRequests = [];

  bool get isLoading => _loading;
  String? get error => _error;
  List<SessionModel> get sessions => _sessions;
  List<SessionModel> get allSessions => _allSessions;
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

      final normalizedRows = await _normalizeBookedCounts(res as List);

      // Filter for scheduled status with case-insensitive comparison
      _sessions = normalizedRows
          .where((e) =>
            e['status'].toString().toLowerCase().trim() == 'scheduled')
          .map((e) => SessionModel.fromMap(e))
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
      final normalizedRows = await _normalizeBookedCounts(res as List);
      _allSessions = normalizedRows
          .map((e) => SessionModel.fromMap(e))
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

  Future<List<Map<String, dynamic>>> _normalizeBookedCounts(
    List<dynamic> sessionRows,
  ) async {
    final typedRows = sessionRows
        .map((row) => Map<String, dynamic>.from(row as Map<String, dynamic>))
        .toList();

    if (typedRows.isEmpty) {
      return typedRows;
    }

    final sessionIds = typedRows
        .map((row) => row['id']?.toString())
        .whereType<String>()
        .toList();

    if (sessionIds.isEmpty) {
      return typedRows;
    }

    final confirmedRows = await _client
        .from('bookings')
        .select('session_id')
        .eq('status', 'confirmed')
        .inFilter('session_id', sessionIds);

    final confirmedCounts = <String, int>{};
    for (final row in confirmedRows as List) {
      final booking = row as Map<String, dynamic>;
      final sessionId = booking['session_id']?.toString();
      if (sessionId == null || sessionId.isEmpty) {
        continue;
      }
      confirmedCounts[sessionId] = (confirmedCounts[sessionId] ?? 0) + 1;
    }

    for (final row in typedRows) {
      final sessionId = row['id']?.toString();
      if (sessionId == null || sessionId.isEmpty) {
        continue;
      }

      final currentBooked = (row['booked_count'] as num?)?.toInt() ?? 0;
      final actualBooked = confirmedCounts[sessionId] ?? 0;
      if (currentBooked != actualBooked) {
        row['booked_count'] = actualBooked;
        await _client.from('sessions').update({
          'booked_count': actualBooked,
        }).eq('id', sessionId);
      }
    }

    return typedRows;
  }

  Future<void> createSession(Map<String, dynamic> payload) async {
    _setLoading(true);
    try {
      await _ensureNoSessionConflict(
        studioId: payload['studio_id']?.toString(),
        startAt: _parseDateTime(payload['start_at']),
        endAt: _parseDateTime(payload['end_at']),
      );

      final inserted = await _client
          .from('sessions')
          .insert(payload)
          .select('id, coach_id')
          .single();
      _error = null;
      await fetchAllSessions();

      final sessionId = inserted['id']?.toString();
      final coachId = inserted['coach_id']?.toString();
      if (sessionId != null && coachId != null && coachId.isNotEmpty) {
        await FollowNotificationService.instance.notifyCoachSessionAssigned(
          sessionId: sessionId,
          coachId: coachId,
        );
      }
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

      final currentSession = await _client
          .from('sessions')
          .select('studio_id, start_at, end_at, booked_count, max_participants, status')
          .eq('id', sessionId)
          .maybeSingle();

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

      final currentBookedCount = (currentSession?['booked_count'] as num?)?.toInt() ?? 0;
      final currentMaxParticipants = (currentSession?['max_participants'] as num?)?.toInt() ?? 0;
      final proposedMaxParticipants = request['proposed_max_participants'] != null
          ? (request['proposed_max_participants'] as num).toInt()
          : currentMaxParticipants;

      if (proposedMaxParticipants < currentBookedCount) {
        throw Exception('Capacity cannot be lower than booked participants');
      }

      if (updates.isNotEmpty) {
        final mergedStudioId = updates['studio_id']?.toString() ?? currentSession?['studio_id']?.toString();
        final mergedStartAt = _parseDateTime(updates['start_at'] ?? currentSession?['start_at']);
        final mergedEndAt = _parseDateTime(updates['end_at'] ?? currentSession?['end_at']);

        await _ensureNoSessionConflict(
          studioId: mergedStudioId,
          startAt: mergedStartAt,
          endAt: mergedEndAt,
          excludeSessionId: sessionId,
        );

        if (request['proposed_max_participants'] != null) {
          updates['max_participants'] = proposedMaxParticipants;
        }

        await _client.from('sessions').update(updates).eq('id', sessionId);
        await FollowNotificationService.instance.notifySessionUpdated(
          sessionId: sessionId,
        );

        if (proposedMaxParticipants > currentMaxParticipants) {
          await FollowNotificationService.instance.notifySessionSpotOpened(
            sessionId: sessionId,
          );
        }
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
      final currentSession = await _client
          .from('sessions')
          .select('studio_id, start_at, end_at, status, booked_count, max_participants')
          .eq('id', id)
          .maybeSingle();

      final mergedStatus = (payload['status'] ?? currentSession?['status'] ?? 'scheduled').toString().toLowerCase().trim();
      if (mergedStatus != 'cancelled') {
        final mergedStudioId = payload['studio_id']?.toString() ?? currentSession?['studio_id']?.toString();
        final mergedStartAt = _parseDateTime(payload['start_at'] ?? currentSession?['start_at']);
        final mergedEndAt = _parseDateTime(payload['end_at'] ?? currentSession?['end_at']);
        final currentBookedCount = (currentSession?['booked_count'] as num?)?.toInt() ?? 0;
        final currentMaxParticipants = (currentSession?['max_participants'] as num?)?.toInt() ?? 0;
        final proposedMaxParticipants = payload['max_participants'] != null
            ? (payload['max_participants'] as num).toInt()
            : currentMaxParticipants;

        if (proposedMaxParticipants < currentBookedCount) {
          throw Exception('Capacity cannot be lower than booked participants');
        }

        await _ensureNoSessionConflict(
          studioId: mergedStudioId,
          startAt: mergedStartAt,
          endAt: mergedEndAt,
          excludeSessionId: id,
        );
      }

      final currentBookedCount = (currentSession?['booked_count'] as num?)?.toInt() ?? 0;
      final currentMaxParticipants = (currentSession?['max_participants'] as num?)?.toInt() ?? 0;
      final proposedMaxParticipants = payload['max_participants'] != null
          ? (payload['max_participants'] as num).toInt()
          : currentMaxParticipants;

      await _client.from('sessions').update(payload).eq('id', id);
      _error = null;
      await fetchAllSessions();

      final status = payload['status']?.toString().toLowerCase().trim();
      if (status != 'cancelled') {
        await FollowNotificationService.instance.notifySessionUpdated(
          sessionId: id,
        );
        if (proposedMaxParticipants > currentMaxParticipants && proposedMaxParticipants > currentBookedCount) {
          await FollowNotificationService.instance.notifySessionSpotOpened(
            sessionId: id,
          );
        }
      }
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

    try {
      await FollowNotificationService.instance.notifySessionCancelled(
        sessionId: id,
      );
    } catch (e) {
      debugPrint('Failed to notify followers of session cancellation: $e');
      // Continue with cancellation even if follow notifications fail
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

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(value.toString());
  }

  Future<void> _ensureNoSessionConflict({
    required String? studioId,
    required DateTime? startAt,
    required DateTime? endAt,
    String? excludeSessionId,
  }) async {
    if (studioId == null || studioId.trim().isEmpty || startAt == null || endAt == null) {
      return;
    }

    final query = _client
        .from('sessions')
        .select('id, title, start_at, end_at, status')
        .eq('studio_id', studioId.trim())
        .neq('status', 'cancelled')
        .lt('start_at', endAt.toIso8601String())
        .gt('end_at', startAt.toIso8601String());

    final result = excludeSessionId == null
        ? await query
        : await query.neq('id', excludeSessionId);

    final conflicts = result as List<dynamic>;
    if (conflicts.isNotEmpty) {
      throw Exception('This room already has a session at that time');
    }
  }
}
