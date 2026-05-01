import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../models/session_model.dart';
import 'buttons.dart';
import 'detail_row.dart';

class BookingModal extends StatelessWidget {
  final SessionModel session;
  final VoidCallback onConfirm;

  const BookingModal(
      {super.key, required this.session, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.sagePale,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 20),
          Text(session.title, style: AppTextStyles.modalTitle),
          const SizedBox(height: 4),
          Text('Confirm your reservation',
              style: AppTextStyles.sessionMeta.copyWith(fontSize: 13)),
          const SizedBox(height: 16),
          DetailRow(
              keyLabel: 'Date & time',
              value:
                  '${DateFormat('EEE d MMM').format(session.startAt)} · ${DateFormat('HH:mm').format(session.startAt)}'),
          DetailRow(keyLabel: 'Coach', value: session.coachName),
          DetailRow(keyLabel: 'Studio', value: session.studioName),
          DetailRow(
              keyLabel: 'Price',
              value: '${session.priceTnd.toStringAsFixed(0)} TND'),
          const SizedBox(height: 16),
          FlexPrimaryButton(label: 'Confirm booking', onPressed: onConfirm),
          const SizedBox(height: 8),
          FlexSecondaryButton(
              label: 'Cancel', onPressed: () => Navigator.of(context).pop()),
        ],
      ),
    );
  }
}
