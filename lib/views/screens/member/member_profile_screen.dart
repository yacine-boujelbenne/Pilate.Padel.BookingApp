import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../controllers/auth_controller.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/buttons.dart';
import '../../widgets/chip_badge.dart';
import '../../widgets/flex_app_bar.dart';
import '../../widgets/flex_bottom_nav.dart';
import '../../widgets/stat_card.dart';

class MemberProfileScreen extends StatelessWidget {
  const MemberProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthController>().profile;
    return Scaffold(
      appBar: const FlexAppBar(title: 'Profile', badgeText: 'Member'),
      bottomNavigationBar: FlexBottomNav(
        currentIndex: 3,
        onTap: (index) {
          if (index == 0) context.go('/member/home');
          if (index == 1) context.go('/member/explore');
          if (index == 2) context.go('/member/bookings');
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'HOME'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'EXPLORE'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month), label: 'MY BOOKINGS'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'PROFILE'),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
              child: AvatarWidget(
                  initials: profile?.firstName.substring(0, 1) ?? 'M',
                  size: 72)),
          const SizedBox(height: 10),
          Center(
              child: Text(profile?.fullName ?? 'Member',
                  style: AppTextStyles.modalTitle
                      .copyWith(fontWeight: FontWeight.bold))),
          Center(
              child: Text(context.read<AuthController>().user?.email ?? '',
                  style: AppTextStyles.sessionMeta)),
          const SizedBox(height: 6),
          const Center(
              child: ChipBadge(
                  text: 'Gold Member', variant: ChipBadgeVariant.green)),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: const [
              StatCard(value: '22', label: 'Sessions done'),
              StatCard(value: '8', label: 'Sessions left'),
              StatCard(value: '4.8', label: 'Avg rating'),
              StatCard(value: '14', label: 'Months active'),
            ],
          ),
          const SizedBox(height: 16),
          FlexSecondaryButton(
            label: 'Sign out',
            onPressed: () async {
              await context.read<AuthController>().signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}
