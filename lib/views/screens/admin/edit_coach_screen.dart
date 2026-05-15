import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../l10n/locale_text.dart';
import '../../../services/supabase_service.dart';
import '../../widgets/buttons.dart';
import '../../widgets/flex_app_bar.dart';
import '../../widgets/form_fields.dart';
import '../../widgets/toast_message.dart';

class EditCoachScreen extends StatefulWidget {
  final String coachId;
  const EditCoachScreen({super.key, required this.coachId});

  @override
  State<EditCoachScreen> createState() => _EditCoachScreenState();
}

class _EditCoachScreenState extends State<EditCoachScreen> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _spec = TextEditingController();
  bool _loading = false;
  List<Map<String, dynamic>> _allSessions = [];
  Set<String> _assignedSessionIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _spec.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final client = SupabaseService.instance.client;
    try {
      final profile = await client
          .from('profiles')
          .select()
          .eq('id', widget.coachId)
          .maybeSingle();
      if (profile != null) {
        _first.text = (profile['first_name'] as String?) ?? '';
        _last.text = (profile['last_name'] as String?) ?? '';
        _spec.text = (profile['speciality'] as String?) ?? '';
      }

      final sessionsRes = await client
          .from('sessions')
          .select('id,title,start_at,coach_id')
          .order('start_at', ascending: true);
      _allSessions = (sessionsRes as List).cast<Map<String, dynamic>>();
      _assignedSessionIds = _allSessions
          .where((s) => (s['coach_id'] as String?) == widget.coachId)
          .map((s) => s['id'] as String)
          .toSet();
    } catch (e) {
      if (mounted) {
        ToastMessage.show(context, context.tr('Failed to load coach data'));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _loading = true);
    final client = SupabaseService.instance.client;
    final ctx = context;
    try {
      await client.from('profiles').update({
        'first_name': _first.text.trim(),
        'last_name': _last.text.trim(),
        'speciality': _spec.text.trim(),
      }).eq('id', widget.coachId);

      for (final s in _allSessions) {
        final id = s['id'] as String;
        final shouldAssign = _assignedSessionIds.contains(id);
        final currentlyAssigned = (s['coach_id'] as String?) == widget.coachId;
        if (shouldAssign && !currentlyAssigned) {
          await client
              .from('sessions')
              .update({'coach_id': widget.coachId}).eq('id', id);
        } else if (!shouldAssign && currentlyAssigned) {
          await client.from('sessions').update({'coach_id': null}).eq('id', id);
        }
      }

      if (ctx.mounted) {
        ToastMessage.show(ctx, context.tr('Coach updated'));
        ctx.pop();
      }
    } catch (e) {
      if (ctx.mounted) {
        ToastMessage.show(ctx, context.tr('Failed to save coach'));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    setState(() => _loading = true);
    final ctx = context;
    try {
      final res = await SupabaseService.instance.client.functions
          .invoke('admin-set-user-password', body: {'user_id': widget.coachId});
      final data = res.data;
      // Log raw response for debugging
      // ignore: avoid_print
      print('admin-set-user-password response: $data');

      if (ctx.mounted) {
        if (data is Map && data['temp_password'] is String) {
          await showDialog<void>(
            context: ctx,
            builder: (dctx) => AlertDialog(
              title: Text(context.tr('Temporary password')),
              content: SelectableText(data['temp_password'] as String),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(dctx).pop(),
                    child: Text(context.tr('Close')))
              ],
            ),
          );
        } else if (data is Map && data['error'] != null) {
          ToastMessage.show(ctx, 'Password reset failed: ${data['error']}');
        } else {
          ToastMessage.show(ctx,
              'Password reset failed: unexpected response ${data ?? 'null'}');
        }
      }
    } catch (e) {
      if (ctx.mounted) {
        ToastMessage.show(ctx, 'Password reset failed: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const FlexAppBar(
          title: 'Edit Coach', showBack: true, backTarget: '/admin/home'),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.sageDark))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                FlexFormInput(
                    controller: _first,
                    hint: context.t('First name', 'Prénom')),
                const SizedBox(height: 8),
                FlexFormInput(
                    controller: _last, hint: context.t('Last name', 'Nom')),
                const SizedBox(height: 8),
                FlexFormInput(
                    controller: _spec,
                    hint: context.t('Speciality', 'Spécialité')),
                const SizedBox(height: 12),
                Text(context.tr('Assigned sessions'),
                    style: AppTextStyles.sectionLabel),
                const SizedBox(height: 8),
                ...[
                  ..._allSessions.map((s) {
                    final id = s['id'] as String;
                    final title =
                        s['title'] as String? ?? context.tr('Session');
                    final assigned = _assignedSessionIds.contains(id);
                    return CheckboxListTile(
                      value: assigned,
                      title: Text(title),
                      subtitle: Text((s['start_at'] as String?) ?? ''),
                      onChanged: (v) {
                        setState(() {
                          if (v == true) {
                            _assignedSessionIds.add(id);
                          } else {
                            _assignedSessionIds.remove(id);
                          }
                        });
                      },
                    );
                  }),
                ],
                const SizedBox(height: 12),
                FlexPrimaryButton(
                    label: context.tr('Save changes'), onPressed: _saveProfile),
                const SizedBox(height: 8),
                FlexSecondaryButton(
                    label: context.tr('Reset password'),
                    onPressed: _resetPassword),
              ],
            ),
    );
  }
}
