import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/booking.dart';
import '../models/booking_detail.dart';
import '../services/supabase_service.dart';

class BookingController extends ChangeNotifier {
  final _client = SupabaseService.instance.client;

  List<Booking> _bookings = [];
  bool _loading = false;
  String? _error;
  RealtimeChannel? _channel;
  List<BookingDetail> _sessionBookings = [];

  List<Booking> get bookings => _bookings;
  bool get isLoading => _loading;
  String? get error => _error;
  List<BookingDetail> get sessionBookings => _sessionBookings;

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

      final inserted = await _client.from('bookings').insert({
        'member_id': uid,
        'session_id': sessionId,
        'payment_method': paymentMethod,
        'payment_status': paymentMethod == 'cash' ? 'pending' : 'paid',
        'paid_amount_tnd': amount,
        'status': 'confirmed',
      }).select().single();

      final createdBooking = Booking.fromMap(
        Map<String, dynamic>.from(inserted as Map),
      );
      _bookings = [
        createdBooking,
        ..._bookings.where((booking) => booking.id != createdBooking.id),
      ];
      notifyListeners();

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

  Future<void> fetchSessionBookingsWithMembers(String sessionId) async {
    _setLoading(true);
    try {
      final res = await _client
          .from('bookings')
          .select(
            '*, profiles!member_id(first_name, last_name, phone, role)',
          )
          .eq('session_id', sessionId)
          .eq('status', 'confirmed')
          .order('booked_at', ascending: false);

      _sessionBookings = (res as List).map((e) {
        final booking = e as Map<String, dynamic>;
        final profile = booking['profiles'] as Map<String, dynamic>?;
        return BookingDetail(
          bookingId: booking['id'] as String,
          memberId: booking['member_id'] as String,
          memberName:
              '${profile?['first_name'] ?? ''} ${profile?['last_name'] ?? ''}'
                    .trim(),
          memberEmail: profile?['phone'] as String? ?? '',
          paymentMethod: booking['payment_method'] as String? ?? 'cash',
          paymentStatus: booking['payment_status'] as String? ?? 'pending',
          paidAmountTnd: (booking['paid_amount_tnd'] as num?)?.toDouble() ?? 0,
          bookedAt: DateTime.parse(booking['booked_at'] as String),
          status: booking['status'] as String? ?? 'confirmed',
        );
      }).toList();
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
