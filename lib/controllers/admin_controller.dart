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
      // Simple lightweight queries - no heavy fallback scans
      final activeMembersRes = await _client
          .from('profiles')
          .select('id')
          .eq('role', 'member')
          .eq('is_blocked', false)
          .limit(10000);

      final sessionsWeekRes = await _client
          .from('sessions')
          .select('id')
          .gte('start_at', DateTime.now().toIso8601String())
          .limit(10000);

      final revenueRes = await _client
          .from('bookings')
          .select('paid_amount_tnd')
          .eq('payment_status', 'paid')
          .limit(1000);

      final activeCoachesRes = await _client
          .from('profiles')
          .select('id')
          .eq('role', 'coach')
          .eq('is_blocked', false)
          .limit(10000);

      final revenueTnd = (revenueRes as List).fold<double>(0, (sum, row) {
        final amount = (row as Map<String, dynamic>)['paid_amount_tnd'] as num?;
        return sum + (amount?.toDouble() ?? 0);
      });

      _stats = {
        'activeMembers': (activeMembersRes as List).length,
        'sessionsWeek': (sessionsWeekRes as List).length,
        'revenueTnd': revenueTnd,
        'activeCoaches': (activeCoachesRes as List).length,
      };
    } catch (e) {
      debugPrint('ERROR in fetchDashboardStats: $e');
      _error ??= 'Failed loading dashboard stats: $e';
      // Set default stats instead of erroring completely
      _stats = {
        'activeMembers': 0,
        'sessionsWeek': 0,
        'revenueTnd': 0.0,
        'activeCoaches': 0,
      };
    }
  }

  Future<void> fetchAllUsers() async {
    try {
      const pageSize = 1000;
      var from = 0;
      final rows = <Map<String, dynamic>>[];

      while (true) {
        final res = await _client
            .from('profiles')
            .select()
            .range(from, from + pageSize - 1);
        final batch = (res as List).cast<Map<String, dynamic>>();
        rows.addAll(batch);
        if (batch.length < pageSize) {
          break;
        }
        from += pageSize;
      }

      _users = rows;
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
          .eq('role', 'coach'); // No order to avoid timeout
      var coaches = (res as List).cast<Map<String, dynamic>>();
      if (coaches.isEmpty) {
        final fallback = await _client.from('profiles').select().limit(1000);
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

  Future<void> sendMessageToUser({
    required String recipientId,
    required String content,
  }) async {
    final message = content.trim();
    if (message.isEmpty) {
      throw Exception('Message cannot be empty');
    }

    final senderId = _client.auth.currentUser?.id;
    if (senderId == null) {
      throw Exception('Not authenticated');
    }

    await _client.from('notifications').insert({
      'member_id': recipientId,
      'title': 'Message from admin',
      'body': message,
      'is_read': false,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
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
