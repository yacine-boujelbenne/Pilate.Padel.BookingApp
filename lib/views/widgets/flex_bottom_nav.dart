import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';

const memberDestinations = [
  BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
  BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), label: 'Explore'),
  BottomNavigationBarItem(
    icon: Icon(Icons.calendar_month_outlined),
    label: 'Bookings',
  ),
  BottomNavigationBarItem(
    icon: Icon(Icons.person_outline_rounded),
    label: 'Profile',
  ),
];
void goToMemberTab(BuildContext context, int index) {
  const paths = [
    '/member/home',
    '/member/explore',
    '/member/bookings',
    '/member/profile',
  ];
  context.go(paths[index]);
}

class FlexBottomNav extends StatelessWidget {
  const FlexBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<BottomNavigationBarItem> items;
  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Align(
      alignment: Alignment.bottomCenter,
      heightFactor: 1,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        margin: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.sagePale),
          boxShadow: AppShadows.soft,
        ),
        child: Row(
          children: List.generate(items.length, (index) {
            final selected = index == currentIndex;
            final raw = items[index].label ?? '';
            final label = raw.toLowerCase() == 'my bookings'
                ? 'Bookings'
                : '${raw.isEmpty ? '' : raw[0].toUpperCase()}${raw.length > 1 ? raw.substring(1).toLowerCase() : ''}';
            return Expanded(
              child: Semantics(
                selected: selected,
                button: true,
                label: label,
                child: Tooltip(
                  message: label,
                  child: InkWell(
                    onTap: () => onTap(index),
                    borderRadius: BorderRadius.circular(22),
                    child: AnimatedContainer(
                      duration: AppMotion.duration(context, AppMotion.standard),
                      constraints: const BoxConstraints(minHeight: 58),
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 2,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.sageDark
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: ExcludeSemantics(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconTheme(
                              data: IconThemeData(
                                size: 22,
                                color: selected
                                    ? AppColors.white
                                    : AppColors.textMid,
                              ),
                              child: selected
                                  ? items[index].activeIcon
                                  : items[index].icon,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              label,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.navLabel.copyWith(
                                color: selected
                                    ? AppColors.white
                                    : AppColors.textMid,
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
          }),
        ),
      ),
    ),
  );
}
