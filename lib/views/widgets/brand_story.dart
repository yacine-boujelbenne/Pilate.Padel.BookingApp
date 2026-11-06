import 'package:flutter/material.dart';
import '../../app/theme.dart';

/// Editorial campaign imagery, never presented as the booked facility or coach.
class BrandStory extends StatelessWidget {
  const BrandStory({super.key, this.compact = false, this.padel = false});
  final bool compact, padel;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(AppRadii.feature),
    child: Stack(
      children: [
        Positioned.fill(
          child: ExcludeSemantics(
            child: Image.asset(
              padel ? 'assets/images/padel.jpg' : 'assets/images/pilates.jpg',
              fit: BoxFit.cover,
              alignment: padel ? Alignment.center : const Alignment(.3, 0),
              errorBuilder: (_, _, _) =>
                  const ColoredBox(color: AppColors.sageDark),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.forest.withValues(alpha: .08),
                  AppColors.textDark.withValues(alpha: .9),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                padel ? 'THE ENERGY OF PADEL' : 'THE ART OF MOVEMENT',
                style: AppTextStyles.sectionLabel.copyWith(
                  color: AppColors.white,
                ),
              ),
              SizedBox(height: compact ? 44 : 90),
              Text(
                padel
                    ? 'Find your focus.\nFeel your game.'
                    : 'A little movement.\nA better everyday.',
                style: AppTextStyles.modalTitle.copyWith(
                  color: AppColors.white,
                  fontSize: compact ? 24 : 28,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                padel
                    ? 'Energy, connection, and a place to play.'
                    : 'Create space for strength, balance, and you.',
                style: AppTextStyles.sessionMeta.copyWith(
                  color: AppColors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
