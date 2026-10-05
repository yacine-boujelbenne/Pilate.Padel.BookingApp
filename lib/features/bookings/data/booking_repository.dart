import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/booking.dart';

/// Database operations are separate from presentation state.
class BookingRepository {
  final SupabaseClient client;
  BookingRepository(this.client);
  static const details =
      '*, sessions(*, profiles!coach_id(first_name,last_name), studios(name))';

  Future<Booking> reserve(String sessionId) async {
    final row = await client.rpc(
      'reserve_session',
      params: {'target_session_id': sessionId},
    );
    // Composite responses may be represented as a row or a one-row list.
    final payload = row is List ? row.single : row;
    final booking = Booking.fromMap(Map<String, dynamic>.from(payload as Map));
    return fetchReceipt(booking.id);
  }

  Future<Booking> fetchReceipt(String bookingId) async {
    final row = await client
        .from('bookings')
        .select(details)
        .eq('id', bookingId)
        .single();
    return Booking.fromMap(row);
  }

  Future<List<Booking>> fetchMember(String uid) async {
    final rows = await client
        .from('bookings')
        .select(details)
        .eq('member_id', uid)
        .order('booked_at', ascending: false);
    return rows.map((row) => Booking.fromMap(row)).toList();
  }

  Future<void> cancel(String bookingId) async {
    await client.rpc(
      'cancel_reservation',
      params: {'target_booking_id': bookingId},
    );
  }
}
