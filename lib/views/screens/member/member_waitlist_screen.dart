import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../controllers/waitlist_controller.dart';
import '../../widgets/flex_app_bar.dart';
import '../../widgets/waitlist_item.dart';

class MemberWaitlistScreen extends StatefulWidget {
  const MemberWaitlistScreen({super.key});

  @override
  State<MemberWaitlistScreen> createState() => _MemberWaitlistScreenState();
}

class _MemberWaitlistScreenState extends State<MemberWaitlistScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WaitlistController>().fetchMemberWaitlists();
    });
  }

  @override
  Widget build(BuildContext context) {
    final waitlists = context.watch<WaitlistController>().entries;

    return Scaffold(
      appBar: const FlexAppBar(title: 'My Waitlists', showBack: true),
      body: waitlists.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.notifications_none,
                      size: 48, color: AppColors.sageLight),
                  const SizedBox(height: 8),
                  Text('No waitlists yet', style: AppTextStyles.body),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('ACTIVE WAITLISTS', style: AppTextStyles.sectionLabel),
                const SizedBox(height: 8),
                ...waitlists.map(
                  (w) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: WaitlistItem(
                      entry: w,
                      onLeave: () => context
                          .read<WaitlistController>()
                          .leaveWaitlist(w.id),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
