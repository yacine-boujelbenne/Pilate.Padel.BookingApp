import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../l10n/locale_text.dart';

class NotificationBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onBook;
  final VoidCallback onDismiss;

  const NotificationBanner({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onBook,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.sageDark,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: AppColors.white),
              child: const Icon(Icons.notifications, color: AppColors.sageDark),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTextStyles.body.copyWith(
                          color: AppColors.white, fontWeight: FontWeight.bold)),
                  Text(subtitle,
                      style: AppTextStyles.sessionMeta.copyWith(
                          color: AppColors.white.withValues(alpha: 0.75))),
                ],
              ),
            ),
            TextButton(
                onPressed: onBook,
                child: Text(context.tr('Book'),
                    style: TextStyle(color: AppColors.white))),
            TextButton(
                onPressed: onDismiss,
                child: Text(context.tr('Dismiss'),
                    style: TextStyle(color: AppColors.white))),
          ],
        ),
      ),
    );
  }
}
