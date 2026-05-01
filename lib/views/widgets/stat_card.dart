import 'package:flutter/material.dart';

import '../../app/theme.dart';

class StatCard extends StatelessWidget {
  final String value;
  final String label;

  const StatCard({super.key, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: AppTextStyles.statNumber),
          const SizedBox(height: 6),
          Text(
            label.toUpperCase(),
            style:
                AppTextStyles.sectionLabel.copyWith(color: AppColors.sageLight),
          ),
        ],
      ),
    );
  }
}
