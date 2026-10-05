import 'package:flutter/material.dart';
import 'app/theme.dart';
import 'features/bookings/presentation/reservation_sheet.dart';
import 'models/booking.dart';
import 'models/session_model.dart';
import 'views/widgets/booking_celebration.dart';
import 'views/widgets/calendar_row.dart';
import 'views/widgets/flex_bottom_nav.dart';
import 'views/widgets/session_card.dart';
import 'views/widgets/state_widgets.dart';
import 'views/widgets/studio_art.dart';

/// Explicit design preview entrypoint. No credentials or backend are used.
/// Production always starts in main.dart.
void main() => runApp(MaterialApp(
    theme: buildAppTheme(),
    debugShowCheckedModeBanner: false,
    title: 'Fléx design preview',
    home: const DesignPreview()));

class DesignPreview extends StatefulWidget {
  const DesignPreview({super.key});
  @override
  State<DesignPreview> createState() => _DesignPreviewState();
}

class _DesignPreviewState extends State<DesignPreview> {
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  bool _confirmed = false;
  int _index = 0;
  SessionModel get _session => SessionModel(
      id: 'preview-session',
      title: 'Reformer flow',
      coachName: 'Amira Ben Ali',
      studioName: 'The garden studio',
      startAt: DateTime(_date.year, _date.month, _date.day, 10),
      endAt: DateTime(_date.year, _date.month, _date.day, 11),
      maxParticipants: 8,
      bookedCount: 5,
      priceTnd: 45,
      level: 'all',
      status: 'scheduled');

  Future<void> _book() async {
    final session = _session;
    final booking = await showModalBottomSheet<Booking>(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        constraints: const BoxConstraints(maxWidth: 560),
        builder: (_) => ReservationSheet(
            session: session,
            onReserve: () async {
              await Future<void>.delayed(const Duration(milliseconds: 1200));
              return Booking(
                  id: 'preview-booking',
                  memberId: 'preview-member',
                  sessionId: session.id,
                  paymentMethod: 'cash',
                  paymentStatus: 'pending',
                  paidAmountTnd: 0,
                  quotedAmountTnd: 45,
                  bookedAt: DateTime.now(),
                  status: 'confirmed',
                  session: session);
            }));
    if (mounted && booking != null) setState(() => _confirmed = true);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        bottomNavigationBar: FlexBottomNav(
            currentIndex: _index,
            onTap: (index) => setState(() => _index = index),
            items: const [
              BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined), label: 'Home'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.explore_outlined), label: 'Explore'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_today_outlined), label: 'Bookings'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline), label: 'Profile'),
            ]),
        body: SafeArea(
            child: Center(
                child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(padding: const EdgeInsets.all(24), children: [
            Text('fléx',
                style:
                    AppTextStyles.logoTitle.copyWith(color: AppColors.forest)),
            const SizedBox(height: 12),
            Text('DESIGN PREVIEW · SAMPLE DATA',
                style: AppTextStyles.sectionLabel),
            const SizedBox(height: 24),
            Text('Make room for\na little movement.',
                style: AppTextStyles.logoTitle
                    .copyWith(color: AppColors.forest, fontSize: 38)),
            const SizedBox(height: 24),
            Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                    color: AppColors.forest,
                    borderRadius: BorderRadius.circular(30)),
                child: Row(children: [
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text('FIND YOUR FLOW',
                            style: AppTextStyles.sectionLabel
                                .copyWith(color: AppColors.lime)),
                        const SizedBox(height: 12),
                        Text('Breathe.\nStretch. Reset.',
                            style:
                                AppTextStyles.logoTitle.copyWith(fontSize: 26)),
                      ])),
                  const StudioArt(compact: true)
                ])),
            const SizedBox(height: 24),
            if (_confirmed) ...[
              const Center(child: BookingCelebration()),
              Text("You're all set. Payment is due at the studio.",
                  style: AppTextStyles.body, textAlign: TextAlign.center),
              const SizedBox(height: 24),
            ],
            CalendarRow(
                selectedDate: _date,
                onSelected: (date) => setState(() {
                      _date = date;
                      _confirmed = false;
                    })),
            const SizedBox(height: 24),
            if (_index == 1)
              const FlexEmptyState(
                  icon: Icons.spa_outlined,
                  text: 'A quiet moment. Find your next session.')
            else if (_index == 3)
              const FlexSessionSkeletons()
            else
              SessionCard(
                  session: _session,
                  isBooked: _confirmed,
                  onBook: _book,
                  onWaitlist: () {}),
            const SizedBox(height: 24),
          ]),
        ))),
      );
}
