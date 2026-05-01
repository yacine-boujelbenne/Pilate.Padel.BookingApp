import 'package:flutter/material.dart';

import '../services/supabase_service.dart';

class CoachController extends ChangeNotifier {
  final _client = SupabaseService.instance.client;

  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _schedule = [];
  List<Map<String, dynamic>> _trainees = [];
  List<double> _fillRates = [0, 0, 0, 0, 0];

  bool get isLoading => _loading;
  String? get error => _error;
  List<Map<String, dynamic>> get schedule => _schedule;
  List<Map<String, dynamic>> get trainees => _trainees;
  List<double> get fillRates => _fillRates;

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
      _trainees = [];
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchFillRateStats() async {
    _fillRates = [0.45, 0.62, 0.71, 0.58, 0.88];
    notifyListeners();
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}
