import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../app/theme.dart';
import '../../../core/motion/flex_motion.dart';
import '../../../models/booking.dart';
import '../../../models/session_model.dart';
import '../../../views/widgets/buttons.dart';
import '../domain/booking_failure.dart';

/// One sheet owns the selection -> submission -> error journey.
/// It stays mounted while work is pending, preventing duplicate submissions.
class ReservationSheet extends StatefulWidget {
  final SessionModel session;
  final Future<Booking> Function() onReserve;
  const ReservationSheet({
    super.key,
    required this.session,
    required this.onReserve,
  });
  @override
  State<ReservationSheet> createState() => _ReservationSheetState();
}

class _ReservationSheetState extends State<ReservationSheet> {
  bool _submitting = false;
  String? _error;

  Future<void> _reserve() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final booking = await widget.onReserve();
      if (!mounted) return;
      // Re-enable PopScope before programmatically closing the sheet.
      setState(() => _submitting = false);
      Navigator.of(context).pop(booking);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = bookingFailureMessage(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    return PopScope(
      canPop: !_submitting,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            16,
            24,
            24 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text('A little time for you.', style: AppTextStyles.modalTitle),
              const SizedBox(height: 8),
              Text(
                'Review your session and reserve your place.',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.title,
                      style: AppTextStyles.sessionTitle.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      DateFormat(
                        'EEEE d MMMM · HH:mm',
                      ).format(session.startAt.toLocal()),
                      style: AppTextStyles.body,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${session.coachName} · ${session.studioName}',
                      style: AppTextStyles.sessionMeta,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      '${session.priceTnd.toStringAsFixed(2)} TND',
                      style: AppTextStyles.statNumber,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('PAYMENT', style: AppTextStyles.sectionLabel),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.forest),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.payments_outlined,
                      color: AppColors.forest,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pay at the studio',
                            style: AppTextStyles.sessionTitle,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your place is reserved now. Payment is due on arrival.',
                            style: AppTextStyles.sessionMeta,
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.forest,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Card and wallet payments are not available yet.',
                style: AppTextStyles.sessionMeta,
              ),
              _ErrorTransition(
                child: _error == null
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Semantics(
                          liveRegion: true,
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.redLight,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              _error!,
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.redDark,
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 24),
              FlexPrimaryButton(
                label: 'Reserve my place',
                isLoading: _submitting,
                onPressed: _reserve,
              ),
              const SizedBox(height: 10),
              FlexSecondaryButton(
                label: 'Keep browsing',
                onPressed:
                    _submitting ? null : () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A zero-duration AnimatedSize can dirty layout in the current Flutter engine.
/// Reduced motion bypasses the animated render object entirely.
class _ErrorTransition extends StatelessWidget {
  final Widget child;
  const _ErrorTransition({required this.child});
  @override
  Widget build(BuildContext context) => FlexMotion.reduced(context)
      ? child
      : AnimatedSize(
          duration: FlexMotion.standard, curve: FlexMotion.curve, child: child);
}
