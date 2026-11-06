import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../app/theme.dart';
import '../../../controllers/auth_controller.dart';
import '../../../services/session_notification_service.dart';
import '../../../services/supabase_service.dart';
import '../../widgets/flex_app_bar.dart';
import '../../widgets/page_layout.dart';
import '../../widgets/state_widgets.dart';
import '../../widgets/toast_message.dart';

class MemberNotificationsScreen extends StatefulWidget {
  const MemberNotificationsScreen({super.key});
  @override
  State<MemberNotificationsScreen> createState() =>
      _MemberNotificationsScreenState();
}

class _MemberNotificationsScreenState extends State<MemberNotificationsScreen> {
  final _service = SessionNotificationService();
  List<Map<String, dynamic>> _items = [];
  final _saving = <String>{};
  RealtimeChannel? _channel;
  bool _loading = true;
  bool _failed = false;
  int _request = 0;
  @override
  void initState() {
    super.initState();
    final uid = context.read<AuthController>().user?.id;
    if (uid != null) {
      _channel =
          SupabaseService.instance.client.channel('member-notifications-$uid')
            ..onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'notifications',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'member_id',
                value: uid,
              ),
              callback: (_) => _load(),
            )
            ..subscribe();
    }
    _load();
  }

  Future<void> _load() async {
    final uid = context.read<AuthController>().user?.id;
    if (uid == null) return;
    final request = ++_request;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final items = await _service.fetchUserNotifications(uid);
      if (mounted && request == _request) setState(() => _items = items);
    } catch (_) {
      if (mounted && request == _request) setState(() => _failed = true);
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  Future<void> _read(Map<String, dynamic> item) async {
    final id = item['id'] as String;
    if (item['is_read'] == true || !_saving.add(id)) return;
    setState(() {});
    try {
      await _service.markAsRead(id);
      if (mounted) setState(() => item['is_read'] = true);
    } catch (_) {
      if (mounted) {
        ToastMessage.show(
          context,
          'Could not update this notification. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving.remove(id));
    }
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const FlexAppBar(
      title: 'Your club updates',
      showBack: true,
      backTarget: '/member/home',
    ),
    body: FlexPage(
      maxWidth: 760,
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            const FlexSectionHeader(
              title: 'Stay in the loop',
              subtitle: 'Updates about your sessions and reservations.',
            ),
            if (_loading && _items.isEmpty)
              const FlexLoading()
            else if (_failed)
              FlexErrorCard(
                message: 'Updates couldn’t be refreshed.',
                onRetry: _load,
              )
            else if (_items.isEmpty)
              const FlexEmptyState(
                icon: Icons.notifications_none_rounded,
                text: 'You’re all caught up',
                description: 'New club updates will appear here.',
              ),
            ..._items.map((item) {
              final read = item['is_read'] == true;
              final date = DateTime.tryParse(
                item['created_at']?.toString() ?? '',
              )?.toLocal();
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: FlexSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            read
                                ? Icons.notifications_none_rounded
                                : Icons.notifications_active_outlined,
                            color: AppColors.sageDark,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item['title'] as String? ?? 'Club update',
                              style: AppTextStyles.sessionTitle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        item['body'] as String? ?? '',
                        style: AppTextStyles.body,
                      ),
                      if (date != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          DateFormat('d MMM · HH:mm').format(date),
                          style: AppTextStyles.sessionMeta,
                        ),
                      ],
                      if (!read)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _saving.contains(item['id'])
                                ? null
                                : () => _read(item),
                            child: const Text('Mark as read'),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    ),
  );
}
