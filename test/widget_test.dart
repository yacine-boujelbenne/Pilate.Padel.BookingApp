import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flex_pilates_studio/app/theme.dart';
import 'package:flex_pilates_studio/core/motion/flex_motion.dart';
import 'package:flex_pilates_studio/features/bookings/presentation/reservation_sheet.dart';
import 'package:flex_pilates_studio/models/booking.dart';
import 'package:flex_pilates_studio/models/session_model.dart';
import 'package:flex_pilates_studio/views/widgets/buttons.dart';
import 'package:flex_pilates_studio/views/widgets/booking_celebration.dart';
import 'package:flex_pilates_studio/views/widgets/calendar_row.dart';
import 'package:flex_pilates_studio/views/widgets/session_card.dart';

SessionModel session() => SessionModel(
    id: 's1',
    title: 'Morning flow',
    coachName: 'Amira',
    studioName: 'Studio 1',
    startAt: DateTime.now().add(const Duration(days: 1)),
    endAt: DateTime.now().add(const Duration(days: 1, hours: 1)),
    maxParticipants: 8,
    bookedCount: 3,
    priceTnd: 45,
    level: 'all',
    status: 'scheduled');
Booking reservation() => Booking(
    id: 'b1',
    memberId: 'm1',
    sessionId: 's1',
    paymentMethod: 'cash',
    paymentStatus: 'pending',
    paidAmountTnd: 0,
    quotedAmountTnd: 45,
    bookedAt: DateTime.now(),
    status: 'confirmed',
    session: session());

Widget app(Widget child, {bool reduced = true, double textScale = 1}) =>
    MaterialApp(
      theme: buildAppTheme(),
      home: MediaQuery(
          data: MediaQueryData(
              disableAnimations: reduced,
              textScaler: TextScaler.linear(textScale)),
          child: Scaffold(body: child)),
    );

void main() {
  test('cash due uses the immutable quoted price', () {
    expect(reservation().amountDueTnd, 45);
    expect(reservation().paidAmountTnd, 0);
    expect(reservation().isUpcoming, isTrue);
  });

  test('joined session maps actual coach and studio names', () {
    final parsed = SessionModel.fromMap({
      'id': 's1',
      'start_at': '2030-01-01T10:00:00Z',
      'end_at': '2030-01-01T11:00:00Z',
      'profiles': {'first_name': 'Amira', 'last_name': 'Ben Ali'},
      'studios': {'name': 'North studio'},
    });
    expect(parsed.coachName, 'Amira Ben Ali');
    expect(parsed.studioName, 'North studio');
  });

  testWidgets('reservation stays open and prevents repeated submissions',
      (tester) async {
    final completer = Completer<Booking>();
    var calls = 0;
    await tester.pumpWidget(app(ReservationSheet(
        session: session(),
        onReserve: () {
          calls++;
          return completer.future;
        })));
    await tester.ensureVisible(find.text('Reserve my place'));
    await tester.tap(find.text('Reserve my place'));
    await tester.pump();
    expect(find.text('Reserving your place…'), findsOneWidget);
    final button =
        tester.widget<FlexPrimaryButton>(find.byType(FlexPrimaryButton));
    expect(button.isLoading, isTrue);
    expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isFalse);
    await tester.tap(find.text('Reserving your place…'));
    expect(calls, 1);
    completer.completeError(const PostgrestException(message: 'SESSION_FULL'));
    await tester.pumpAndSettle();
    expect(find.text('This session just filled up. You can join the waitlist.'),
        findsOneWidget);
    expect(find.text('Reserve my place'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion disables decorative loops', (tester) async {
    await tester.pumpWidget(app(const Column(children: [
      FlexBreathing(child: Icon(Icons.spa)),
      BookingCelebration(),
    ])));
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);
    expect(find.byType(BookingCelebration), findsOneWidget);
  });

  testWidgets('session and date cards fit narrow screens and large text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(
        SingleChildScrollView(
            child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            CalendarRow(selectedDate: DateTime.now(), onSelected: (_) {}),
            SessionCard(session: session(), onBook: () {}, onWaitlist: () {}),
          ]),
        )),
        textScale: 1.5));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
