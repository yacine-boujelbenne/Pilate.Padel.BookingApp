import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../app/theme.dart';
import '../../../controllers/booking_controller.dart';
import '../../../models/booking.dart';
import '../../widgets/chip_badge.dart';
import '../../widgets/buttons.dart';
import '../../widgets/flex_app_bar.dart';
import '../../widgets/flex_bottom_nav.dart';
import '../../widgets/page_layout.dart';
import '../../widgets/reservation_card.dart';
import '../../widgets/state_widgets.dart';
import '../../widgets/toast_message.dart';

class MemberBookingsScreen extends StatefulWidget {
  const MemberBookingsScreen({super.key});
  @override
  State<MemberBookingsScreen> createState() => _MemberBookingsScreenState();
}

class _MemberBookingsScreenState extends State<MemberBookingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  int _filter = 0;
  final _cancelling = <String>{};
  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<BookingController>().fetchMemberBookings();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _cancel(Booking booking) async {
    if (_cancelling.contains(booking.id)) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel your reservation?'),
        content: Text(
          'Your place in ${booking.displayTitle} will be released.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep reservation'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.redDark),
            child: const Text('Cancel reservation'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _cancelling.add(booking.id));
    try {
      await context.read<BookingController>().cancelBooking(booking.id);
      if (mounted) ToastMessage.show(context, 'Reservation cancelled.');
    } catch (_) {
      if (mounted) {
        ToastMessage.show(
          context,
          'Could not cancel your reservation. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _cancelling.remove(booking.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BookingController>();
    final bookings = controller.bookings;
    final now = DateTime.now();
    bool active(Booking b) =>
        !b.isCancelled &&
        b.status == 'confirmed' &&
        (b.session == null ||
            (b.session!.status != 'completed' &&
                !b.session!.endAt.isBefore(now)));
    final visible = bookings
        .where(
          (b) => _filter == 2
              ? b.isCancelled
              : _filter == 0
              ? active(b)
              : !active(b) && !b.isCancelled,
        )
        .toList();
    visible.sort(
      (a, b) => (a.session?.startAt ?? a.bookedAt).compareTo(
        b.session?.startAt ?? b.bookedAt,
      ),
    );
    return Scaffold(
      appBar: const FlexAppBar(title: 'Your reservations'),
      bottomNavigationBar: FlexBottomNav(
        currentIndex: 2,
        onTap: (i) => goToMemberTab(context, i),
        items: memberDestinations,
      ),
      body: FlexPage(
        child: Column(
          children: [
            TabBar(
              controller: _tabs,
              tabs: const [
                Tab(text: 'Bookings'),
                Tab(text: 'Payments'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  RefreshIndicator(
                    onRefresh: controller.fetchMemberBookings,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      children: [
                        FlexSectionHeader(
                          title: 'Time well spent',
                          subtitle: 'Your movement, all in one place.',
                          action: IconButton(
                            tooltip: 'My waitlists',
                            onPressed: () => context.push('/member/waitlists'),
                            icon: const Icon(Icons.notifications_none_rounded),
                          ),
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(
                            3,
                            (i) => ChoiceChip(
                              label: Text(
                                const ['Active', 'History', 'Cancelled'][i],
                              ),
                              selected: _filter == i,
                              onSelected: (_) => setState(() => _filter = i),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (controller.isLoading && bookings.isEmpty)
                          const FlexSessionSkeletons()
                        else if (controller.error != null)
                          FlexErrorCard(
                            message: 'Your reservations couldn’t be refreshed.',
                            onRetry: controller.fetchMemberBookings,
                          )
                        else if (visible.isEmpty)
                          FlexEmptyState(
                            icon: Icons.calendar_today_outlined,
                            text: _filter == 0
                                ? 'Your next chapter starts here'
                                : 'Nothing here yet',
                            description: _filter == 0
                                ? 'Find a session that fits your rhythm.'
                                : 'Reservations will appear here as their status changes.',
                            action: FlexPrimaryButton(
                              label: 'Find a session',
                              onPressed: () => context.go('/member/home'),
                            ),
                          )
                        else
                          ...visible.map(
                            (b) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: ReservationCard(
                                booking: b,
                                busy: _cancelling.contains(b.id),
                                onCancel: active(b) ? () => _cancel(b) : null,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      ...bookings.map(
                        (b) => ListTile(
                          tileColor: AppColors.white,
                          title: Text('Payment ${b.id.substring(0, 6)}'),
                          subtitle: Text(
                            '${b.paidAmountTnd.toStringAsFixed(0)} TND',
                          ),
                          trailing: ChipBadge(
                            text: b.paymentStatus == 'paid'
                                ? 'Paid'
                                : 'Pending',
                            variant: b.paymentStatus == 'paid'
                                ? ChipBadgeVariant.green
                                : ChipBadgeVariant.amber,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Monthly total: ${bookings.fold<double>(0, (sum, b) => sum + b.paidAmountTnd).toStringAsFixed(0)} TND',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
