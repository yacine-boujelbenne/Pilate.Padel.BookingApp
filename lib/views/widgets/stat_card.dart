import 'package:flutter/material.dart';
import '../../app/theme.dart';

class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadii.card),
      border: Border.all(color: AppColors.sagePale),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: AppTextStyles.statNumber),
        const SizedBox(height: 8),
        Text(label, style: AppTextStyles.sessionMeta),
      ],
    ),
  );
}
