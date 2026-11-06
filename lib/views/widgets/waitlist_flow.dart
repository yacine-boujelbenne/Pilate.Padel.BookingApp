import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/waitlist_controller.dart';
import '../../models/session_model.dart';
import 'waitlist_modal.dart';
import 'toast_message.dart';

Future<void> openSessionWaitlist(
  BuildContext context,
  SessionModel session,
) async {
  final controller = context.read<WaitlistController>();
  if (controller.entries.any((entry) => entry.sessionId == session.id)) {
    context.push('/member/waitlists');
    return;
  }
  final channel = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => WaitlistModal(
      sessionName: session.title,
      position: 0,
      onJoin: (channel) => Navigator.of(sheetContext).pop(channel),
    ),
  );
  if (channel == null || !context.mounted) return;
  try {
    await controller.joinWaitlist(
      sessionId: session.id,
      notifyChannel: channel,
    );
    if (context.mounted) {
      ToastMessage.show(
        context,
        'You’re on the waitlist. View your place in My Waitlists.',
      );
    }
  } catch (_) {
    if (context.mounted) {
      ToastMessage.show(
        context,
        'Could not join the waitlist. Please try again.',
      );
    }
  }
}
