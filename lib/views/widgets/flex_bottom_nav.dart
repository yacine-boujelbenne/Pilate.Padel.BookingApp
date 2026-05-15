import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../l10n/locale_text.dart';

class FlexBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<BottomNavigationBarItem> items;

  const FlexBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.sagePale, width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.sageDark,
        unselectedItemColor: AppColors.sageLight,
        selectedLabelStyle:
            AppTextStyles.navLabel.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: AppTextStyles.navLabel,
        items: items
            .map(
              (item) => BottomNavigationBarItem(
                icon: item.icon,
                label: context.tr(item.label ?? ''),
              ),
            )
            .toList(),
      ),
    );
  }
}
