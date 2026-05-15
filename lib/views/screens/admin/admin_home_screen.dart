import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../controllers/admin_controller.dart';
import '../../../controllers/auth_controller.dart';
import '../../../l10n/locale_text.dart';
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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminController>().refreshDashboardData();
    });
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    if (!mounted) return;
    setState(() {
      _searchQuery = _searchController.text.trim().toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminController>();
    final auth = context.watch<AuthController>();
    final activeMembers = admin.users.where((user) {
      final role = (user['role'] as String?)?.toLowerCase().trim();
      final isBlocked = user['is_blocked'] == true;
      if (role != 'member' || isBlocked) {
        return false;
      }

      if (_searchQuery.isEmpty) {
        return true;
      }

      final haystack = [
        user['first_name'],
        user['last_name'],
        user['phone'],
        user['member_tier'],
      ].whereType<String>().join(' ').toLowerCase();

      return haystack.contains(_searchQuery);
    }).toList();

    return Scaffold(
      appBar: FlexAppBar(
        title: context.tr('Admin Panel'),
        badgeText: context.tr('Admin'),
        showBack: false,
        extraActions: [
          IconButton(
            tooltip: context.tr('Refresh'),
            icon: const Icon(Icons.refresh, color: AppColors.sageDark),
            onPressed: () =>
                context.read<AdminController>().refreshDashboardData(),
          ),
          IconButton(
            tooltip: context.tr('Sign out'),
            icon: const Icon(Icons.logout, color: AppColors.sageDark),
            onPressed: () async {
              await context.read<AuthController>().signOut();
              if (context.mounted) context.go('/');
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if ((auth.profile?.role ?? '') != 'admin' || admin.error != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.redLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('Dashboard diagnostic'),
                    style: AppTextStyles.sectionLabel.copyWith(
                      color: AppColors.redDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${context.tr('Current role:')} ${auth.profile?.role ?? 'unknown'}',
                    style: AppTextStyles.body,
                  ),
                  if (admin.error != null) ...[
                    const SizedBox(height: 4),
                    Text('Error: ${admin.error}', style: AppTextStyles.body),
                  ],
                ],
              ),
            ),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              StatCard(
                value: admin.stats['activeMembers']?.toString() ?? '0',
                label: context.tr('ACTIVE MEMBERS'),
              ),
              StatCard(
                value: admin.stats['sessionsWeek']?.toString() ?? '0',
                label: context.tr('THIS WEEK'),
              ),
              StatCard(
                value: admin.stats['revenueTnd']?.toStringAsFixed(0) ?? '0',
                label: context.t('Revenue (TND)', 'Revenu (TND)'),
              ),
              StatCard(
                value: admin.stats['activeCoaches']?.toString() ?? '0',
                label: context.tr('COACHES'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(context.tr('PENDING VALIDATIONS'),
              style: AppTextStyles.sectionLabel),
          const SizedBox(height: 8),
          if (admin.pendingValidations.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16)),
              child: Text(
                context.tr('No pending payment validations'),
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
              final amount =
                  (booking['paid_amount_tnd'] as num?)?.toStringAsFixed(2) ??
                      '0.00';

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
                        memberName.isEmpty
                            ? context.tr('Unknown member')
                            : memberName,
                        style: AppTextStyles.sessionTitle),
                    const SizedBox(height: 4),
                    Text(
                      '$sessionTitle · ${context.tr('Pending')} payment · $amount TND',
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
                          child: Text(context.tr('Validate')),
                        ),
                        const SizedBox(width: 6),
                        ElevatedButton(
                          onPressed: () => context
                              .read<AdminController>()
                              .rejectPayment(booking['id'] as String),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.redLight,
                              foregroundColor: AppColors.redDark),
                          child: Text(context.tr('Reject')),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 12),
          Text(context.tr('ACTIVE MEMBERS'), style: AppTextStyles.sectionLabel),
          const SizedBox(height: 8),
          FlexFormInput(
              controller: _searchController,
              hint: context.tr('Search member...')),
          const SizedBox(height: 8),
          if (activeMembers.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                _searchQuery.isEmpty
                    ? context.tr('No active members available')
                    : context.tr('No members match your search'),
                style: AppTextStyles.body,
              ),
            )
          else
            ...activeMembers.map(
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
                    ChipBadge(
                        text: '${u['member_tier'] ?? 'Standard'}',
                        variant: ChipBadgeVariant.amber),
                    const SizedBox(width: 6),
                    const ChipBadge(
                        text: 'Active', variant: ChipBadgeVariant.green),
                    const SizedBox(width: 6),
                    TextButton(
                        onPressed: () =>
                            context.push('/admin/users/${u['id']}'),
                        child: Text(context.tr('View'))),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          Text(context.tr('COACHES'), style: AppTextStyles.sectionLabel),
          const SizedBox(height: 8),
          if (admin.coaches.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(context.tr('No coaches available'),
                  style: AppTextStyles.body),
            )
          else
            ...admin.coaches.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: CoachCard(
                    name: '${c['first_name'] ?? ''} ${c['last_name'] ?? ''}',
                    speciality: '${c['speciality'] ?? 'Coach'}',
                    onEdit: () =>
                        context.push('/admin/coaches/${c['id']}/edit'),
                    onTap: () =>
                        context.push('/admin/coaches/${c['id']}/edit')),
              ),
            ),
          const SizedBox(height: 8),
          FlexPrimaryButton(
              label: context.tr('Add coach account'),
              onPressed: () => context.push('/admin/coaches/new')),
          const SizedBox(height: 8),
          FlexSecondaryButton(
              label: context.tr('Manage all sessions'),
              onPressed: () => context.push('/admin/sessions')),
        ],
      ),
    );
  }
}
