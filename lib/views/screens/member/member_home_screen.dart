import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/booking_controller.dart';
import '../../../controllers/session_controller.dart';
import '../../../controllers/waitlist_controller.dart';
import '../../../models/session_model.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/booking_modal.dart';
import '../../widgets/calendar_row.dart';
import '../../widgets/chip_badge.dart';
import '../../widgets/flex_app_bar.dart';
import '../../widgets/flex_bottom_nav.dart';
import '../../widgets/payment_modal.dart';
import '../../widgets/session_card.dart';
import '../../widgets/toast_message.dart';
import '../../widgets/waitlist_modal.dart';

class MemberHomeScreen extends StatefulWidget {
  const MemberHomeScreen({super.key});

  @override
  State<MemberHomeScreen> createState() => _MemberHomeScreenState();
}

class _MemberHomeScreenState extends State<MemberHomeScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SessionController>().fetchSessionsByDate(_selectedDate);
      context.read<BookingController>().fetchMemberBookings();
      context.read<BookingController>().subscribeRealtime();
      context.read<WaitlistController>().subscribeRealtime();
    });
  }

  Future<void> _openBookingFlow(SessionModel session) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BookingModal(
        session: session,
        onConfirm: () {
          Navigator.of(context).pop();
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => PaymentModal(
              sessionName: session.title,
              amount: session.priceTnd,
              onPay: (method) async {
                Navigator.of(context).pop();
                try {
                  await context.read<BookingController>().bookSession(
                        sessionId: session.id,
                        paymentMethod: method,
                        amount: session.priceTnd,
                      );
                  if (!mounted) return;
                  await context
                      .read<SessionController>()
                      .fetchSessionsByDate(_selectedDate);
                  if (!mounted) return;
                  context.go('/member/payment-success', extra: {
                    'sessionName': session.title,
                    'amount': session.priceTnd,
                    'method': method,
                  });
                } catch (_) {
                  if (mounted) {
                    ToastMessage.show(context,
                        'Could not complete booking. Please try again.');
                  }
                }
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _openWaitlist(SessionModel session) async {
    final waitlist = context.read<WaitlistController>();
    final pos = await waitlist.getPosition(session.id);
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WaitlistModal(
        sessionName: session.title,
        position: pos,
        onJoin: (channel) async {
          Navigator.of(context).pop();
          try {
            await waitlist.joinWaitlist(
                sessionId: session.id, notifyChannel: channel);
            if (mounted) {
              ToastMessage.show(context, 'Added to waitlist');
            }
          } catch (_) {
            if (mounted) {
              ToastMessage.show(context, 'Could not join waitlist');
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final sessions = context.watch<SessionController>().sessions;
    final sessionCtrl = context.watch<SessionController>();
    final bookings = context.watch<BookingController>().bookings;
    final confirmedBookings = bookings
        .where((booking) => booking.status == 'confirmed')
        .toList();
    final bookedSessionIds = confirmedBookings
      .map((booking) => booking.sessionId)
      .toSet();

    return Scaffold(
      appBar: const FlexAppBar(title: 'Fléx', badgeText: 'Member'),
      bottomNavigationBar: FlexBottomNav(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) context.go('/member/explore');
          if (index == 2) context.go('/member/bookings');
          if (index == 3) context.go('/member/profile');
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'HOME'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'EXPLORE'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month), label: 'MY BOOKINGS'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'PROFILE'),
        ],
      ),
      body: sessionCtrl.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.sageDark))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      AvatarWidget(
                          initials:
                              auth.profile?.firstName.substring(0, 1) ?? 'M',
                          size: 52),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                'Good morning, ${auth.profile?.firstName ?? 'Member'} ☀️',
                                style: AppTextStyles.body
                                    .copyWith(fontWeight: FontWeight.w700)),
                            Text(
                                '${auth.profile?.memberTier ?? 'Standard'} member',
                                style: AppTextStyles.sessionMeta),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                CalendarRow(
                  selectedDate: _selectedDate,
                  onSelected: (date) {
                    setState(() => _selectedDate = date);
                    context.read<SessionController>().fetchSessionsByDate(date);
                  },
                ),
                const SizedBox(height: 12),
                Text('AVAILABLE SESSIONS', style: AppTextStyles.sectionLabel),
                const SizedBox(height: 8),
                if (sessions.isEmpty)
                  const Center(
                      child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('No sessions for selected day'))),
                ...sessions.map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SessionCard(
                      session: s,
                      isBooked: bookedSessionIds.contains(s.id),
                      onBook: () => _openBookingFlow(s),
                      onWaitlist: () => _openWaitlist(s),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text('UPCOMING BOOKINGS', style: AppTextStyles.sectionLabel),
                const SizedBox(height: 8),
                if (confirmedBookings.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16)),
                    child: Text(
                      'No confirmed bookings yet',
                      style: AppTextStyles.body,
                    ),
                  )
                else
                  ...confirmedBookings.map(
                    (booking) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Session ${booking.sessionId.substring(0, 6)}',
                                  style: AppTextStyles.body,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Booked ${booking.bookedAt.day}/${booking.bookedAt.month}/${booking.bookedAt.year}',
                                  style: AppTextStyles.sessionMeta,
                                ),
                              ],
                            ),
                          ),
                          const ChipBadge(
                            text: 'Upcoming',
                            variant: ChipBadgeVariant.amber,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
