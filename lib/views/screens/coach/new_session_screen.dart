import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../controllers/auth_controller.dart';
import '../../../controllers/coach_controller.dart';
import '../../../controllers/session_controller.dart';
import '../../../services/supabase_service.dart';
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
        ToastMessage.show(context, 'Could not load studios');
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
      ToastMessage.show(context, 'Please enter a session name');
      return;
    }

    final selectedDate = DateTime.tryParse(_date.text.trim());
    if (selectedDate == null) {
      ToastMessage.show(context, 'Please enter a valid date (YYYY-MM-DD)');
      return;
    }

    final startParts = _start.text.trim().split(':');
    final endParts = _end.text.trim().split(':');
    if (startParts.length != 2 || endParts.length != 2) {
      ToastMessage.show(context, 'Please enter valid times (HH:mm)');
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
      ToastMessage.show(context, 'Please enter valid times (HH:mm)');
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
      ToastMessage.show(context, 'End time must be after start time');
      return;
    }

    final maxParticipants = int.tryParse(_max.text.trim()) ?? 10;
    if (maxParticipants <= 0) {
      ToastMessage.show(context, 'Max participants must be greater than 0');
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
      ToastMessage.show(context, 'Session sent for approval');
      _goBack();
    } catch (_) {
      if (mounted) {
        final error = context.read<SessionController>().error;
        ToastMessage.show(context, error ?? 'Could not create session');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<SessionController>().isLoading;
    return Scaffold(
      appBar: const FlexAppBar(
        title: 'Create Session',
        showBack: true,
        backTarget: '/coach/home',
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FlexFormInput(controller: _title, hint: 'Session name'),
          const SizedBox(height: 8),
          FlexFormInput(controller: _date, hint: 'Date (YYYY-MM-DD)'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child:
                      FlexFormInput(controller: _start, hint: 'Start (HH:mm)')),
              const SizedBox(width: 10),
              Expanded(
                  child: FlexFormInput(controller: _end, hint: 'End (HH:mm)')),
            ],
          ),
          const SizedBox(height: 8),
          if (_loadingStudios)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_studios.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('No studios available'),
            )
          else ...[
            const Text('Studio'),
            const SizedBox(height: 8),
            FlexDropdown(
              value: _selectedStudioId,
              items: _studios
                  .map((studio) => DropdownMenuItem<String>(
                        value: studio['id'] as String,
                        child: Text(studio['name'] as String? ?? 'Studio'),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _selectedStudioId = value),
            ),
            const SizedBox(height: 8),
          ],
          FlexFormInput(
              controller: _max,
              hint: 'Max participants',
              keyboardType: TextInputType.number),
          const SizedBox(height: 8),
          FlexDropdown(
            value: _level,
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All levels')),
              DropdownMenuItem(value: 'beginner', child: Text('Beginner')),
              DropdownMenuItem(
                  value: 'intermediate', child: Text('Intermediate')),
              DropdownMenuItem(value: 'advanced', child: Text('Advanced')),
            ],
            onChanged: (v) => setState(() => _level = v ?? 'all'),
          ),
          const SizedBox(height: 8),
          FlexFormInput(
              controller: _price,
              hint: 'Price TND',
              keyboardType: TextInputType.number),
          const SizedBox(height: 14),
          FlexPrimaryButton(
            label: loading ? 'Creating...' : 'Create session',
            onPressed: loading ? null : _createSession,
          ),
        ],
      ),
    );
  }
}
