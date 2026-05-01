import 'package:flutter/material.dart';

import '../../app/theme.dart';

class SpotsBar extends StatelessWidget {
  final int booked;
  final int max;

  const SpotsBar({super.key, required this.booked, required this.max});

  @override
  Widget build(BuildContext context) {
    final progress = max == 0 ? 0.0 : booked / max;
    final isFull = progress >= 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.clamp(0, 1),
            minHeight: 4,
            backgroundColor: AppColors.sagePale,
            valueColor: AlwaysStoppedAnimation<Color>(
                isFull ? AppColors.spotsFull : AppColors.sage),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$booked / $max spots${progress >= 0.8 && !isFull ? ' · Almost full' : ''}',
          style: AppTextStyles.chip.copyWith(
            color:
                progress >= 0.8 && !isFull ? AppColors.redDark : AppColors.sage,
          ),
        ),
      ],
    );
  }
}
