import 'package:flutter/material.dart';
import '../../app/theme.dart';
import 'brand_story.dart';

class AuthFrame extends StatelessWidget {
  const AuthFrame({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });
  final String title, subtitle;
  final Widget child;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1160),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (constraints.maxWidth >= 900) ...[
                    const Expanded(child: BrandStory()),
                    const SizedBox(width: 64),
                  ],
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: AutofillGroup(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Fléx.',
                                style: AppTextStyles.logoTitle.copyWith(
                                  color: AppColors.forest,
                                ),
                              ),
                              const SizedBox(height: 40),
                              Text(title, style: AppTextStyles.display),
                              const SizedBox(height: 12),
                              Text(subtitle, style: AppTextStyles.sessionMeta),
                              const SizedBox(height: 32),
                              child,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
