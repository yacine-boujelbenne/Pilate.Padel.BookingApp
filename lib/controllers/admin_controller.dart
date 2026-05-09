import 'package:flutter/material.dart';

import '../services/supabase_service.dart';

class AdminController extends ChangeNotifier {
  final _client = SupabaseService.instance.client;

  bool _loading = false;
  String? _error;
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _coaches = [];
  List<Map<String, dynamic>> _pendingValidations = [];

  bool get isLoading => _loading;
  String? get error => _error;
  Map<String, dynamic> get stats => _stats;
  List<Map<String, dynamic>> get users => _users;
  List<Map<String, dynamic>> get coaches => _coaches;
  List<Map<String, dynamic>> get pendingValidations => _pendingValidations;

  Future<void> refreshDashboardData() async {
    _setLoading(true);
    try {
      _error = null;
      await fetchDashboardStats();
      await fetchAllUsers();
      await fetchAllCoaches();
      await fetchPendingValidations();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchDashboardStats() async {
    try {
      final activeMembersRes = await _client
          .from('profiles')
          .select('id')
          .eq('role', 'member')
          .eq('is_blocked', false);

      final sessionsWeekRes = await _client
          .from('sessions')
          .select('id')
          .gte('start_at', DateTime.now().toIso8601String());

      final revenueRes = await _client
          .from('bookings')
          .select('paid_amount_tnd')
          .eq('payment_status', 'paid');

      final activeCoachesRes = await _client
          .from('profiles')
          .select('id')
          .eq('role', 'coach')
          .eq('is_blocked', false);

      // Fallback for legacy/manual rows with inconsistent role casing.
      final allProfilesRes =
          await _client.from('profiles').select('role, is_blocked');

      // Fallback for legacy/manual rows with inconsistent payment status casing.
      final allBookingsRes = await _client
          .from('bookings')
          .select('paid_amount_tnd, payment_status');

      final revenueTnd = (revenueRes as List).fold<double>(0, (sum, row) {
        final amount = (row as Map<String, dynamic>)['paid_amount_tnd'] as num?;
        return sum + (amount?.toDouble() ?? 0);
      });

      int activeMembers = (activeMembersRes as List).length;
      int activeCoaches = (activeCoachesRes as List).length;

      if (activeMembers == 0 || activeCoaches == 0) {
        for (final row in (allProfilesRes as List)) {
          final map = row as Map<String, dynamic>;
          final role = (map['role'] as String?)?.toLowerCase().trim();
          final isBlocked = map['is_blocked'] == true;
          if (!isBlocked && role == 'member') {
            activeMembers += 1;
          }
          if (!isBlocked && role == 'coach') {
            activeCoaches += 1;
          }
        }
      }

      double normalizedRevenueTnd = revenueTnd;
      if (normalizedRevenueTnd == 0) {
        normalizedRevenueTnd =
            (allBookingsRes as List).fold<double>(0, (sum, row) {
          final map = row as Map<String, dynamic>;
          final status =
              (map['payment_status'] as String?)?.toLowerCase().trim();
          if (status != 'paid') {
            return sum;
          }
          final amount = map['paid_amount_tnd'] as num?;
          return sum + (amount?.toDouble() ?? 0);
        });
      }

      _stats = {
        'activeMembers': activeMembers,
        'sessionsWeek': (sessionsWeekRes as List).length,
        'revenueTnd': normalizedRevenueTnd,
        'activeCoaches': activeCoaches,
      };
    } catch (e) {
      _error ??= 'Failed loading dashboard stats: $e';
    }
  }

  Future<void> fetchAllUsers() async {
    try {
      final res = await _client
          .from('profiles')
          .select()
          .order('created_at', ascending: false);
      _users = (res as List).cast<Map<String, dynamic>>();
    } catch (e) {
      _error ??= 'Failed loading users: $e';
    }
  }

  Future<void> blockUser(String userId, bool isBlocked) async {
    await _client
        .from('profiles')
        .update({'is_blocked': isBlocked}).eq('id', userId);
    await fetchAllUsers();
  }

  Future<void> fetchAllCoaches() async {
    try {
      final res = await _client
          .from('profiles')
          .select()
          .eq('role', 'coach')
          .order('created_at');
      var coaches = (res as List).cast<Map<String, dynamic>>();
      if (coaches.isEmpty) {
        final fallback =
            await _client.from('profiles').select().order('created_at');
        coaches = (fallback as List)
            .cast<Map<String, dynamic>>()
            .where((row) =>
                (row['role'] as String?)?.toLowerCase().trim() == 'coach')
            .toList();
      }
      _coaches = coaches;
    } catch (e) {
      _error ??= 'Failed loading coaches: $e';
    }
  }

  Future<void> fetchPendingValidations() async {
    try {
      final res = await _client
          .from('bookings')
          .select(
            'id, booked_at, payment_method, payment_status, paid_amount_tnd, status, profiles!member_id(first_name, last_name), sessions!session_id(title, start_at)',
          )
          .eq('payment_status', 'pending')
          .order('booked_at', ascending: false);

      _pendingValidations = (res as List).cast<Map<String, dynamic>>();
    } catch (e) {
      _error ??= 'Failed loading pending validations: $e';
    }
  }

  Future<void> approvePayment(String bookingId) async {
    await _client
        .from('bookings')
        .update({'payment_status': 'paid'}).eq('id', bookingId);
    await fetchPendingValidations();
  }

  Future<void> rejectPayment(String bookingId) async {
    await _client
        .from('bookings')
        .update({'payment_status': 'rejected'}).eq('id', bookingId);
    await fetchPendingValidations();
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}
