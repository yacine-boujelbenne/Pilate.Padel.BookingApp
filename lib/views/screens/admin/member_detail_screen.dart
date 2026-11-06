import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/theme.dart';
import '../../../controllers/admin_controller.dart';
import '../../../services/member_profile_summary_service.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/buttons.dart';
import '../../widgets/chip_badge.dart';
import '../../widgets/detail_row.dart';
import '../../widgets/flex_app_bar.dart';
import '../../widgets/page_layout.dart';
import '../../widgets/state_widgets.dart';
import '../../widgets/toast_message.dart';

class MemberDetailScreen extends StatefulWidget {
  const MemberDetailScreen({super.key, required this.userId});
  final String userId;
  @override
  State<MemberDetailScreen> createState() => _MemberDetailScreenState();
}

class _MemberDetailScreenState extends State<MemberDetailScreen> {
  final _service = MemberProfileSummaryService();
  Future<MemberProfileSummary>? _summary;
  bool _loading = true, _failed = false, _saving = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final user = await context.read<AdminController>().fetchUser(
        widget.userId,
      );
      if (!mounted) return;
      if (user == null) {
        setState(() => _failed = true);
        return;
      }
      _summary = _service.fetch(
        memberId: widget.userId,
        createdAt: DateTime.parse(user['created_at'] as String),
        memberTier: user['member_tier'] as String? ?? 'standard',
      );
      // Attach the error handler before this future can fail; FutureBuilder renders it.
      _summary!.then<void>((_) {}, onError: (Object _) {});
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _block(bool blocked) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(blocked ? 'Block this member?' : 'Restore member access?'),
        content: Text(
          blocked
              ? 'This member will no longer be able to sign in.'
              : 'The member will be able to sign in again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await context.read<AdminController>().blockUser(widget.userId, blocked);
    } catch (_) {
      if (mounted) {
        ToastMessage.show(
          context,
          'Could not update member access. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context
        .watch<AdminController>()
        .users
        .where((u) => u['id'] == widget.userId)
        .firstOrNull;
    final name = '${user?['first_name'] ?? ''} ${user?['last_name'] ?? ''}'
        .trim();
    final blocked = user?['is_blocked'] == true;
    return Scaffold(
      appBar: const FlexAppBar(
        title: 'Member details',
        showBack: true,
        backTarget: '/admin/home',
      ),
      body: FlexPage(
        maxWidth: 720,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (_loading)
              const FlexLoading()
            else if (_failed || user == null)
              FlexErrorCard(
                message: 'This member could not be loaded.',
                onRetry: _load,
              )
            else ...[
              FlexSurface(
                child: Column(
                  children: [
                    AvatarWidget(
                      initials: name.isEmpty ? 'M' : name[0],
                      imageUrl: user['avatar_url'] as String?,
                      size: 72,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.modalTitle,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChipBadge(
                          text: user['member_tier'] as String? ?? 'standard',
                          variant: ChipBadgeVariant.sage,
                        ),
                        ChipBadge(
                          text: blocked ? 'Blocked' : 'Active',
                          variant: blocked
                              ? ChipBadgeVariant.red
                              : ChipBadgeVariant.green,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              DetailRow(
                keyLabel: 'Phone',
                value: user['phone'] as String? ?? 'Not provided',
              ),
              FutureBuilder<MemberProfileSummary>(
                future: _summary,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const FlexLoading();
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return FlexErrorCard(
                      message: 'Member activity could not be loaded.',
                      onRetry: _load,
                    );
                  }
                  final value = snapshot.data!;
                  return Column(
                    children: [
                      DetailRow(
                        keyLabel: 'Sessions completed',
                        value: '${value.sessionsDone}',
                      ),
                      DetailRow(
                        keyLabel: 'Upcoming sessions',
                        value: '${value.sessionsLeft}',
                      ),
                      DetailRow(
                        keyLabel: 'Payment status',
                        value: value.paymentStatusLabel,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              FlexSecondaryButton(
                label: _saving
                    ? 'Updating…'
                    : blocked
                    ? 'Restore member access'
                    : 'Block member',
                onPressed: _saving ? null : () => _block(!blocked),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
