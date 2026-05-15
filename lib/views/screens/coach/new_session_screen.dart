import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../controllers/auth_controller.dart';
import '../../../controllers/coach_controller.dart';
import '../../../controllers/session_controller.dart';
import '../../../services/supabase_service.dart';
import '../../../l10n/locale_text.dart';
import '../../widgets/buttons.dart';
import '../../widgets/flex_app_bar.dart';
import '../../widgets/form_fields.dart';
import '../../widgets/toast_message.dart';

class NewSessionScreen extends StatefulWidget {
  const NewSessionScreen({super.key});

  @override
  State<NewSessionScreen> createState() => _NewSessionScreenState();
}

class _NewSessionScreenState extends State<NewSessionScreen> {
  final _title = TextEditingController();
  final _date = TextEditingController();
  final _start = TextEditingController();
  final _end = TextEditingController();
  final _max = TextEditingController(text: '10');
  final _price = TextEditingController();

  String? _selectedStudioId;
  List<Map<String, dynamic>> _studios = [];
  bool _loadingStudios = false;
  String _level = 'all';

  @override
  void initState() {
    super.initState();
    _loadStudios();
  }

  Future<void> _loadStudios() async {
    setState(() => _loadingStudios = true);
    try {
      final res = await SupabaseService.instance.client
          .from('studios')
          .select('id, name')
          .order('name');
      _studios = (res as List).cast<Map<String, dynamic>>();
      if (_studios.isNotEmpty) {
        _selectedStudioId = _studios.first['id'] as String?;
      }
    } catch (_) {
      if (mounted) {
        ToastMessage.show(context, context.tr('Could not load studios'));
      }
    } finally {
      if (mounted) {
        setState(() => _loadingStudios = false);
      }
    }
  }

  void _goBack() {
    if (GoRouter.of(context).canPop()) {
      context.pop();
      return;
    }
    context.go('/coach/home');
  }

  @override
  void dispose() {
    _title.dispose();
    _date.dispose();
    _start.dispose();
    _end.dispose();
    _max.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _createSession() async {
    final coachId = context.read<AuthController>().user?.id;
    if (coachId == null) return;

    if (_title.text.trim().isEmpty) {
      ToastMessage.show(context, context.tr('Please enter a session name'));
      return;
    }

    final selectedDate = DateTime.tryParse(_date.text.trim());
    if (selectedDate == null) {
      ToastMessage.show(
          context, context.tr('Please enter a valid date (YYYY-MM-DD)'));
      return;
    }

    final startParts = _start.text.trim().split(':');
    final endParts = _end.text.trim().split(':');
    if (startParts.length != 2 || endParts.length != 2) {
      ToastMessage.show(
          context, context.tr('Please enter valid times (HH:mm)'));
      return;
    }

    final startHour = int.tryParse(startParts[0]);
    final startMinute = int.tryParse(startParts[1]);
    final endHour = int.tryParse(endParts[0]);
    final endMinute = int.tryParse(endParts[1]);
    if (startHour == null ||
        startMinute == null ||
        endHour == null ||
        endMinute == null) {
      ToastMessage.show(
          context, context.tr('Please enter valid times (HH:mm)'));
      return;
    }

    final startAt = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      startHour,
      startMinute,
    );
    final endAt = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      endHour,
      endMinute,
    );

    if (!endAt.isAfter(startAt)) {
      ToastMessage.show(
          context, context.tr('End time must be after start time'));
      return;
    }

    final maxParticipants = int.tryParse(_max.text.trim()) ?? 10;
    if (maxParticipants <= 0) {
      ToastMessage.show(
          context, context.tr('Max participants must be greater than 0'));
      return;
    }

    final price = double.tryParse(_price.text.trim()) ?? 0;

    try {
      await context.read<SessionController>().createSession({
        'coach_id': coachId,
        'studio_id': _selectedStudioId,
        'title': _title.text,
        'level': _level,
        'start_at': startAt.toIso8601String(),
        'end_at': endAt.toIso8601String(),
        'max_participants': maxParticipants,
        'booked_count': 0,
        'price_tnd': price,
        'status': 'pending',
      });
      if (!mounted) return;
      await context.read<CoachController>().fetchCoachSchedule();
      if (!mounted) return;
      ToastMessage.show(context, context.tr('Session sent for approval'));
      _goBack();
    } catch (_) {
      if (mounted) {
        final error = context.read<SessionController>().error;
        ToastMessage.show(
            context, error ?? context.tr('Could not create session'));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<SessionController>().isLoading;
    return Scaffold(
      appBar: FlexAppBar(
        title: context.tr('Create Session'),
        showBack: true,
        backTarget: '/coach/home',
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FlexFormInput(controller: _title, hint: context.tr('Session name')),
          const SizedBox(height: 8),
          FlexFormInput(
              controller: _date, hint: context.tr('Date (YYYY-MM-DD)')),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: FlexFormInput(
                      controller: _start,
                      hint: context.t('Start (HH:mm)', 'Début (HH:mm)'))),
              const SizedBox(width: 10),
              Expanded(
                  child: FlexFormInput(
                      controller: _end,
                      hint: context.t('End (HH:mm)', 'Fin (HH:mm)'))),
            ],
          ),
          const SizedBox(height: 8),
          if (_loadingStudios)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_studios.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(context.tr('No studios available')),
            )
          else ...[
            Text(context.tr('Studio')),
            const SizedBox(height: 8),
            FlexDropdown(
              value: _selectedStudioId,
              items: _studios
                  .map((studio) => DropdownMenuItem<String>(
                        value: studio['id'] as String,
                        child: Text(
                            studio['name'] as String? ?? context.tr('Studio')),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _selectedStudioId = value),
            ),
            const SizedBox(height: 8),
          ],
          FlexFormInput(
              controller: _max,
              hint: context.t('Max participants', 'Participants max'),
              keyboardType: TextInputType.number),
          const SizedBox(height: 8),
          FlexDropdown(
            value: _level,
            items: [
              DropdownMenuItem(
                  value: 'all', child: Text(context.tr('All levels'))),
              DropdownMenuItem(
                  value: 'beginner', child: Text(context.tr('Beginner'))),
              DropdownMenuItem(
                  value: 'intermediate',
                  child: Text(context.tr('Intermediate'))),
              DropdownMenuItem(
                  value: 'advanced', child: Text(context.tr('Advanced'))),
            ],
            onChanged: (v) => setState(() => _level = v ?? 'all'),
          ),
          const SizedBox(height: 8),
          FlexFormInput(
              controller: _price,
              hint: context.t('Price TND', 'Prix TND'),
              keyboardType: TextInputType.number),
          const SizedBox(height: 14),
          FlexPrimaryButton(
            label: loading
                ? context.tr('Creating...')
                : context.tr('Create session'),
            onPressed: loading ? null : _createSession,
          ),
        ],
      ),
    );
  }
}
