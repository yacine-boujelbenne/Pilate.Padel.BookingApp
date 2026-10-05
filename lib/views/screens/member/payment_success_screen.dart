import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../app/theme.dart';
import '../../../controllers/booking_controller.dart';
import '../../../core/motion/flex_motion.dart';
import '../../../models/booking.dart';
import '../../widgets/booking_celebration.dart';
import '../../widgets/buttons.dart';
import '../../widgets/state_widgets.dart';

/// Receipts are fetched by ID: route arguments cannot fabricate a payment.
class PaymentSuccessScreen extends StatefulWidget {
  final String bookingId;
  const PaymentSuccessScreen({super.key, required this.bookingId});
  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen> {
  late Future<Booking> _receipt;
  @override
  void initState() {
    super.initState();
    _receipt = context.read<BookingController>().fetchReceipt(widget.bookingId);
  }

  void _retry() => setState(
        () => _receipt = context.read<BookingController>().fetchReceipt(
              widget.bookingId,
            ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: FutureBuilder<Booking>(
                future: _receipt,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: FlexErrorCard(
                        message:
                            'We could not load your receipt. Your reservation may already be saved.',
                        onRetry: _retry,
                      ),
                    );
                  }
                  if (!snapshot.hasData) return const FlexLoading();
                  final booking = snapshot.data!;
                  final session = booking.session;
                  final paid = booking.paymentStatus == 'paid';
                  final confirmed = (booking.status == 'confirmed' ||
                          booking.status == 'attended') &&
                      session?.status != 'cancelled';
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        if (confirmed)
                          const BookingCelebration()
                        else
                          const Icon(
                            Icons.event_busy_rounded,
                            size: 72,
                            color: AppColors.sage,
                          ),
                        const SizedBox(height: 16),
                        Text(
                          confirmed
                              ? "You're all set."
                              : 'Reservation cancelled',
                          style: AppTextStyles.logoTitle.copyWith(
                            color: AppColors.forest,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          confirmed
                              ? 'A little movement. A little more you.'
                              : 'This reservation is no longer active.',
                          style: AppTextStyles.body,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        FlexEntrance(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'YOUR RESERVATION',
                                  style: AppTextStyles.sectionLabel,
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  session?.title ??
                                      'Session details unavailable',
                                  style: AppTextStyles.modalTitle,
                                ),
                                const SizedBox(height: 16),
                                if (session != null) ...[
                                  _detail(
                                    Icons.calendar_today_outlined,
                                    DateFormat(
                                      'EEEE d MMMM',
                                    ).format(session.startAt.toLocal()),
                                  ),
                                  _detail(
                                    Icons.schedule_rounded,
                                    DateFormat(
                                      'HH:mm',
                                    ).format(session.startAt.toLocal()),
                                  ),
                                  _detail(
                                      Icons.person_outline, session.coachName),
                                  _detail(
                                    Icons.location_on_outlined,
                                    session.studioName,
                                  ),
                                ],
                                const Divider(height: 32),
                                Text(
                                  !confirmed
                                      ? 'Payment details'
                                      : paid
                                          ? 'Payment received'
                                          : 'Payment due at studio',
                                  style: AppTextStyles.sessionTitle,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${(paid ? booking.paidAmountTnd : booking.amountDueTnd).toStringAsFixed(2)} TND',
                                  style: AppTextStyles.statNumber,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  paid
                                      ? 'Your payment has been recorded.'
                                      : 'No payment has been taken online.',
                                  style: AppTextStyles.sessionMeta,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        FlexPrimaryButton(
                          label: 'View my bookings',
                          onPressed: () => context.go('/member/bookings'),
                        ),
                        const SizedBox(height: 12),
                        FlexSecondaryButton(
                          label: 'Back to home',
                          onPressed: () => context.go('/member/home'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );

  Widget _detail(IconData icon, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.sageDark),
            const SizedBox(width: 12),
            Expanded(child: Text(value, style: AppTextStyles.body)),
          ],
        ),
      );
}
