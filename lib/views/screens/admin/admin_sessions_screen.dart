import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final sessions = context.watch<SessionController>().sessions;
    return Scaffold(
      appBar: const FlexAppBar(title: 'All Sessions', showBack: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('THIS WEEK', style: AppTextStyles.sectionLabel),
          const SizedBox(height: 8),
          ...sessions.map(
            (s) => Container(
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
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ChipBadge(
                          text: s.status,
                          variant: s.status == 'cancelled'
                              ? ChipBadgeVariant.red
                              : ChipBadgeVariant.sage),
                      const Spacer(),
                      OutlinedButton(
                          onPressed: () =>
                              context.go('/admin/sessions/${s.id}/edit'),
                          child: const Text('Edit')),
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
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
