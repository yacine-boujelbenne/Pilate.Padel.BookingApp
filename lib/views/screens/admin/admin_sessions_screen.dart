import '../../widgets/page_layout.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../controllers/session_controller.dart';
import '../../widgets/chip_badge.dart';
import '../../widgets/state_widgets.dart';
import '../../widgets/toast_message.dart';
import '../../widgets/flex_app_bar.dart';

class AdminSessionsScreen extends StatefulWidget {
  const AdminSessionsScreen({super.key});

  @override
  State<AdminSessionsScreen> createState() => _AdminSessionsScreenState();
}

class _AdminSessionsScreenState extends State<AdminSessionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SessionController>().fetchAllSessions();
      context.read<SessionController>().fetchPendingEditRequests();
    });
  }

  Future<void> _act(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      if (mounted) {
        ToastMessage.show(
          context,
          'Could not update this session. Please try again.',
        );
      }
    }
  }

  Future<void> _cancel(String id, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel this session?'),
        content: Text('Cancel $title for everyone who has reserved a place?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep session'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cancel session'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _act(() => context.read<SessionController>().cancelSession(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionCtrl = context.watch<SessionController>();
    final sessions = sessionCtrl.sessions;
    final editRequests = sessionCtrl.editRequests;
    final sessionsById = {for (final s in sessions) s.id: s};

    String formatDateTime(dynamic value) {
      if (value == null) return '';
      final parsed = value is DateTime
          ? value
          : DateTime.tryParse(value.toString());
      if (parsed == null) return '';
      return DateFormat('yyyy-MM-dd HH:mm').format(parsed);
    }

    return Scaffold(
      appBar: const FlexAppBar(
        title: 'All Sessions',
        showBack: true,
        backTarget: '/admin/home',
      ),
      body: FlexPage(
        maxWidth: 1120,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const FlexSectionHeader(
              title: 'Set the club in motion.',
              subtitle: 'Sessions, approvals, and the people behind them.',
            ),
            if (sessionCtrl.isLoading) const LinearProgressIndicator(),
            if (sessionCtrl.error != null)
              FlexErrorCard(
                message: 'The session list could not be refreshed.',
                onRetry: sessionCtrl.fetchAllSessions,
              ),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () => context.go('/admin/sessions/new'),
                icon: const Icon(Icons.add),
                label: const Text('Add Session'),
              ),
            ),
            const SizedBox(height: 12),
            if (editRequests.isNotEmpty) ...[
              Text('EDIT REQUESTS', style: AppTextStyles.sectionLabel),
              const SizedBox(height: 8),
              ...editRequests.map((r) {
                final sessionId = r['session_id'] as String?;
                final sessionTitle = sessionId != null
                    ? sessionsById[sessionId]?.title
                    : null;
                final details = <String>[];
                if (r['proposed_title'] != null) {
                  details.add('Title: ${r['proposed_title']}');
                }
                final startAt = formatDateTime(r['proposed_start_at']);
                final endAt = formatDateTime(r['proposed_end_at']);
                if (startAt.isNotEmpty || endAt.isNotEmpty) {
                  details.add('Time: $startAt → $endAt');
                }
                if (r['proposed_max_participants'] != null) {
                  details.add(
                    'Max: ${r['proposed_max_participants'].toString()}',
                  );
                }
                if (r['proposed_price_tnd'] != null) {
                  details.add(
                    'Price: ${r['proposed_price_tnd'].toString()} TND',
                  );
                }
                if (r['proposed_level'] != null) {
                  details.add('Level: ${r['proposed_level']}');
                }

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
                        sessionTitle ?? 'Session edit request',
                        style: AppTextStyles.sessionTitle,
                      ),
                      if (details.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        ...details.map(
                          (d) => Text(d, style: AppTextStyles.sessionMeta),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ElevatedButton(
                            onPressed: sessionCtrl.isLoading
                                ? null
                                : () => _act(
                                    () => sessionCtrl.approveEditRequest(r),
                                  ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.greenLight,
                              foregroundColor: AppColors.greenDark,
                            ),
                            child: const Text('Approve'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: sessionCtrl.isLoading
                                ? null
                                : () => _act(
                                    () => sessionCtrl.rejectEditRequest(
                                      r['id'] as String,
                                    ),
                                  ),
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
            ],
            Text('ALL SESSIONS', style: AppTextStyles.sectionLabel),
            const SizedBox(height: 8),
            ...sessions.map((s) {
              final isPending = s.status == 'pending';
              final isCancelled = s.status == 'cancelled';
              final badgeVariant = isPending
                  ? ChipBadgeVariant.amber
                  : isCancelled
                  ? ChipBadgeVariant.red
                  : ChipBadgeVariant.sage;
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
                    Text(s.title, style: AppTextStyles.sessionTitle),
                    Text(
                      DateFormat('EEE d MMM · HH:mm').format(s.startAt),
                      style: AppTextStyles.sessionMeta,
                    ),
                    Text(
                      '${s.coachName} · ${s.studioName}',
                      style: AppTextStyles.sessionMeta,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${s.bookedCount}/${s.maxParticipants} participants',
                      style: AppTextStyles.sessionMeta,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ChipBadge(text: s.status, variant: badgeVariant),
                        const Spacer(),
                        if (s.bookedCount > 0)
                          TextButton.icon(
                            onPressed: () => context.go(
                              '/sessions/${s.id}/attendees',
                              extra: '/admin/sessions',
                            ),
                            icon: const Icon(Icons.people, size: 16),
                            label: const Text('Attendees'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (isPending) ...[
                          ElevatedButton(
                            onPressed: sessionCtrl.isLoading
                                ? null
                                : () => _act(
                                    () => sessionCtrl.approveSession(s.id),
                                  ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.greenLight,
                              foregroundColor: AppColors.greenDark,
                            ),
                            child: const Text('Approve'),
                          ),
                          const SizedBox(width: 8),
                        ],
                        OutlinedButton(
                          onPressed: () =>
                              context.push('/admin/sessions/${s.id}/edit'),
                          child: const Text('Edit'),
                        ),
                        if (!isCancelled) ...[
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: sessionCtrl.isLoading
                                ? null
                                : () => _cancel(s.id, s.title),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.redLight,
                              foregroundColor: AppColors.redDark,
                            ),
                            child: const Text('Cancel'),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
