import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/session_model.dart';
import 'buttons.dart';
import 'detail_row.dart';
import 'page_layout.dart';

class BookingModal extends StatelessWidget {
  const BookingModal({
    super.key,
    required this.session,
    required this.onConfirm,
  });
  final SessionModel session;
  final VoidCallback onConfirm;
  @override
  Widget build(BuildContext context) => FlexSheet(
    title: session.title,
    subtitle: 'A little time for movement. Review your session below.',
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DetailRow(
          keyLabel: 'Date',
          value: DateFormat('EEEE d MMMM').format(session.startAt),
        ),
        DetailRow(
          keyLabel: 'Time',
          value:
              '${DateFormat('HH:mm').format(session.startAt)}–${DateFormat('HH:mm').format(session.endAt)}',
        ),
        DetailRow(keyLabel: 'Coach', value: session.coachName),
        DetailRow(keyLabel: 'Studio', value: session.studioName),
        DetailRow(
          keyLabel: 'Session price',
          value: '${session.priceTnd.toStringAsFixed(0)} TND',
        ),
        const SizedBox(height: 24),
        FlexPrimaryButton(
          label: 'Continue reservation',
          onPressed: onConfirm,
          icon: Icons.arrow_forward_rounded,
        ),
        const SizedBox(height: 8),
        FlexSecondaryButton(
          label: 'Back',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    ),
  );
}
