import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/booking.dart';
import '../features/bookings/data/booking_repository.dart';
import '../models/booking_detail.dart';
import '../services/supabase_service.dart';

class BookingController extends ChangeNotifier {
  final _client = SupabaseService.instance.client;

  late final _repository = BookingRepository(_client);
  int _fetchGeneration = 0;
  bool _disposed = false;

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

  Future<Booking> bookSession({
    required String sessionId,
    required String paymentMethod,
    required double amount,
  }) async {
    if (paymentMethod != 'cash') {
      throw const PostgrestException(message: 'PAYMENT_UNAVAILABLE');
    }
    // Amount is intentionally derived by the database, not trusted from UI.
    final booking = await _repository.reserve(sessionId);
    if (_disposed) return booking;
    _bookings = [booking, ..._bookings.where((item) => item.id != booking.id)];
    notifyListeners();
    return booking;
  }

  Future<Booking> fetchReceipt(String bookingId) =>
      _repository.fetchReceipt(bookingId);

  Future<void> cancelBooking(String bookingId) async {
    await _repository.cancel(bookingId);
    await fetchMemberBookings();
  }

  void reset() {
    _fetchGeneration++;
    _bookings = [];
    _sessionBookings = [];
    _loading = false;
    _error = null;
    _channel?.unsubscribe();
    _channel = null;
    notifyListeners();
  }

  Future<void> fetchMemberBookings() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      reset();
      return;
    }
    final generation = ++_fetchGeneration;
    _setLoading(true);
    try {
      final result = await _repository.fetchMember(uid);
      if (generation != _fetchGeneration ||
          uid != _client.auth.currentUser?.id) {
        return;
      }
      _bookings = result;
      _error = null;
    } catch (e) {
      if (generation == _fetchGeneration) _error = e.toString();
    } finally {
      if (generation == _fetchGeneration) _setLoading(false);
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
          .select('*, profiles!member_id(first_name, last_name, phone, role)')
          .eq('session_id', sessionId)
          .eq('status', 'confirmed')
          .order('booked_at', ascending: false);

      // Filter for confirmed status with case-insensitive comparison
      _sessionBookings = (res as List)
          .where(
        (e) =>
            (e as Map<String, dynamic>)['status']
                .toString()
                .toLowerCase()
                .trim() ==
            'confirmed',
      )
          .map((e) {
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
        .rpc('record_cash_payment', params: {'target_booking_id': bookingId});
    await fetchMemberBookings();
  }

  @override
  void dispose() {
    _disposed = true;
    _fetchGeneration++;
    _channel?.unsubscribe();
    super.dispose();
  }

  void _setLoading(bool value) {
    if (_disposed) return;
    _loading = value;
    notifyListeners();
  }
}
