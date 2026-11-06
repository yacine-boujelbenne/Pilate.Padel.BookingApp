import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/waitlist_controller.dart';
import '../../../models/waitlist_entry.dart';
import '../../widgets/flex_app_bar.dart';
import '../../widgets/page_layout.dart';
import '../../widgets/state_widgets.dart';
import '../../widgets/toast_message.dart';
import '../../widgets/waitlist_item.dart';

class MemberWaitlistScreen extends StatefulWidget {
  const MemberWaitlistScreen({super.key});
  @override
  State<MemberWaitlistScreen> createState() => _MemberWaitlistScreenState();
}

class _MemberWaitlistScreenState extends State<MemberWaitlistScreen> {
  final _leaving = <String>{};
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<WaitlistController>().fetchMemberWaitlists();
    });
  }

  Future<void> _leave(WaitlistEntry entry) async {
    if (_leaving.contains(entry.id)) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Leave this waitlist?'),
        content: Text(
          'You’ll give up your place for ${entry.session?.title ?? 'this session'}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Stay on waitlist'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Leave waitlist'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _leaving.add(entry.id));
    try {
      await context.read<WaitlistController>().leaveWaitlist(entry.id);
      if (mounted) ToastMessage.show(context, 'You’ve left the waitlist.');
    } catch (_) {
      if (mounted) {
        ToastMessage.show(
          context,
          'Could not leave the waitlist. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _leaving.remove(entry.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<WaitlistController>();
    return Scaffold(
      appBar: const FlexAppBar(
        title: 'My waitlists',
        showBack: true,
        backTarget: '/member/profile',
      ),
      body: FlexPage(
        maxWidth: 760,
        child: RefreshIndicator(
          onRefresh: controller.fetchMemberWaitlists,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
              const FlexSectionHeader(
                title: 'Good things are worth the wait',
                subtitle: 'Keep track of your place in the queue.',
              ),
              if (controller.isLoading && controller.entries.isEmpty)
                const FlexLoading()
              else if (controller.error != null)
                FlexErrorCard(
                  message: 'Your waitlists couldn’t be loaded.',
                  onRetry: controller.fetchMemberWaitlists,
                )
              else if (controller.entries.isEmpty)
                const FlexEmptyState(
                  icon: Icons.notifications_none_rounded,
                  text: 'No waiting, just possibilities',
                  description:
                      'When a session is full, you can join its waitlist from the schedule.',
                )
              else
                ...controller.entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: WaitlistItem(
                      entry: entry,
                      busy: _leaving.contains(entry.id),
                      onLeave: () => _leave(entry),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
