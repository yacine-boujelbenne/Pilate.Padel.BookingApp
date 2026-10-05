import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../app/theme.dart';
import '../../../controllers/booking_controller.dart';
import '../../../core/motion/flex_motion.dart';
import '../../../features/bookings/domain/booking_failure.dart';
import '../../../models/booking.dart';
import '../../widgets/buttons.dart';
import '../../widgets/chip_badge.dart';
import '../../widgets/flex_app_bar.dart';
import '../../widgets/state_widgets.dart';
import '../../widgets/toast_message.dart';

class MemberBookingsScreen extends StatefulWidget {
  const MemberBookingsScreen({super.key});
  @override
  State<MemberBookingsScreen> createState() => _MemberBookingsScreenState();
}

class _MemberBookingsScreenState extends State<MemberBookingsScreen> {
  final Set<String> _cancelling = {};
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<BookingController>().fetchMemberBookings();
    });
  }

  Future<void> _cancel(Booking booking) async {
    final approved = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Cancel this session?'),
              content: const Text(
                  'Your place will be released. Contact the studio about any payment already made.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Keep reservation')),
                TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Cancel session')),
              ],
            ));
    if (!mounted || approved != true || _cancelling.contains(booking.id)) {
      return;
    }
    setState(() => _cancelling.add(booking.id));
    try {
      await context.read<BookingController>().cancelBooking(booking.id);
      if (mounted) ToastMessage.show(context, 'Reservation cancelled.');
    } catch (error) {
      if (mounted) ToastMessage.show(context, bookingFailureMessage(error));
    } finally {
      if (mounted) setState(() => _cancelling.remove(booking.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BookingController>();
    final bookings = [...controller.bookings]..sort((a, b) =>
        (b.session?.startAt ?? b.bookedAt)
            .compareTo(a.session?.startAt ?? a.bookedAt));
    return Scaffold(
      appBar: const FlexAppBar(title: 'Your movement diary'),
      body: RefreshIndicator(
        onRefresh: controller.fetchMemberBookings,
        child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(
                                child: Text(
                                    'A little consistency goes a long way.',
                                    style: AppTextStyles.body)),
                            TextButton(
                                onPressed: () =>
                                    context.push('/member/waitlists'),
                                child: const Text('Waitlists')),
                          ]),
                          const SizedBox(height: 24),
                          if (controller.error != null) ...[
                            FlexErrorCard(
                                message: 'Could not refresh your bookings.',
                                onRetry: controller.fetchMemberBookings),
                            const SizedBox(height: 16),
                          ],
                          if (controller.isLoading && bookings.isEmpty)
                            const FlexSessionSkeletons()
                          else if (bookings.isEmpty)
                            const FlexEmptyState(
                                icon: Icons.event_available_outlined,
                                text:
                                    'Your movement diary starts with one session.\nFind your next class on Home.')
                          else
                            ...bookings.map(_bookingCard),
                        ],
                      ))),
            ]),
      ),
    );
  }

  Widget _bookingCard(Booking booking) {
    final session = booking.session;
    final cancelled =
        booking.status == 'cancelled' || session?.status == 'cancelled';
    final label = cancelled
        ? 'Cancelled'
        : booking.isUpcoming
            ? 'Upcoming'
            : booking.status == 'attended'
                ? 'Attended'
                : 'Past';
    return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: FlexEntrance(
            key: ValueKey(booking.id),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                          child: Text(
                              session?.title ?? 'Session details unavailable',
                              style: AppTextStyles.sessionTitle)),
                      const SizedBox(width: 12),
                      ChipBadge(
                          text: label,
                          variant: cancelled
                              ? ChipBadgeVariant.sage
                              : ChipBadgeVariant.green)
                    ]),
                    const SizedBox(height: 12),
                    if (session != null) ...[
                      Text(
                          DateFormat('EEE d MMM · HH:mm')
                              .format(session.startAt.toLocal()),
                          style: AppTextStyles.body),
                      const SizedBox(height: 6),
                      Text('${session.coachName} · ${session.studioName}',
                          style: AppTextStyles.sessionMeta),
                    ],
                    const SizedBox(height: 16),
                    Text(
                        booking.paymentStatus == 'paid'
                            ? '${booking.paidAmountTnd.toStringAsFixed(2)} TND paid'
                            : cancelled
                                ? 'Contact studio for payment details'
                                : '${booking.amountDueTnd.toStringAsFixed(2)} TND due at studio',
                        style: AppTextStyles.body),
                    const SizedBox(height: 16),
                    FlexSecondaryButton(
                        label: 'View reservation',
                        onPressed: () => context
                            .push('/member/bookings/${booking.id}/receipt')),
                    if (booking.isUpcoming && !cancelled) ...[
                      const SizedBox(height: 8),
                      TextButton(
                          onPressed: _cancelling.contains(booking.id)
                              ? null
                              : () => _cancel(booking),
                          child: Text(
                              _cancelling.contains(booking.id)
                                  ? 'Cancelling…'
                                  : 'Cancel reservation',
                              style:
                                  const TextStyle(color: AppColors.redDark))),
                    ],
                  ]),
            )));
  }
}
