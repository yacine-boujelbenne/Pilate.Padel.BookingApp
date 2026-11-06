import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flex_pilates_studio/app/theme.dart';
import 'package:flex_pilates_studio/models/session_model.dart';
import 'package:flex_pilates_studio/views/widgets/booking_modal.dart';
import 'package:flex_pilates_studio/views/widgets/session_card.dart';
import 'package:flex_pilates_studio/views/widgets/flex_bottom_nav.dart';
import 'package:flex_pilates_studio/views/widgets/confirmation_motion.dart';

SessionModel session({int booked = 3}) => SessionModel(
  id: 'session',
  title: 'Reformer flow',
  coachName: 'Amina',
  studioName: 'Studio one',
  startAt: DateTime.now().add(const Duration(days: 1)),
  endAt: DateTime.now().add(const Duration(days: 1, hours: 1)),
  maxParticipants: 8,
  bookedCount: booked,
  priceTnd: 40,
  level: 'all',
  status: 'scheduled',
);
Widget host(Widget child, {double scale = 1}) => MaterialApp(
  theme: buildAppTheme(),
  home: MediaQuery(
    data: MediaQueryData(
      textScaler: TextScaler.linear(scale),
      disableAnimations: true,
    ),
    child: Scaffold(body: SingleChildScrollView(child: child)),
  ),
);

void main() {
  testWidgets('full session offers a waitlist instead of a booking action', (
    tester,
  ) async {
    var booked = false, waitlisted = false;
    await tester.pumpWidget(
      host(
        SessionCard(
          session: session(booked: 8),
          onBook: () => booked = true,
          onWaitlist: () => waitlisted = true,
        ),
      ),
    );
    expect(find.text('Reserve a place'), findsNothing);
    await tester.tap(find.text('Join waitlist'));
    expect(waitlisted, isTrue);
    expect(booked, isFalse);
  });
  testWidgets(
    'reserved session routes to its reservation and has no dead cancel action',
    (tester) async {
      var viewed = false;
      await tester.pumpWidget(
        host(
          SessionCard(
            session: session(),
            isBooked: true,
            onBook: () {},
            onWaitlist: () {},
            onViewBooking: () => viewed = true,
          ),
        ),
      );
      await tester.tap(find.text('View reservation'));
      expect(viewed, isTrue);
      expect(find.text('Cancel'), findsNothing);
    },
  );
  testWidgets('booking review and card fit narrow screens with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final child in [
      SessionCard(session: session(), onBook: () {}, onWaitlist: () {}),
      BookingModal(session: session(), onConfirm: () {}),
    ]) {
      await tester.pumpWidget(host(child, scale: 2));
      await tester.pump();
      expect(tester.takeException(), isNull);
    }
  });
  testWidgets(
    'navigation keeps destinations visible and tappable with large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 850);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      int? tapped;
      await tester.pumpWidget(
        host(
          FlexBottomNav(
            currentIndex: 0,
            onTap: (i) => tapped = i,
            items: memberDestinations,
          ),
          scale: 2,
        ),
      );
      await tester.tap(find.text('Bookings'));
      expect(tapped, 2);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'reduced motion displays a static confirmation without loading Rive',
    (tester) async {
      await tester.pumpWidget(host(const ConfirmationMotion()));
      expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
