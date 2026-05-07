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

  Future<void> fetchDashboardStats() async {
    _setLoading(true);
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
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchAllUsers() async {
    _setLoading(true);
    try {
      final res = await _client
          .from('profiles')
          .select()
          .order('created_at', ascending: false);
      _users = (res as List).cast<Map<String, dynamic>>();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> blockUser(String userId, bool isBlocked) async {
    await _client
        .from('profiles')
        .update({'is_blocked': isBlocked}).eq('id', userId);
    await fetchAllUsers();
  }

  Future<void> fetchAllCoaches() async {
    _setLoading(true);
    try {
      final res = await _client
          .from('profiles')
          .select()
          .eq('role', 'coach')
          .order('created_at');
      _coaches = (res as List).cast<Map<String, dynamic>>();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchPendingValidations() async {
    _setLoading(true);
    try {
      final res = await _client
          .from('bookings')
          .select(
            'id, booked_at, payment_method, payment_status, paid_amount_tnd, status, profiles!member_id(first_name, last_name), sessions!session_id(title, start_at)',
          )
          .eq('payment_status', 'pending')
          .order('booked_at', ascending: false);

      _pendingValidations = (res as List).cast<Map<String, dynamic>>();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
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
