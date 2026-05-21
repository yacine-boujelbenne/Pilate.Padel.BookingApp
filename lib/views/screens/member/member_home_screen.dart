import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/booking_controller.dart';
import '../../../controllers/notification_controller.dart';
import '../../../controllers/session_controller.dart';
import '../../../controllers/waitlist_controller.dart';
import '../../../models/session_model.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/booking_modal.dart';
import '../../widgets/calendar_row.dart';
import '../../widgets/chip_badge.dart';
import '../../widgets/flex_app_bar.dart';
import '../../widgets/flex_bottom_nav.dart';
import '../../widgets/modern_components.dart';
import '../../widgets/payment_modal.dart';
import '../../widgets/session_card.dart';
import '../../widgets/toast_message.dart';
import '../../widgets/waitlist_modal.dart';
import '../../../l10n/locale_text.dart';

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
      context.read<SessionController>().fetchAllSessions();
      context.read<BookingController>().fetchMemberBookings();
      context.read<WaitlistController>().fetchMemberWaitlists();
      context.read<BookingController>().subscribeRealtime();
      context.read<WaitlistController>().subscribeRealtime();
    });
  }

  Future<void> _cancelBooking(String bookingId) async {
    try {
      await context.read<BookingController>().cancelBooking(bookingId);
      if (!mounted) return;
      await context
          .read<SessionController>()
          .fetchSessionsByDate(_selectedDate);
      if (!mounted) return;
      ToastMessage.show(
          context, context.t('Booking cancelled', 'Réservation annulée'));
    } catch (_) {
      if (mounted) {
        ToastMessage.show(
            context,
            context.t('Could not cancel booking. Please try again.',
                'Impossible d\'annuler la réservation. Veuillez réessayer.'));
      }
    }
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
                    ToastMessage.show(
                        context,
                        context.t(
                            'Could not complete booking. Please try again.',
                            'Impossible de terminer la réservation. Veuillez réessayer.'));
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
              ToastMessage.show(
                  context,
                  context.t(
                      'Added to waitlist', 'Ajouté à la liste d\'attente'));
            }
          } catch (_) {
            if (mounted) {
              ToastMessage.show(
                  context,
                  context.t('Could not join waitlist',
                      'Impossible de rejoindre la liste d\'attente'));
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
    final allSessions = context.watch<SessionController>().allSessions;
    final sessionCtrl = context.watch<SessionController>();
    final bookings = context.watch<BookingController>().bookings;
    final waitlistEntries = context.watch<WaitlistController>().entries;
    final confirmedBookings =
        bookings.where((booking) => booking.status == 'confirmed').toList();
    final bookedSessionIds =
        confirmedBookings.map((booking) => booking.sessionId).toSet();
    final confirmedBookingBySessionId = {
      for (final booking in confirmedBookings) booking.sessionId: booking,
    };
    final waitlistedSessionIds =
        waitlistEntries.map((entry) => entry.sessionId).toSet();
    final sessionsById = {
      for (final session in [...sessions, ...allSessions]) session.id: session,
    };

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/member/chatbot'),
        backgroundColor: AppColors.sageDark,
        child: const Icon(Icons.chat_bubble_outline, color: AppColors.white),
      ),
      appBar: AppBar(
        title: const Text('Fléx'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.sageDark,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () => context.push('/notifications'),
              ),
              Consumer<NotificationController>(
                builder: (context, controller, _) {
                  final unreadCount = controller.unreadCount;
                  if (unreadCount == 0) return const SizedBox.shrink();
                  return Positioned(
                    right: 8,
                    top: 8,
                    child: NotificationBadge(count: unreadCount),
                  );
                },
              ),
            ],
          ),
        ],
      ),
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
                                '${context.t('Good morning', 'Bonjour')}, ${auth.profile?.firstName ?? context.t('Member', 'Membre')} ☀️',
                                style: AppTextStyles.body
                                    .copyWith(fontWeight: FontWeight.w700)),
                            Text(
                                '${auth.profile?.memberTier ?? context.t('Standard', 'Standard')} ${context.t('member', 'membre')}',
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
                Text(context.t('AVAILABLE SESSIONS', 'SÉANCES DISPONIBLES'),
                    style: AppTextStyles.sectionLabel),
                const SizedBox(height: 8),
                if (sessions.isEmpty)
                  Center(
                      child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                              context.tr('No sessions for selected day')))),
                ...sessions.map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SessionCard(
                      session: s,
                      isBooked: bookedSessionIds.contains(s.id),
                      onWaitlistList: waitlistedSessionIds.contains(s.id),
                      onBook: () => _openBookingFlow(s),
                      onWaitlist: () {
                        if (waitlistedSessionIds.contains(s.id)) {
                          ToastMessage.show(
                              context,
                              context.t('You are already on this waitlist',
                                  'Vous êtes déjà sur cette liste d\'attente'));
                          return;
                        }
                        _openWaitlist(s);
                      },
                      onCancelBooking: confirmedBookingBySessionId[s.id] == null
                          ? null
                          : () => _cancelBooking(
                                confirmedBookingBySessionId[s.id]!.id,
                              ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(context.t('UPCOMING BOOKINGS', 'RÉSERVATIONS À VENIR'),
                    style: AppTextStyles.sectionLabel),
                const SizedBox(height: 8),
                if (confirmedBookings.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16)),
                    child: Text(
                      context.t('No confirmed bookings yet',
                          'Aucune réservation confirmée pour le moment'),
                      style: AppTextStyles.body,
                    ),
                  )
                else
                  ...confirmedBookings.map(
                    (booking) {
                      final sessionTitle =
                          sessionsById[booking.sessionId]?.title ??
                              context.t('Session', 'Séance');
                      return Container(
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
                                    '${context.t('Session', 'Séance')} $sessionTitle',
                                    style: AppTextStyles.body,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${context.t('Booked', 'Réservée')} ${booking.bookedAt.day}/${booking.bookedAt.month}/${booking.bookedAt.year}',
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
                      );
                    },
                  ),
              ],
            ),
    );
  }
}
