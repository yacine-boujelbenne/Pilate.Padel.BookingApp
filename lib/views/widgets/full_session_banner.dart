import 'package:flutter/material.dart';

import '../../app/theme.dart';

class FullSessionBanner extends StatelessWidget {
  const FullSessionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.redLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.cancel, color: AppColors.redDark, size: 18),
          const SizedBox(width: 8),
          Text('Session Full',
              style: AppTextStyles.body.copyWith(color: AppColors.redDark)),
        ],
      ),
    );
  }
}
