import 'package:flutter_test/flutter_test.dart';
import 'package:flex_pilates_studio/models/booking.dart';
import 'package:flex_pilates_studio/models/session_model.dart';

Map<String, dynamic> sessionRow({
  String status = 'scheduled',
  int booked = 3,
}) => {
  'id': 'session',
  'title': 'Reformer flow',
  'start_at': '2030-06-12T09:00:00Z',
  'end_at': '2030-06-12T10:00:00Z',
  'max_participants': 8,
  'booked_count': booked,
  'price_tnd': 40,
  'level': 'all',
  'status': status,
  'coach': {'first_name': 'Amina', 'last_name': 'Test'},
  'studio': {'name': 'Studio one'},
};
Map<String, dynamic> bookingRow({
  String status = 'confirmed',
  Map<String, dynamic>? session,
}) => {
  'id': 'booking',
  'member_id': 'member',
  'session_id': 'session',
  'booked_at': '2030-01-01T12:00:00Z',
  'status': status,
  'session': session,
};
void main() {
  final before = DateTime.utc(2030, 6, 12, 8);
  test(
    'joined session identity and session time drive upcoming reservations',
    () {
      final booking = Booking.fromMap(bookingRow(session: sessionRow()));
      expect(booking.displayTitle, 'Reformer flow');
      expect(booking.session!.coachName, 'Amina Test');
      expect(booking.session!.studioName, 'Studio one');
      expect(booking.isUpcomingAt(before), isTrue);
      expect(booking.isUpcomingAt(DateTime.utc(2030, 6, 13)), isFalse);
      expect(booking.statusLabelAt(DateTime.utc(2030, 6, 13)), 'Completed');
    },
  );
  test('cancelled reservation and cancelled session never appear upcoming', () {
    for (final booking in [
      Booking.fromMap(bookingRow(status: 'cancelled', session: sessionRow())),
      Booking.fromMap(bookingRow(session: sessionRow(status: 'cancelled'))),
    ]) {
      expect(booking.isUpcomingAt(before), isFalse);
      expect(booking.statusLabelAt(before), 'Cancelled');
    }
  });
  test(
    'hidden historical relationship preserves reservation without inventing details',
    () {
      final booking = Booking.fromMap(bookingRow());
      expect(booking.id, 'booking');
      expect(booking.displayTitle, 'Session details unavailable');
      expect(booking.isUpcomingAt(before), isFalse);
      expect(booking.statusLabelAt(before), 'Confirmed');
    },
  );
  test('full, pending, cancelled and elapsed sessions cannot be booked', () {
    expect(SessionModel.fromMap(sessionRow()).canBookAt(before), isTrue);
    expect(
      SessionModel.fromMap(sessionRow(booked: 8)).canBookAt(before),
      isFalse,
    );
    expect(
      SessionModel.fromMap(sessionRow(status: 'pending')).canBookAt(before),
      isFalse,
    );
    expect(
      SessionModel.fromMap(sessionRow(status: 'cancelled')).canBookAt(before),
      isFalse,
    );
    expect(
      SessionModel.fromMap(
        sessionRow(),
      ).canBookAt(DateTime.utc(2030, 6, 12, 9)),
      isFalse,
    );
  });
}
