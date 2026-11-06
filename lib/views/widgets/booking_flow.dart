import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/booking_controller.dart';
import '../../models/session_model.dart';
import 'booking_modal.dart';
import 'payment_modal.dart';
import 'toast_message.dart';

/// Shared presentation; the existing payment choices and booking payload are retained.
Future<void> openSessionBooking(
  BuildContext context,
  SessionModel session, {
  Future<void> Function()? onBooked,
}) async {
  final controller = context.read<BookingController>();
  if (controller.isSubmitting) return;
  if (controller.bookings.any(
    (b) => b.sessionId == session.id && b.status == 'confirmed',
  )) {
    context.go('/member/bookings');
    return;
  }
  if (!session.canBookAt(DateTime.now())) {
    ToastMessage.show(
      context,
      'This session is no longer available. Please refresh the schedule.',
    );
    return;
  }
  final review = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => BookingModal(
      session: session,
      onConfirm: () => Navigator.of(sheetContext).pop(true),
    ),
  );
  if (review != true || !context.mounted) return;
  final method = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => PaymentModal(
      sessionName: session.title,
      amount: session.priceTnd,
      onPay: (method) => Navigator.of(sheetContext).pop(method),
    ),
  );
  if (method == null || !context.mounted || controller.isSubmitting) return;
  try {
    await controller.bookSession(
      sessionId: session.id,
      paymentMethod: method,
      amount: session.priceTnd,
    );
  } catch (_) {
    if (context.mounted) {
      ToastMessage.show(
        context,
        'Could not reserve this session. Refresh availability and try again.',
      );
    }
    return;
  }
  if (!context.mounted) return;
  // The write succeeded. A refresh failure must not invite a duplicate submission.
  if (onBooked != null) await onBooked();
  if (!context.mounted) return;
  context.go(
    '/member/payment-success',
    extra: {
      'sessionName': session.title,
      'amount': session.priceTnd,
      'method': method,
      'session': session,
    },
  );
}
