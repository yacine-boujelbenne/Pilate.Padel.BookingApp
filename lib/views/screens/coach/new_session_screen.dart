import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../controllers/auth_controller.dart';
import '../../../controllers/coach_controller.dart';
import '../../../controllers/session_controller.dart';
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

  String _studio = 'Studio A';
  String _level = 'all';

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
        'studio_id': null,
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
      context.pop();
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
      appBar: const FlexAppBar(title: 'Create Session', showBack: true),
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
          FlexDropdown(
            value: _studio,
            items: const [
              DropdownMenuItem(value: 'Studio A', child: Text('Studio A')),
              DropdownMenuItem(value: 'Studio B', child: Text('Studio B')),
            ],
            onChanged: (v) => setState(() => _studio = v ?? 'Studio A'),
          ),
          const SizedBox(height: 8),
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
