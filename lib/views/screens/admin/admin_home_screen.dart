import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../controllers/admin_controller.dart';
import '../../../controllers/auth_controller.dart';
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
      context.read<AdminController>().fetchPendingValidations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminController>();
    final searchController = TextEditingController();

    return Scaffold(
      appBar: FlexAppBar(
        title: 'Admin Panel',
        badgeText: 'Admin',
        extraActions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout, color: AppColors.sageDark),
            onPressed: () async {
              await context.read<AuthController>().signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
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
          if (admin.pendingValidations.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16)),
              child: Text(
                'No pending payment validations',
                style: AppTextStyles.body,
              ),
            )
          else
            ...admin.pendingValidations.map((booking) {
              final profile = booking['profiles'] as Map<String, dynamic>?;
              final session = booking['sessions'] as Map<String, dynamic>?;
              final memberName =
                  '${profile?['first_name'] ?? ''} ${profile?['last_name'] ?? ''}'
                      .trim();
              final sessionTitle = session?['title'] as String? ?? 'Session';
              final amount = (booking['paid_amount_tnd'] as num?)?.toStringAsFixed(2) ?? '0.00';

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      memberName.isEmpty ? 'Unknown member' : memberName,
                      style: AppTextStyles.sessionTitle,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$sessionTitle · Pending payment · $amount TND',
                      style: AppTextStyles.sessionMeta,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () => context
                              .read<AdminController>()
                              .approvePayment(booking['id'] as String),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.greenLight,
                              foregroundColor: AppColors.greenDark),
                          child: const Text('Validate'),
                        ),
                        const SizedBox(width: 6),
                        ElevatedButton(
                          onPressed: () => context
                              .read<AdminController>()
                              .rejectPayment(booking['id'] as String),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.redLight,
                              foregroundColor: AppColors.redDark),
                          child: const Text('Reject'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
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
                              context.push('/admin/users/${u['id']}'),
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
              onPressed: () => context.push('/admin/coaches/new')),
          const SizedBox(height: 8),
          FlexSecondaryButton(
              label: 'Manage all sessions',
              onPressed: () => context.push('/admin/sessions')),
        ],
      ),
    );
  }
}
