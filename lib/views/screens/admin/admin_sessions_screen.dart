import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../controllers/session_controller.dart';
import '../../widgets/chip_badge.dart';
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

  @override
  Widget build(BuildContext context) {
    final sessionCtrl = context.watch<SessionController>();
    final sessions = sessionCtrl.sessions;
    final editRequests = sessionCtrl.editRequests;
    final sessionsById = {for (final s in sessions) s.id: s};

    String formatDateTime(dynamic value) {
      if (value == null) return '';
      final parsed =
          value is DateTime ? value : DateTime.tryParse(value.toString());
      if (parsed == null) return '';
      return DateFormat('yyyy-MM-dd HH:mm').format(parsed);
    }

    return Scaffold(
      appBar: const FlexAppBar(
        title: 'All Sessions',
        showBack: true,
        backTarget: '/admin/home',
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
              final sessionTitle =
                  sessionId != null ? sessionsById[sessionId]?.title : null;
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
                details
                    .add('Max: ${r['proposed_max_participants'].toString()}');
              }
              if (r['proposed_price_tnd'] != null) {
                details.add('Price: ${r['proposed_price_tnd'].toString()} TND');
              }
              if (r['proposed_level'] != null) {
                details.add('Level: ${r['proposed_level']}');
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sessionTitle ?? 'Session edit request',
                        style: AppTextStyles.sessionTitle),
                    if (details.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      ...details.map(
                          (d) => Text(d, style: AppTextStyles.sessionMeta)),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () => sessionCtrl.approveEditRequest(r),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.greenLight,
                              foregroundColor: AppColors.greenDark),
                          child: const Text('Approve'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () =>
                              sessionCtrl.rejectEditRequest(r['id'] as String),
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
          ],
          Text('THIS WEEK', style: AppTextStyles.sectionLabel),
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
                  borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.title, style: AppTextStyles.sessionTitle),
                  Text('${s.coachName} · ${s.studioName}',
                      style: AppTextStyles.sessionMeta),
                  const SizedBox(height: 4),
                  Text('${s.bookedCount}/${s.maxParticipants} participants',
                      style: AppTextStyles.sessionMeta),
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
                  Row(
                    children: [
                      if (isPending) ...[
                        ElevatedButton(
                          onPressed: () => context
                              .read<SessionController>()
                              .approveSession(s.id),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.greenLight,
                              foregroundColor: AppColors.greenDark),
                          child: const Text('Approve'),
                        ),
                        const SizedBox(width: 8),
                      ],
                      OutlinedButton(
                          onPressed: () =>
                              context.push('/admin/sessions/${s.id}/edit'),
                          child: const Text('Edit')),
                      if (!isCancelled) ...[
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => context
                              .read<SessionController>()
                              .cancelSession(s.id),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.redLight,
                              foregroundColor: AppColors.redDark),
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
    );
  }
}
