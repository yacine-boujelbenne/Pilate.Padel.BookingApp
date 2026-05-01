import 'package:flutter/material.dart';

import '../services/supabase_service.dart';

class AdminController extends ChangeNotifier {
  final _client = SupabaseService.instance.client;

  bool _loading = false;
  String? _error;
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _coaches = [];

  bool get isLoading => _loading;
  String? get error => _error;
  Map<String, dynamic> get stats => _stats;
  List<Map<String, dynamic>> get users => _users;
  List<Map<String, dynamic>> get coaches => _coaches;

  Future<void> fetchDashboardStats() async {
    _setLoading(true);
    try {
      _stats = {
        'activeMembers': 0,
        'sessionsWeek': 0,
        'revenueTnd': 0.0,
        'activeCoaches': 0,
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

  Future<void> approvePayment(String bookingId) async {
    await _client
        .from('bookings')
        .update({'payment_status': 'paid'}).eq('id', bookingId);
  }

  Future<void> rejectPayment(String bookingId) async {
    await _client
        .from('bookings')
        .update({'payment_status': 'rejected'}).eq('id', bookingId);
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}
