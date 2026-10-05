// Standalone offline model checks: dart run test/model_check.dart.
import 'package:flex_pilates_studio/models/booking.dart';

void check(bool condition, String message) {
  if (!condition) throw StateError(message);
}

void main() {
  final row = <String, dynamic>{
    'id': 'booking',
    'member_id': 'member',
    'session_id': 'session',
    'payment_method': 'cash',
    'payment_status': 'pending',
    'paid_amount_tnd': 0,
    'quoted_amount_tnd': 45,
    'booked_at': '2030-01-01T10:00:00Z',
    'status': 'confirmed',
    'sessions': {
      'id': 'session',
      'title': 'Morning flow',
      'start_at': '2030-01-02T10:00:00Z',
      'end_at': '2030-01-02T11:00:00Z',
      'price_tnd': 80,
      'status': 'scheduled',
      'profiles': {'first_name': 'Amira', 'last_name': 'Ben Ali'},
      'studios': {'name': 'Garden studio'},
    },
  };
  final booking = Booking.fromMap(row);
  check(booking.amountDueTnd == 45, 'Current price replaced quoted price');
  check(booking.paidAmountTnd == 0, 'Pending cash interpreted as collected');
  check(booking.session?.coachName == 'Amira Ben Ali', 'Coach join not mapped');
  check(
      booking.session?.studioName == 'Garden studio', 'Studio join not mapped');
  row['status'] = 'cancelled';
  check(!Booking.fromMap(row).isUpcoming,
      'Cancelled reservation shown as upcoming');
  row['status'] = 'confirmed';
  (row['sessions'] as Map)['status'] = 'cancelled';
  check(
      !Booking.fromMap(row).isUpcoming, 'Cancelled session shown as upcoming');
  // A thrown StateError fails this standalone verification command.
}
