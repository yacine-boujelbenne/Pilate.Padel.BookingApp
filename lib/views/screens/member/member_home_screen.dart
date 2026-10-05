import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../app/theme.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/booking_controller.dart';
import '../../../controllers/session_controller.dart';
import '../../../controllers/waitlist_controller.dart';
import '../../../core/motion/flex_motion.dart';
import '../../../features/bookings/presentation/reservation_sheet.dart';
import '../../../models/booking.dart';
import '../../../models/session_model.dart';
import '../../widgets/calendar_row.dart';
import '../../widgets/session_card.dart';
import '../../widgets/state_widgets.dart';
import '../../widgets/studio_art.dart';
import '../../widgets/toast_message.dart';
import '../../widgets/waitlist_modal.dart';

class MemberHomeScreen extends StatefulWidget {
  const MemberHomeScreen({super.key});
  @override
  State<MemberHomeScreen> createState() => _MemberHomeScreenState();
}

class _MemberHomeScreenState extends State<MemberHomeScreen> {
  DateTime _selectedDate = DateTime.now();
  String _level = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refresh();
      context.read<BookingController>().subscribeRealtime();
      context.read<WaitlistController>().subscribeRealtime();
    });
  }

  Future<void> _refresh() async {
    await Future.wait([
      context.read<SessionController>().fetchSessionsByDate(_selectedDate),
      context.read<BookingController>().fetchMemberBookings(),
    ]);
  }

  Future<void> _openBookingFlow(SessionModel session) async {
    final controller = context.read<BookingController>();
    final booking = await showModalBottomSheet<Booking>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (_) => ReservationSheet(
        session: session,
        onReserve: () => controller.bookSession(
          sessionId: session.id,
          paymentMethod: 'cash',
          amount: session.priceTnd,
        ),
      ),
    );
    if (!mounted || booking == null) return;
    context.read<SessionController>().fetchSessionsByDate(_selectedDate);
    context.push('/member/bookings/${booking.id}/receipt');
  }

  Future<void> _openWaitlist(SessionModel session) async {
    // Position is only shown after the server has assigned it.
    final waitlist = context.read<WaitlistController>();
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (sheetContext) => WaitlistModal(
        sessionName: session.title,
        position: null,
        onJoin: (channel) async {
          Navigator.of(sheetContext).pop();
          try {
            await waitlist.joinWaitlist(
              sessionId: session.id,
              notifyChannel: channel,
            );
            if (mounted) {
              ToastMessage.show(
                context,
                'You are on the waitlist. View your position in My bookings.',
              );
            }
          } catch (_) {
            if (mounted) {
              ToastMessage.show(
                context,
                'Could not join the waitlist. Please try again.',
              );
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final controller = context.watch<SessionController>();
    final bookingController = context.watch<BookingController>();
    final bookings = bookingController.bookings;
    final upcoming = bookings.where((booking) => booking.isUpcoming).toList()
      ..sort((a, b) => a.session!.startAt.compareTo(b.session!.startAt));
    final bookedIds = bookings
        .where((b) => b.status == 'confirmed')
        .map((b) => b.sessionId)
        .toSet();
    final sessions = controller.sessions
        .where((s) => _level == 'all' || s.level == _level || s.level == 'all')
        .toList();
    final firstName = auth.profile?.firstName.trim();
    final name = firstName == null || firstName.isEmpty ? 'there' : firstName;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 18
            ? 'Good afternoon'
            : 'Good evening';
    final isCurrentDate = DateUtils.isSameDay(
      controller.loadedDate,
      _selectedDate,
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.forest,
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'fléx',
                                style: AppTextStyles.logoTitle.copyWith(
                                  color: AppColors.forest,
                                  fontSize: 34,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                tooltip: 'My waitlists',
                                onPressed: () =>
                                    context.push('/member/waitlists'),
                                icon: const Icon(
                                  Icons.notifications_none_rounded,
                                  color: AppColors.forest,
                                ),
                              ),
                              const SizedBox(width: 8),
                              CircleAvatar(
                                backgroundColor: AppColors.lime,
                                child: Text(
                                  name[0].toUpperCase(),
                                  style: AppTextStyles.body.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            '$greeting, $name.',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textMid,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Make room for\na little movement.',
                            style: AppTextStyles.logoTitle.copyWith(
                              color: AppColors.forest,
                              fontSize: 38,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 28),
                          FlexEntrance(
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppColors.forest, Color(0xFF2D6251)],
                                ),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final copy = Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'BREATHE. STRETCH. RESET.',
                                        style: AppTextStyles.sectionLabel
                                            .copyWith(color: AppColors.lime),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Find your flow.',
                                        style: AppTextStyles.logoTitle.copyWith(
                                          fontSize: 30,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'A stronger body. A calmer mind.\nYour next session starts here.',
                                        style: AppTextStyles.body.copyWith(
                                          color: AppColors.white,
                                          height: 1.6,
                                        ),
                                      ),
                                    ],
                                  );
                                  return Row(
                                    children: [
                                      Expanded(child: copy),
                                      if (constraints.maxWidth >= 450)
                                        const StudioArt()
                                      else
                                        const StudioArt(compact: true),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                          if (upcoming.isNotEmpty) ...[
                            const SizedBox(height: 28),
                            Text(
                              'YOUR NEXT SESSION',
                              style: AppTextStyles.sectionLabel,
                            ),
                            const SizedBox(height: 12),
                            _nextBooking(upcoming.first),
                          ],
                          if (bookingController.error != null) ...[
                            const SizedBox(height: 16),
                            FlexErrorCard(
                              message: 'Your bookings could not be refreshed.',
                              onRetry: () =>
                                  bookingController.fetchMemberBookings(),
                            ),
                          ],
                          const SizedBox(height: 32),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Choose your session',
                                  style: AppTextStyles.modalTitle,
                                ),
                              ),
                              Text(
                                DateFormat('MMM yyyy').format(_selectedDate),
                                style: AppTextStyles.sessionMeta,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          CalendarRow(
                            selectedDate: _selectedDate,
                            onSelected: (date) {
                              setState(() => _selectedDate = date);
                              controller.fetchSessionsByDate(date);
                            },
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                ['all', 'beginner', 'intermediate', 'advanced']
                                    .map(
                                      (level) => ChoiceChip(
                                        label: Text(
                                          level == 'all'
                                              ? 'All levels'
                                              : '${level[0].toUpperCase()}${level.substring(1)}',
                                        ),
                                        selected: _level == level,
                                        selectedColor: AppColors.lime,
                                        backgroundColor: AppColors.white,
                                        side: const BorderSide(
                                          color: AppColors.border,
                                        ),
                                        onSelected: (_) =>
                                            setState(() => _level = level),
                                      ),
                                    )
                                    .toList(),
                          ),
                          const SizedBox(height: 24),
                          if (controller.isLoading && isCurrentDate)
                            LinearProgressIndicator(
                              minHeight: 2,
                              color: AppColors.forest,
                              value: FlexMotion.reduced(context) ? 0.75 : null,
                            ),
                          if (controller.error != null) ...[
                            FlexErrorCard(
                              message:
                                  'We could not refresh sessions. Please try again.',
                              onRetry: () =>
                                  controller.fetchSessionsByDate(_selectedDate),
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (controller.isLoading && !isCurrentDate)
                            const FlexSessionSkeletons()
                          else if (isCurrentDate && sessions.isEmpty)
                            const FlexEmptyState(
                              icon: Icons.spa_outlined,
                              text:
                                  'A quiet day on the calendar.\nTry another day or level.',
                            )
                          else if (isCurrentDate)
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final columns = constraints.maxWidth >= 880
                                    ? 3
                                    : constraints.maxWidth >= 600
                                        ? 2
                                        : 1;
                                final width = (constraints.maxWidth -
                                        (columns - 1) * 16) /
                                    columns;
                                return Wrap(
                                  spacing: 16,
                                  runSpacing: 16,
                                  children: sessions
                                      .map(
                                        (session) => SizedBox(
                                          width: width,
                                          child: FlexEntrance(
                                            key: ValueKey(session.id),
                                            child: SessionCard(
                                              session: session,
                                              isBooked: bookedIds.contains(
                                                session.id,
                                              ),
                                              onBook: () =>
                                                  _openBookingFlow(session),
                                              onWaitlist: () =>
                                                  _openWaitlist(session),
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                );
                              },
                            ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _nextBooking(Booking booking) {
    final session = booking.session!;
    return Material(
      color: AppColors.lime,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => context.push('/member/bookings/${booking.id}/receipt'),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const Icon(
                Icons.event_available_rounded,
                size: 30,
                color: AppColors.forest,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(session.title, style: AppTextStyles.sessionTitle),
                    const SizedBox(height: 6),
                    Text(
                      DateFormat(
                        'EEE d MMM · HH:mm',
                      ).format(session.startAt.toLocal()),
                      style: AppTextStyles.body,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, color: AppColors.forest),
            ],
          ),
        ),
      ),
    );
  }
}
