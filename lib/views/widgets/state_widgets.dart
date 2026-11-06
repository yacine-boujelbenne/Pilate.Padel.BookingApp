import 'package:flutter/material.dart';
import '../../app/theme.dart';
import 'buttons.dart';
import 'page_layout.dart';

class FlexLoading extends StatelessWidget {
  const FlexLoading({super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.all(32),
    child: Center(
      child: Semantics(label: 'Loading', child: CircularProgressIndicator()),
    ),
  );
}

class FlexErrorCard extends StatelessWidget {
  const FlexErrorCard({
    super.key,
    required this.message,
    required this.onRetry,
  });
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => FlexSurface(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.cloud_off_outlined,
          color: AppColors.textMid,
          size: 32,
        ),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center, style: AppTextStyles.body),
        const SizedBox(height: 16),
        FlexSecondaryButton(
          label: 'Try again',
          onPressed: onRetry,
          icon: Icons.refresh_rounded,
        ),
      ],
    ),
  );
}

class FlexEmptyState extends StatelessWidget {
  const FlexEmptyState({
    super.key,
    required this.icon,
    required this.text,
    this.description,
    this.action,
  });
  final IconData icon;
  final String text;
  final String? description;
  final Widget? action;
  @override
  Widget build(BuildContext context) => FlexSurface(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.mint,
          ),
          child: Icon(icon, color: AppColors.sageDark, size: 28),
        ),
        const SizedBox(height: 16),
        Text(
          text,
          textAlign: TextAlign.center,
          style: AppTextStyles.sessionTitle,
        ),
        if (description != null) ...[
          const SizedBox(height: 8),
          Text(
            description!,
            textAlign: TextAlign.center,
            style: AppTextStyles.sessionMeta,
          ),
        ],
        if (action != null) ...[const SizedBox(height: 20), action!],
      ],
    ),
  );
}

class FlexSessionSkeletons extends StatelessWidget {
  const FlexSessionSkeletons({super.key});
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Loading sessions',
    child: ExcludeSemantics(
      child: Column(
        children: List.generate(
          3,
          (_) => Container(
            height: 146,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 180,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.sagePale.withValues(alpha: .6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: 240,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.mint,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const Spacer(),
                const LinearProgressIndicator(minHeight: 2),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
