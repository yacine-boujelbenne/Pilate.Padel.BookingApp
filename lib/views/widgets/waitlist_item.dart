import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../l10n/locale_text.dart';
import '../../models/waitlist_entry.dart';

class WaitlistItem extends StatelessWidget {
  final WaitlistEntry entry;
  final VoidCallback onLeave;

  const WaitlistItem({super.key, required this.entry, required this.onLeave});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
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
            child: Text('${entry.position}',
                style:
                    AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    '${context.tr('Session')} ${entry.sessionId.substring(0, 6)}',
                    style: AppTextStyles.body
                        .copyWith(fontWeight: FontWeight.w600)),
                Text(
                    '${context.tr('Notify via')} ${entry.notifyChannel.toUpperCase()}',
                    style: AppTextStyles.sessionMeta),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onLeave,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.redLight,
              foregroundColor: AppColors.redDark,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(context.tr('Leave')),
          ),
        ],
      ),
    );
  }
}
