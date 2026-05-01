import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/booking.dart';
import '../services/supabase_service.dart';

class BookingController extends ChangeNotifier {
  final _client = SupabaseService.instance.client;

  List<Booking> _bookings = [];
  bool _loading = false;
  String? _error;
  RealtimeChannel? _channel;

  List<Booking> get bookings => _bookings;
  bool get isLoading => _loading;
  String? get error => _error;

  void subscribeRealtime() {
    _channel ??= _client.channel('bookings-live')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'bookings',
        callback: (_) => fetchMemberBookings(),
      )
      ..subscribe();
  }

  Future<void> bookSession({
    required String sessionId,
    required String paymentMethod,
    required double amount,
  }) async {
    _setLoading(true);
    try {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) {
        throw Exception('Not authenticated');
      }

      final existing = await _client
          .from('bookings')
          .select('id')
          .eq('member_id', uid)
          .eq('session_id', sessionId)
          .eq('status', 'confirmed');
      if ((existing as List).isNotEmpty) {
        throw Exception("You're already booked!");
      }

      await _client.from('bookings').insert({
        'member_id': uid,
        'session_id': sessionId,
        'payment_method': paymentMethod,
        'payment_status': paymentMethod == 'cash' ? 'pending' : 'paid',
        'paid_amount_tnd': amount,
        'status': 'confirmed',
      });

      _error = null;
      await fetchMemberBookings();
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> cancelBooking(String bookingId) async {
    _setLoading(true);
    try {
      await _client.from('bookings').update({
        'status': 'cancelled',
        'cancelled_at': DateTime.now().toIso8601String(),
      }).eq('id', bookingId);
      _error = null;
      await fetchMemberBookings();
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> fetchMemberBookings() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      _bookings = [];
      notifyListeners();
      return;
    }

    _setLoading(true);
    try {
      final res = await _client
          .from('bookings')
          .select()
          .eq('member_id', uid)
          .order('booked_at', ascending: false);
      _bookings = (res as List)
          .map((e) => Booking.fromMap(e as Map<String, dynamic>))
          .toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchSessionBookings(String sessionId) async {
    _setLoading(true);
    try {
      final res =
          await _client.from('bookings').select().eq('session_id', sessionId);
      _bookings = (res as List)
          .map((e) => Booking.fromMap(e as Map<String, dynamic>))
          .toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> validatePayment(String bookingId) async {
    await _client
        .from('bookings')
        .update({'payment_status': 'paid'}).eq('id', bookingId);
    await fetchMemberBookings();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}
