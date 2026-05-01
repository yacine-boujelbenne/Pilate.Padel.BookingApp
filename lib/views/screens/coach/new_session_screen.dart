import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../controllers/auth_controller.dart';
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

    final selectedDate = DateTime.tryParse(_date.text.trim()) ?? DateTime.now();
    final startParts = _start.text.split(':');
    final endParts = _end.text.split(':');
    final startAt = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        int.tryParse(startParts.first) ?? 9,
        int.tryParse(startParts.last) ?? 0);
    final endAt = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        int.tryParse(endParts.first) ?? 10,
        int.tryParse(endParts.last) ?? 0);

    try {
      await context.read<SessionController>().createSession({
        'coach_id': coachId,
        'studio_id': null,
        'title': _title.text,
        'level': _level,
        'start_at': startAt.toIso8601String(),
        'end_at': endAt.toIso8601String(),
        'max_participants': int.tryParse(_max.text) ?? 10,
        'booked_count': 0,
        'price_tnd': double.tryParse(_price.text) ?? 0,
        'status': 'scheduled',
      });
      if (!mounted) return;
      ToastMessage.show(context, 'Session created! 🎉');
      context.pop();
    } catch (_) {
      if (mounted) ToastMessage.show(context, 'Could not create session');
    }
  }

  @override
  Widget build(BuildContext context) {
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
          FlexPrimaryButton(label: 'Create session', onPressed: _createSession),
        ],
      ),
    );
  }
}
