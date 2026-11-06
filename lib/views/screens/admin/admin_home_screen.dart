import '../../widgets/page_layout.dart';
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
import '../../widgets/state_widgets.dart';

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

  Future<void> _editCoach(Map<String, dynamic> coach) async {
    final first = TextEditingController(
      text: coach['first_name'] as String? ?? '',
    );
    final last = TextEditingController(
      text: coach['last_name'] as String? ?? '',
    );
    final speciality = TextEditingController(
      text: coach['speciality'] as String? ?? '',
    );
    bool saving = false;
    String? error;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: const Text('Coach details'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FlexFormInput(controller: first, hint: 'First name'),
                const SizedBox(height: 16),
                FlexFormInput(controller: last, hint: 'Last name'),
                const SizedBox(height: 16),
                FlexFormInput(
                  controller: speciality,
                  hint: 'Speciality',
                  errorText: error,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (first.text.trim().isEmpty ||
                          last.text.trim().isEmpty) {
                        update(() => error = 'Enter a first and last name.');
                        return;
                      }
                      update(() {
                        saving = true;
                        error = null;
                      });
                      try {
                        await this.context.read<AdminController>().updateCoach(
                          coach['id'] as String,
                          firstName: first.text.trim(),
                          lastName: last.text.trim(),
                          speciality: speciality.text.trim(),
                        );
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                      } catch (_) {
                        if (dialogContext.mounted) {
                          update(() {
                            error = 'Could not save. Please try again.';
                            saving = false;
                          });
                        }
                      }
                    },
              child: Text(saving ? 'Saving…' : 'Save changes'),
            ),
          ],
        ),
      ),
    );
    first.dispose();
    last.dispose();
    speciality.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminController>();
    final activeMembers = admin.users.where((user) {
      final role = (user['role'] as String?)?.toLowerCase().trim();
      if (role != 'member') {
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
        title: 'Admin Panel',
        badgeText: 'Admin',
        extraActions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh, color: AppColors.sageDark),
            onPressed: () =>
                context.read<AdminController>().refreshDashboardData(),
          ),
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
      body: FlexPage(
        maxWidth: 1120,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const FlexSectionHeader(
              title: 'Your club, at a glance.',
              subtitle: 'Look after your members. Make room for what’s next.',
            ),
            if (admin.isLoading) const LinearProgressIndicator(),
            if (admin.error != null)
              FlexErrorCard(
                message: 'Some club information could not be refreshed.',
                onRetry: admin.refreshDashboardData,
              ),
            const SizedBox(height: 20),
            FlexStatsGrid(
              children: [
                StatCard(
                  value: admin.stats['activeMembers']?.toString() ?? '0',
                  label: 'Active members',
                ),
                StatCard(
                  value: admin.stats['sessionsWeek']?.toString() ?? '0',
                  label: 'Upcoming sessions',
                ),
                StatCard(
                  value: admin.stats['revenueTnd']?.toStringAsFixed(0) ?? '0',
                  label: 'Revenue (TND)',
                ),
                StatCard(
                  value: admin.stats['activeCoaches']?.toString() ?? '0',
                  label: 'Active coaches',
                ),
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
                  borderRadius: BorderRadius.circular(AppRadii.card),
                ),
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
                final amount =
                    (booking['paid_amount_tnd'] as num?)?.toStringAsFixed(2) ??
                    '0.00';

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppRadii.card),
                  ),
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
                              foregroundColor: AppColors.greenDark,
                            ),
                            child: const Text('Validate'),
                          ),
                          const SizedBox(width: 6),
                          ElevatedButton(
                            onPressed: () => context
                                .read<AdminController>()
                                .rejectPayment(booking['id'] as String),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.redLight,
                              foregroundColor: AppColors.redDark,
                            ),
                            child: const Text('Reject'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 12),
            Text('MEMBERS', style: AppTextStyles.sectionLabel),
            const SizedBox(height: 8),
            FlexFormInput(
              controller: _searchController,
              hint: 'Search member...',
            ),
            const SizedBox(height: 8),
            if (activeMembers.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppRadii.card),
                ),
                child: Text(
                  _searchQuery.isEmpty
                      ? 'No active members available'
                      : 'No members match your search',
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
                    borderRadius: BorderRadius.circular(AppRadii.card),
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '${u['first_name'] ?? ''} ${u['last_name'] ?? ''}',
                        style: AppTextStyles.sessionTitle,
                      ),
                      ChipBadge(
                        text: '${u['member_tier'] ?? 'Standard'}',
                        variant: ChipBadgeVariant.amber,
                      ),
                      const SizedBox(width: 6),
                      ChipBadge(
                        text: u['is_blocked'] == true ? 'Blocked' : 'Active',
                        variant: u['is_blocked'] == true
                            ? ChipBadgeVariant.red
                            : ChipBadgeVariant.green,
                      ),
                      const SizedBox(width: 6),
                      TextButton(
                        onPressed: () =>
                            context.push('/admin/users/${u['id']}'),
                        child: const Text('View'),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Text('COACHES', style: AppTextStyles.sectionLabel),
            const SizedBox(height: 8),
            if (admin.coaches.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppRadii.card),
                ),
                child: Text('No coaches available', style: AppTextStyles.body),
              )
            else
              ...admin.coaches.map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: CoachCard(
                    name: '${c['first_name'] ?? ''} ${c['last_name'] ?? ''}',
                    speciality: '${c['speciality'] ?? 'Coach'}',
                    onEdit: () => _editCoach(c),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            FlexPrimaryButton(
              label: '+ Add coach account',
              onPressed: () => context.push('/admin/coaches/new'),
            ),
            const SizedBox(height: 8),
            FlexSecondaryButton(
              label: 'Manage all sessions',
              onPressed: () => context.push('/admin/sessions'),
            ),
          ],
        ),
      ),
    );
  }
}
