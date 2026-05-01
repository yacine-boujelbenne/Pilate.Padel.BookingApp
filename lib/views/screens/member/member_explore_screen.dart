import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../widgets/chip_badge.dart';
import '../../widgets/coach_card.dart';
import '../../widgets/flex_app_bar.dart';
import '../../widgets/flex_bottom_nav.dart';
import '../../widgets/form_fields.dart';

class MemberExploreScreen extends StatelessWidget {
  const MemberExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final searchController = TextEditingController();
    return Scaffold(
      appBar: const FlexAppBar(title: 'Explore', badgeText: 'Member'),
      bottomNavigationBar: FlexBottomNav(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) context.go('/member/home');
          if (index == 2) context.go('/member/bookings');
          if (index == 3) context.go('/member/profile');
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
          FlexFormInput(
              controller: searchController,
              hint: 'Search sessions or coaches…'),
          const SizedBox(height: 12),
          Text('OUR COACHES', style: AppTextStyles.sectionLabel),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14)),
            child: const Row(
              children: [
                Expanded(
                    child: CoachCard(
                        name: 'Nour Ben Ali', speciality: 'Reformer Flow')),
                ChipBadge(text: 'Active', variant: ChipBadgeVariant.green),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
