import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'buttons.dart';

class FlexLoading extends StatelessWidget {
  const FlexLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.sageDark),
    );
  }
}

class FlexErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const FlexErrorCard({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: AppColors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message,
                style: AppTextStyles.body.copyWith(color: AppColors.redDark)),
            const SizedBox(height: 12),
            FlexSecondaryButton(label: 'Retry', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}

class FlexEmptyState extends StatelessWidget {
  final IconData icon;
  final String text;

  const FlexEmptyState({
    super.key,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.sageLight, size: 40),
          const SizedBox(height: 10),
          Text(text,
              style: AppTextStyles.body.copyWith(color: AppColors.textMid)),
        ],
      ),
    );
  }
}
