import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../controllers/admin_controller.dart';
import '../../../l10n/locale_text.dart';
import '../../../services/member_profile_summary_service.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/chip_badge.dart';
import '../../widgets/detail_row.dart';
import '../../widgets/flex_app_bar.dart';
import '../../widgets/toast_message.dart';

class MemberDetailScreen extends StatefulWidget {
  final String userId;

  const MemberDetailScreen({super.key, required this.userId});

  @override
  State<MemberDetailScreen> createState() => _MemberDetailScreenState();
}

class _MemberDetailScreenState extends State<MemberDetailScreen> {
  final MemberProfileSummaryService _summaryService =
      MemberProfileSummaryService();
  Future<MemberProfileSummary>? _summaryFuture;
  String? _userId;

  Future<void> _openMessageDialog(
      BuildContext context, Map<String, dynamic> user) async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(context.tr('Message')),
          content: TextField(
            controller: controller,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: context.tr('Write a message'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(context.tr('Cancel')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text),
              child: Text(context.tr('Send')),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (result == null || result.trim().isEmpty) {
      return;
    }

    try {
      await context.read<AdminController>().sendMessageToUser(
            recipientId: widget.userId,
            content: result,
          );
      if (!context.mounted) return;
      ToastMessage.show(
        context,
        context.tr('Message sent'),
      );
    } catch (e) {
      if (!context.mounted) return;
      ToastMessage.show(
        context,
        '${context.tr('Could not send message')}: $e',
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context
        .read<AdminController>()
        .users
        .where((u) => u['id'] == widget.userId)
        .firstOrNull;
    if (user == null) {
      _summaryFuture = null;
      _userId = null;
      return;
    }
    if (_userId != widget.userId) {
      _userId = widget.userId;
      _summaryFuture = _summaryService.fetch(
        memberId: widget.userId,
        createdAt: _parseCreatedAt(user['created_at']),
        memberTier: (user['member_tier'] as String?) ?? 'standard',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context
        .watch<AdminController>()
        .users
        .where((u) => u['id'] == widget.userId)
        .firstOrNull;

    return Scaffold(
      appBar: const FlexAppBar(
        title: 'Member Detail',
        showBack: true,
        backTarget: '/admin/home',
      ),
      body: user == null
          ? Center(child: Text(context.tr('User not found')))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: AvatarWidget(
                    initials: _initialsFor(user),
                    size: 64,
                  ),
                ),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChipBadge(
                      text: _capitalize(
                          (user['member_tier'] as String?) ?? 'standard'),
                      variant: ChipBadgeVariant.amber,
                    ),
                    const SizedBox(width: 8),
                    const ChipBadge(
                        text: 'Active', variant: ChipBadgeVariant.green),
                  ],
                ),
                const SizedBox(height: 12),
                DetailRow(
                  keyLabel: context.tr('Member since'),
                  value: _memberSince(_parseCreatedAt(user['created_at'])),
                ),
                FutureBuilder<MemberProfileSummary>(
                  future: _summaryFuture,
                  builder: (context, snapshot) {
                    final summary = snapshot.data;
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        summary == null) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    return Column(
                      children: [
                        DetailRow(
                          keyLabel: context.tr('Sessions done'),
                          value: '${summary?.sessionsDone ?? 0}',
                        ),
                        DetailRow(
                          keyLabel: context.tr('Sessions left'),
                          value: '${summary?.sessionsLeft ?? 0}',
                        ),
                        DetailRow(
                          keyLabel: context.tr('Payment status'),
                          value: summary?.paymentStatusLabel ?? 'Good',
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _openMessageDialog(context, user),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.sagePale,
                            foregroundColor: AppColors.sageDark),
                        child: Text(context.tr('Message')),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => context
                            .read<AdminController>()
                            .blockUser(widget.userId, true),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.redLight,
                            foregroundColor: AppColors.redDark),
                        child: Text(context.tr('Block')),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  DateTime _parseCreatedAt(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.parse(value);
    }
    return DateTime.now();
  }

  String _memberSince(DateTime createdAt) {
    return '${createdAt.year}';
  }

  String _initialsFor(Map<String, dynamic> user) {
    final first = (user['first_name'] as String?) ?? '';
    final last = (user['last_name'] as String?) ?? '';
    final initials =
        '${first.isNotEmpty ? first[0] : ''}${last.isNotEmpty ? last[0] : ''}'
            .trim();
    return initials.isEmpty ? 'M' : initials;
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }
}
