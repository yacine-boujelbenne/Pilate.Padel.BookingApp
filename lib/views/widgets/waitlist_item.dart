import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../models/waitlist_entry.dart';

class WaitlistItem extends StatelessWidget {
  final WaitlistEntry entry;
  final VoidCallback onLeave;
  final bool busy;

  const WaitlistItem({
    super.key,
    required this.entry,
    required this.onLeave,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.sagePale,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              '${entry.position}',
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.session?.title ?? 'Session details unavailable',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (entry.session != null)
                  Text(
                    DateFormat(
                      'EEE d MMM · HH:mm',
                    ).format(entry.session!.startAt),
                    style: AppTextStyles.sessionMeta,
                  ),
                Text(
                  'Preferred channel: ${entry.notifyChannel}',
                  style: AppTextStyles.sessionMeta,
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: busy ? null : onLeave,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.redLight,
              foregroundColor: AppColors.redDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }
}
