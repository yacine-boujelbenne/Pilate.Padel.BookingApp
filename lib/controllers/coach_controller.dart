import 'package:flutter/material.dart';

import '../services/supabase_service.dart';

class CoachController extends ChangeNotifier {
  final _client = SupabaseService.instance.client;

  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _schedule = [];
  List<Map<String, dynamic>> _trainees = [];
  List<double> _fillRates = [0, 0, 0, 0, 0];
  int _sessionsToday = 0;
  int _sessionsWeek = 0;
  int _upcomingSessions = 0;
  double _averageFillRate = 0;

  bool get isLoading => _loading;
  String? get error => _error;
  List<Map<String, dynamic>> get schedule => _schedule;
  List<Map<String, dynamic>> get trainees => _trainees;
  List<double> get fillRates => _fillRates;
  int get sessionsToday => _sessionsToday;
  int get sessionsWeek => _sessionsWeek;
  int get upcomingSessions => _upcomingSessions;
  double get averageFillRate => _averageFillRate;

  Future<void> fetchCoachSchedule() async {
    _setLoading(true);
    try {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) {
        _schedule = [];
      } else {
        final res = await _client
            .from('sessions')
            .select()
            .eq('coach_id', uid)
            .order('start_at');
        _schedule = (res as List).cast<Map<String, dynamic>>();
        _updateDashboardMetrics();
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchCoachTrainees() async {
    _setLoading(true);
    try {
      final sessionIds = _schedule
          .map((session) => session['id'] as String?)
          .whereType<String>()
          .toSet();

      if (sessionIds.isEmpty) {
        _trainees = [];
        _error = null;
        return;
      }

      final res = await _client
          .from('bookings')
          .select(
            'member_id, session_id, profiles!member_id(first_name, last_name, phone, speciality, role)',
          )
          .eq('status', 'confirmed')
          .order('booked_at', ascending: false);

      final seenMembers = <String>{};
      final trainees = <Map<String, dynamic>>[];
      for (final row in res as List) {
        final booking = row as Map<String, dynamic>;
        final sessionId = booking['session_id'] as String?;
        final memberId = booking['member_id'] as String?;
        if (sessionId == null || memberId == null) continue;
        if (!sessionIds.contains(sessionId) || seenMembers.contains(memberId)) {
          continue;
        }

        seenMembers.add(memberId);
        final profile = booking['profiles'] as Map<String, dynamic>?;
        trainees.add({
          'id': memberId,
          'first_name': profile?['first_name'] ?? '',
          'last_name': profile?['last_name'] ?? '',
          'phone': profile?['phone'],
          'speciality': profile?['speciality'],
        });
      }

      _trainees = trainees;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchFillRateStats() async {
    _updateDashboardMetrics();
    notifyListeners();
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  void _updateDashboardMetrics() {
    final now = DateTime.now();
    final dayStart = DateTime(now.year, now.month, now.day);
    final weekStart = dayStart.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));

    var totalFill = 0.0;
    var fillCount = 0;
    final fillTotals = List<double>.filled(5, 0);
    final fillCounts = List<int>.filled(5, 0);

    _sessionsToday = 0;
    _sessionsWeek = 0;
    _upcomingSessions = 0;

    for (final session in _schedule) {
      final startAt = _parseDate(session['start_at']);
      final booked = (session['booked_count'] as num?)?.toDouble() ?? 0;
      final max = (session['max_participants'] as num?)?.toDouble() ?? 0;

      if (_isSameDay(startAt, now)) {
        _sessionsToday++;
      }
      if (!startAt.isBefore(weekStart) && startAt.isBefore(weekEnd)) {
        _sessionsWeek++;
      }
      if (startAt.isAfter(now)) {
        _upcomingSessions++;
      }

      if (max <= 0) continue;

      final fillRate = booked / max;
      totalFill += fillRate;
      fillCount++;

      final weekdayIndex = startAt.weekday - 1;
      if (weekdayIndex >= 0 && weekdayIndex < fillTotals.length) {
        fillTotals[weekdayIndex] += fillRate;
        fillCounts[weekdayIndex]++;
      }
    }

    _averageFillRate = fillCount == 0 ? 0 : totalFill / fillCount;
    _fillRates = List.generate(
      fillTotals.length,
      (index) => fillCounts[index] == 0 ? 0 : fillTotals[index] / fillCounts[index],
    );
  }

  DateTime _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  bool _isSameDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }
}
