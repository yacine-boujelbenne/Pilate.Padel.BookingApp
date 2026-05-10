import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../controllers/admin_controller.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/chip_badge.dart';
import '../../widgets/detail_row.dart';
import '../../widgets/flex_app_bar.dart';

class MemberDetailScreen extends StatelessWidget {
  final String userId;

  const MemberDetailScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final user = context
        .watch<AdminController>()
        .users
        .where((u) => u['id'] == userId)
        .firstOrNull;

    return Scaffold(
      appBar: const FlexAppBar(
        title: 'Member Detail',
        showBack: true,
        backTarget: '/admin/home',
      ),
      body: user == null
          ? const Center(child: Text('User not found'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Center(child: AvatarWidget(initials: 'M', size: 64)),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}',
                    style: AppTextStyles.screenTitle
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Center(
                    child: Text('${user['email'] ?? ''}',
                        style: AppTextStyles.sessionMeta)),
                const SizedBox(height: 6),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChipBadge(text: 'Gold', variant: ChipBadgeVariant.amber),
                    SizedBox(width: 8),
                    ChipBadge(text: 'Active', variant: ChipBadgeVariant.green),
                  ],
                ),
                const SizedBox(height: 12),
                const DetailRow(keyLabel: 'Member since', value: '2024'),
                const DetailRow(keyLabel: 'Sessions done', value: '22'),
                const DetailRow(keyLabel: 'Sessions left', value: '8'),
                const DetailRow(keyLabel: 'Payment status', value: 'Good'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.sagePale,
                            foregroundColor: AppColors.sageDark),
                        child: const Text('Message'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => context
                            .read<AdminController>()
                            .blockUser(userId, true),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.redLight,
                            foregroundColor: AppColors.redDark),
                        child: const Text('Block'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
