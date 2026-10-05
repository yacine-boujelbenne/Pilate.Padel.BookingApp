import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../core/motion/flex_motion.dart';
import 'buttons.dart';

class FlexLoading extends StatelessWidget {
  const FlexLoading({super.key});
  @override
  Widget build(BuildContext context) => Center(
        child: Semantics(
          label: 'Loading',
          child: CircularProgressIndicator(
            color: AppColors.forest,
            value: FlexMotion.reduced(context) ? 0.75 : null,
          ),
        ),
      );
}

/// Layout-matched placeholders: content stays in place while loading.
class FlexSessionSkeletons extends StatelessWidget {
  const FlexSessionSkeletons({super.key});
  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Loading available sessions',
        liveRegion: true,
        child: ExcludeSemantics(
          child: FlexBreathing(
            child: Column(
              children: List.generate(
                3,
                (_) => Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _bar(120, 12),
                      const SizedBox(height: 16),
                      _bar(220, 22),
                      const SizedBox(height: 12),
                      _bar(160, 12),
                      const SizedBox(height: 24),
                      _bar(double.infinity, 48),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  Widget _bar(double width, double height) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(12),
        ),
      );
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
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.redLight,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, color: AppColors.redDark),
              const SizedBox(height: 12),
              Text(message,
                  textAlign: TextAlign.center, style: AppTextStyles.body),
              const SizedBox(height: 16),
              FlexSecondaryButton(label: 'Try again', onPressed: onRetry),
            ],
          ),
        ),
      );
}

class FlexEmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  const FlexEmptyState({super.key, required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FlexBreathing(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.lime,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.forest, size: 32),
              ),
            ),
            const SizedBox(height: 16),
            Text(text, textAlign: TextAlign.center, style: AppTextStyles.body),
          ],
        ),
      );
}
