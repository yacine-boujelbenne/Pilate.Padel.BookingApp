import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../l10n/locale_text.dart';

enum ChipBadgeVariant { green, sage, amber, red, blue }

class ChipBadge extends StatelessWidget {
  final String text;
  final ChipBadgeVariant variant;

  const ChipBadge({super.key, required this.text, required this.variant});

  @override
  Widget build(BuildContext context) {
    final colors = switch (variant) {
      ChipBadgeVariant.green => (AppColors.greenLight, AppColors.greenDark),
      ChipBadgeVariant.sage => (AppColors.sagePale, AppColors.sageDark),
      ChipBadgeVariant.amber => (AppColors.amberLight, AppColors.amberDark),
      ChipBadgeVariant.red => (AppColors.redLight, AppColors.redDark),
      ChipBadgeVariant.blue => (AppColors.blueLight, AppColors.sageDark),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        context.tr(text),
        style: AppTextStyles.chip.copyWith(color: colors.$2),
      ),
    );
  }
}
