import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../app/theme.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/booking_controller.dart';
import '../../../controllers/session_controller.dart';
import '../../../controllers/waitlist_controller.dart';
import '../../../models/session_model.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/booking_flow.dart';
import '../../widgets/brand_story.dart';
import '../../widgets/buttons.dart';
import '../../widgets/calendar_row.dart';
import '../../widgets/flex_bottom_nav.dart';
import '../../widgets/page_layout.dart';
import '../../widgets/reservation_card.dart';
import '../../widgets/session_card.dart';
import '../../widgets/state_widgets.dart';
import '../../widgets/waitlist_flow.dart';

class MemberHomeScreen extends StatefulWidget {
  const MemberHomeScreen({super.key});
  @override
  State<MemberHomeScreen> createState() => _MemberHomeScreenState();
}

class _MemberHomeScreenState extends State<MemberHomeScreen> {
  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());
  final _pendingWaitlists = <String>{};
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    final sessions = context.read<SessionController>();
    final bookings = context.read<BookingController>();
    final waitlists = context.read<WaitlistController>();
    bookings.subscribeRealtime();
    waitlists.subscribeRealtime();
    await Future.wait([
      sessions.fetchSessionsByDate(_selectedDate),
      bookings.fetchMemberBookings(),
      waitlists.fetchMemberWaitlists(),
    ]);
  }

  void _select(DateTime date) {
    setState(() => _selectedDate = DateUtils.dateOnly(date));
    context.read<SessionController>().fetchSessionsByDate(_selectedDate);
  }

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: today,
      lastDate: DateTime(today.year + 1, today.month, today.day),
    );
    if (date != null && mounted) _select(date);
  }

  Future<void> _waitlist(SessionModel session) async {
    if (!_pendingWaitlists.add(session.id)) return;
    setState(() {});
    try {
      await openSessionWaitlist(context, session);
    } finally {
      _pendingWaitlists.remove(session.id);
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final sessions = context.watch<SessionController>();
    final bookings = context.watch<BookingController>();
    final waitlist = context.watch<WaitlistController>();
    final upcoming =
        bookings.bookings.where((b) => b.isUpcomingAt(DateTime.now())).toList()
          ..sort((a, b) => a.session!.startAt.compareTo(b.session!.startAt));
    final bookedIds = bookings.bookings
        .where((b) => b.status == 'confirmed')
        .map((b) => b.sessionId)
        .toSet();
    final waitingIds = waitlist.entries.map((w) => w.sessionId).toSet();
    final name = auth.profile?.firstName.trim() ?? '';
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 18
        ? 'Good afternoon'
        : 'Good evening';
    return Scaffold(
      bottomNavigationBar: FlexBottomNav(
        currentIndex: 0,
        onTap: (i) => goToMemberTab(context, i),
        items: memberDestinations,
      ),
      body: SafeArea(
        bottom: false,
        child: FlexPage(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Row(
                  children: [
                    Text(
                      'Fléx.',
                      style: AppTextStyles.logoTitle.copyWith(
                        color: AppColors.textDark,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Notifications',
                      onPressed: () => context.push('/member/notifications'),
                      icon: const Icon(Icons.notifications_none_rounded),
                    ),
                    IconButton(
                      tooltip: 'Your profile',
                      onPressed: () => context.go('/member/profile'),
                      icon: AvatarWidget(
                        initials: name.isEmpty ? 'M' : name[0],
                        imageUrl: auth.profile?.avatarUrl,
                        size: 38,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                FlexEntrance(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$greeting${name.isEmpty ? '' : ', $name'}',
                        style: AppTextStyles.sessionMeta,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Find your rhythm.',
                        style: AppTextStyles.display,
                      ),
                      const SizedBox(height: 24),
                      if (bookings.isSubmitting)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: LinearProgressIndicator(),
                        ),
                      if (bookings.isLoading && bookings.bookings.isEmpty)
                        const FlexLoading()
                      else if (bookings.error != null)
                        FlexErrorCard(
                          message: 'Your reservations could not be refreshed.',
                          onRetry: bookings.fetchMemberBookings,
                        )
                      else if (upcoming.isNotEmpty)
                        ReservationCard(
                          booking: upcoming.first,
                          featured: true,
                          onTap: () => context.go('/member/bookings'),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                FlexSectionHeader(
                  title: 'Make time for you',
                  subtitle: DateFormat('EEEE, d MMMM').format(_selectedDate),
                  action: IconButton(
                    tooltip: 'Choose another date',
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_month_outlined),
                  ),
                ),
                CalendarRow(selectedDate: _selectedDate, onSelected: _select),
                const SizedBox(height: 20),
                if (sessions.isLoading)
                  const FlexSessionSkeletons()
                else if (sessions.error != null)
                  FlexErrorCard(
                    message: 'We couldn’t load the schedule. Please try again.',
                    onRetry: () => sessions.fetchSessionsByDate(_selectedDate),
                  )
                else if (sessions.sessions.isEmpty)
                  FlexEmptyState(
                    icon: Icons.self_improvement_rounded,
                    text: 'A little space in the schedule',
                    description:
                        'There are no sessions on this date. Try another day.',
                    action: FlexSecondaryButton(
                      label: 'Choose a date',
                      onPressed: _pickDate,
                    ),
                  )
                else
                  ...sessions.sessions.map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: SessionCard(
                        session: s,
                        isBooked: bookedIds.contains(s.id),
                        onWaitlistList: waitingIds.contains(s.id),
                        isBusy:
                            bookings.isSubmitting ||
                            _pendingWaitlists.contains(s.id),
                        onViewBooking: () => context.go('/member/bookings'),
                        onBook: () => openSessionBooking(
                          context,
                          s,
                          onBooked: () =>
                              sessions.fetchSessionsByDate(_selectedDate),
                        ),
                        onWaitlist: () => _waitlist(s),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                const BrandStory(compact: true),
                const SizedBox(height: 20),
                FlexSurface(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.notifications_none_rounded,
                        color: AppColors.sageDark,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Waiting for a place?',
                          style: AppTextStyles.body,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push('/member/waitlists'),
                        child: const Text('My waitlists'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
