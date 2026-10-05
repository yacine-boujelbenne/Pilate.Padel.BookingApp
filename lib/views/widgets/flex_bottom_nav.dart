import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../core/motion/flex_motion.dart';

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
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: onTap,
          animationDuration: FlexMotion.duration(context, FlexMotion.standard),
          backgroundColor: AppColors.white,
          indicatorColor: AppColors.lime,
          height: 76,
          destinations: items
              .map(
                (item) => NavigationDestination(
                  icon: item.icon,
                  selectedIcon: item.activeIcon,
                  label: _label(item.label ?? ''),
                ),
              )
              .toList(),
        ),
      );

  String _label(String label) => label
      .toLowerCase()
      .split(' ')
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
}
