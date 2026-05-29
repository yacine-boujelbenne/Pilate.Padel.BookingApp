import 'package:supabase_flutter/supabase_flutter.dart';

import 'session_count_reconciler.dart';
import 'supabase_service.dart';

class FollowedCoachSummary {
  final String coachId;
  final String fullName;
  final String? speciality;
  final String? avatarUrl;
  final DateTime followedAt;

  const FollowedCoachSummary({
    required this.coachId,
    required this.fullName,
    required this.followedAt,
    this.speciality,
    this.avatarUrl,
  });
}

class FollowedSessionSummary {
  final String sessionId;
  final String title;
  final String coachName;
  final String studioName;
  final DateTime startAt;
  final DateTime endAt;
  final int maxParticipants;
  final int bookedCount;
  final String status;
  final DateTime followedAt;

  const FollowedSessionSummary({
    required this.sessionId,
    required this.title,
    required this.coachName,
    required this.studioName,
    required this.startAt,
    required this.endAt,
    required this.maxParticipants,
    required this.bookedCount,
    required this.status,
    required this.followedAt,
  });

  bool get isFull => bookedCount >= maxParticipants;
}

class FollowService {
  final SupabaseClient _client = SupabaseService.instance.client;

  String? get _userId => _client.auth.currentUser?.id;

  Future<void> followCoach(String coachId) async {
    final userId = _requireUserId();
    await _client.from('coach_follows').upsert({
      'member_id': userId,
      'coach_id': coachId,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'member_id,coach_id');
  }

  Future<void> unfollowCoach(String coachId) async {
    final userId = _requireUserId();
    await _client
        .from('coach_follows')
        .delete()
        .eq('member_id', userId)
        .eq('coach_id', coachId);
  }

  Future<void> followSession(String sessionId) async {
    final userId = _requireUserId();
    await _client.from('session_follows').upsert({
      'member_id': userId,
      'session_id': sessionId,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'member_id,session_id');
  }

  Future<void> unfollowSession(String sessionId) async {
    final userId = _requireUserId();
    await _client
        .from('session_follows')
        .delete()
        .eq('member_id', userId)
        .eq('session_id', sessionId);
  }

  Future<Set<String>> fetchFollowedCoachIds() async {
    final userId = _currentUserId();
    if (userId == null) {
      return <String>{};
    }

    final rows = await _client
        .from('coach_follows')
        .select('coach_id')
        .eq('member_id', userId)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((row) => (row as Map<String, dynamic>)['coach_id']?.toString())
        .whereType<String>()
        .where((coachId) => coachId.isNotEmpty)
        .toSet();
  }

  Future<Set<String>> fetchFollowedSessionIds() async {
    final userId = _currentUserId();
    if (userId == null) {
      return <String>{};
    }

    final rows = await _client
        .from('session_follows')
        .select('session_id')
        .eq('member_id', userId)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((row) => (row as Map<String, dynamic>)['session_id']?.toString())
        .whereType<String>()
        .where((sessionId) => sessionId.isNotEmpty)
        .toSet();
  }

  Future<List<FollowedCoachSummary>> fetchFollowedCoaches() async {
    final userId = _currentUserId();
    if (userId == null) {
      return const [];
    }

    final followRows = await _client
        .from('coach_follows')
        .select('coach_id, created_at')
        .eq('member_id', userId)
        .order('created_at', ascending: false);

    final coachIds = (followRows as List)
        .map((row) => (row as Map<String, dynamic>)['coach_id']?.toString())
        .whereType<String>()
        .where((coachId) => coachId.isNotEmpty)
        .toList();

    if (coachIds.isEmpty) {
      return const [];
    }

    final coaches = await _client
        .from('profiles')
        .select('id, first_name, last_name, speciality, avatar_url')
        .inFilter('id', coachIds)
        .eq('role', 'coach');

    final coachById = {
      for (final row in coaches as List)
        row['id'].toString(): Map<String, dynamic>.from(row),
    };

    return followRows
        .map((row) {
          final follow = Map<String, dynamic>.from(row);
          final coachId = follow['coach_id']?.toString() ?? '';
          final coach = coachById[coachId];
          if (coach == null) {
            return null;
          }

          final firstName = (coach['first_name'] as String?) ?? '';
          final lastName = (coach['last_name'] as String?) ?? '';
          return FollowedCoachSummary(
            coachId: coachId,
            fullName: '$firstName $lastName'.trim(),
            speciality: coach['speciality'] as String?,
            avatarUrl: coach['avatar_url'] as String?,
            followedAt: DateTime.parse(follow['created_at'] as String),
          );
        })
        .whereType<FollowedCoachSummary>()
        .toList();
  }

  Future<List<FollowedSessionSummary>> fetchFollowedSessions() async {
    final userId = _currentUserId();
    if (userId == null) {
      return const [];
    }

    final followRows = await _client
        .from('session_follows')
        .select('session_id, created_at')
        .eq('member_id', userId)
        .order('created_at', ascending: false);

    final sessionIds = (followRows as List)
        .map((row) => (row as Map<String, dynamic>)['session_id']?.toString())
        .whereType<String>()
        .where((sessionId) => sessionId.isNotEmpty)
        .toList();

    if (sessionIds.isEmpty) {
      return const [];
    }

    final sessions = await _client
        .from('sessions')
        .select(
            'id, title, start_at, end_at, max_participants, booked_count, level, status, coach_id, profiles!coach_id(first_name, last_name), studios(name)')
        .inFilter('id', sessionIds);

    final reconciledSessions = await SessionCountReconciler.reconcile(
      _client,
      sessions as List,
    );

    final sessionById = {
      for (final row in reconciledSessions)
        row['id'].toString(): Map<String, dynamic>.from(row),
    };

    return followRows
        .map((row) {
          final follow = Map<String, dynamic>.from(row);
          final sessionId = follow['session_id']?.toString() ?? '';
          final session = sessionById[sessionId];
          if (session == null) {
            return null;
          }

          final coach = session['profiles'] as Map<String, dynamic>?;
          final studio = session['studios'] as Map<String, dynamic>?;
          return FollowedSessionSummary(
            sessionId: sessionId,
            title: (session['title'] as String?) ?? 'Session',
            coachName:
                '${coach?['first_name'] ?? ''} ${coach?['last_name'] ?? ''}'
                        .trim()
                        .isNotEmpty
                    ? '${coach?['first_name'] ?? ''} ${coach?['last_name'] ?? ''}'
                        .trim()
                    : 'Coach',
            studioName: (studio?['name'] as String?) ?? 'Studio',
            startAt: DateTime.parse(session['start_at'] as String),
            endAt: DateTime.parse(session['end_at'] as String),
            maxParticipants:
                (session['max_participants'] as num?)?.toInt() ?? 0,
            bookedCount: (session['booked_count'] as num?)?.toInt() ?? 0,
            status: (session['status'] as String?) ?? 'scheduled',
            followedAt: DateTime.parse(follow['created_at'] as String),
          );
        })
        .whereType<FollowedSessionSummary>()
        .toList();
  }

  Future<bool> isCoachFollowed(String coachId) async {
    final ids = await fetchFollowedCoachIds();
    return ids.contains(coachId);
  }

  Future<bool> isSessionFollowed(String sessionId) async {
    final ids = await fetchFollowedSessionIds();
    return ids.contains(sessionId);
  }

  String _requireUserId() {
    final userId = _currentUserId();
    if (userId == null) {
      throw Exception('Not authenticated');
    }
    return userId;
  }

  String? _currentUserId() {
    final userId = _userId;
    if (userId == null || userId.isEmpty) {
      return null;
    }
    return userId;
  }
}
