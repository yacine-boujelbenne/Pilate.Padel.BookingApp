import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../controllers/admin_controller.dart';
import '../../widgets/buttons.dart';
import '../../widgets/chip_badge.dart';
import '../../widgets/coach_card.dart';
import '../../widgets/flex_app_bar.dart';
import '../../widgets/form_fields.dart';
import '../../widgets/stat_card.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminController>().fetchDashboardStats();
      context.read<AdminController>().fetchAllUsers();
      context.read<AdminController>().fetchAllCoaches();
    });
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminController>();
    final searchController = TextEditingController();

    return Scaffold(
      appBar: const FlexAppBar(title: 'Admin Panel', badgeText: 'Admin'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: const [
              StatCard(value: '124', label: 'Active members'),
              StatCard(value: '38', label: 'Sessions / week'),
              StatCard(value: '4810', label: 'Revenue (TND)'),
              StatCard(value: '6', label: 'Active coaches'),
            ],
          ),
          const SizedBox(height: 12),
          Text('PENDING VALIDATIONS', style: AppTextStyles.sectionLabel),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                const Expanded(child: Text('Sara Kouki\nPending payment')),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.greenLight,
                      foregroundColor: AppColors.greenDark),
                  child: const Text('Validate'),
                ),
                const SizedBox(width: 6),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.redLight,
                      foregroundColor: AppColors.redDark),
                  child: const Text('Reject'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('MANAGE USERS', style: AppTextStyles.sectionLabel),
          const SizedBox(height: 8),
          FlexFormInput(controller: searchController, hint: 'Search user...'),
          const SizedBox(height: 8),
          ...admin.users.take(3).map(
                (u) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(14)),
                  child: Row(
                    children: [
                      Expanded(
                          child: Text(
                              '${u['first_name'] ?? ''} ${u['last_name'] ?? ''}')),
                      const ChipBadge(
                          text: 'Plan', variant: ChipBadgeVariant.amber),
                      const SizedBox(width: 6),
                      ChipBadge(
                          text: u['is_blocked'] == true ? 'Blocked' : 'Active',
                          variant: u['is_blocked'] == true
                              ? ChipBadgeVariant.red
                              : ChipBadgeVariant.green),
                      const SizedBox(width: 6),
                      TextButton(
                          onPressed: () =>
                              context.go('/admin/users/${u['id']}'),
                          child: const Text('View')),
                    ],
                  ),
                ),
              ),
          const SizedBox(height: 12),
          Text('COACHES', style: AppTextStyles.sectionLabel),
          const SizedBox(height: 8),
          ...admin.coaches.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: CoachCard(
                  name: '${c['first_name'] ?? ''} ${c['last_name'] ?? ''}',
                  speciality: '${c['speciality'] ?? 'Coach'}',
                  onEdit: () {}),
            ),
          ),
          const SizedBox(height: 8),
          FlexPrimaryButton(
              label: '+ Add coach account',
              onPressed: () => context.go('/admin/coaches/new')),
          const SizedBox(height: 8),
          FlexSecondaryButton(
              label: 'Manage all sessions',
              onPressed: () => context.go('/admin/sessions')),
        ],
      ),
    );
  }
}
