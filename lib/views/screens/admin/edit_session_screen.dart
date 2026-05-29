import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../controllers/session_controller.dart';
import '../../../l10n/locale_text.dart';
import '../../widgets/buttons.dart';
import '../../widgets/flex_app_bar.dart';
import '../../widgets/form_fields.dart';

class EditSessionScreen extends StatefulWidget {
  final String sessionId;

  const EditSessionScreen({super.key, required this.sessionId});

  @override
  State<EditSessionScreen> createState() => _EditSessionScreenState();
}

class _EditSessionScreenState extends State<EditSessionScreen> {
  final _title = TextEditingController();
  final _date = TextEditingController();
  final _start = TextEditingController();
  final _end = TextEditingController();
  final _capacity = TextEditingController();
  final _level = TextEditingController();
  final _price = TextEditingController();
  bool _loadingSession = true;

  void _goBack() {
    if (GoRouter.of(context).canPop()) {
      context.pop();
      return;
    }
    context.go('/admin/sessions');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSession();
    });
  }

  Future<void> _loadSession() async {
    try {
      final controller = context.read<SessionController>();
      if (controller.allSessions.isEmpty) {
        await controller.fetchAllSessions();
      }

      final session = controller.allSessions
          .where((s) => s.id == widget.sessionId)
          .firstOrNull;

      if (session == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr('Session not found'))),
          );
          _goBack();
        }
        return;
      }

      setState(() {
        _title.text = session.title;
        _date.text = DateFormat('yyyy-MM-dd').format(session.startAt);
        _start.text = DateFormat('HH:mm').format(session.startAt);
        _end.text = DateFormat('HH:mm').format(session.endAt);
        _capacity.text = session.maxParticipants.toString();
        _level.text = session.level;
        _price.text = session.priceTnd.toString();
        _loadingSession = false;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('Could not load session'))),
        );
        _goBack();
      }
    }
  }

  Future<void> _pickDate() async {
    final initialDate = DateTime.tryParse(_date.text.trim()) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked == null) return;
    setState(() {
      _date.text = DateFormat('yyyy-MM-dd').format(picked);
    });
  }

  Future<void> _pickTime(TextEditingController controller) async {
    final current = _parseTime(controller.text) ?? TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
    );
    if (picked == null) return;
    setState(() {
      controller.text = _formatTimeOfDay(picked);
    });
  }

  TimeOfDay? _parseTime(String value) {
    final parts = value.trim().split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatTimeOfDay(TimeOfDay timeOfDay) {
    return '${timeOfDay.hour.toString().padLeft(2, '0')}:${timeOfDay.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _title.dispose();
    _date.dispose();
    _start.dispose();
    _end.dispose();
    _capacity.dispose();
    _level.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final selectedDate = DateTime.tryParse(_date.text.trim());
    if (selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Please select a valid date'))),
      );
      return;
    }

    final startParts = _start.text.trim().split(':');
    final endParts = _end.text.trim().split(':');
    if (startParts.length != 2 || endParts.length != 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Please select valid times'))),
      );
      return;
    }

    final startHour = int.tryParse(startParts[0]);
    final startMinute = int.tryParse(startParts[1]);
    final endHour = int.tryParse(endParts[0]);
    final endMinute = int.tryParse(endParts[1]);
    if (startHour == null || startMinute == null || endHour == null || endMinute == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Please select valid times'))),
      );
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

    final capacity = int.tryParse(_capacity.text.trim());
    if (capacity == null || capacity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t('Please enter a valid capacity', 'Veuillez saisir une capacité valide'))),
      );
      return;
    }

    if (!endAt.isAfter(startAt)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('End time must be after start time'))),
      );
      return;
    }

    await context.read<SessionController>().updateSession(widget.sessionId, {
      'title': _title.text,
      'level': _level.text,
      'max_participants': capacity,
      'start_at': startAt.toIso8601String(),
      'end_at': endAt.toIso8601String(),
      'price_tnd': double.tryParse(_price.text) ?? 0,
    });
    if (!mounted) return;
    _goBack();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingSession) {
      return Scaffold(
        appBar: FlexAppBar(
          title: context.tr('Edit Session'),
          showBack: true,
          backTarget: '/admin/sessions',
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: FlexAppBar(
        title: context.tr('Edit Session'),
        showBack: true,
        backTarget: '/admin/sessions',
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FlexFormInput(controller: _title, hint: context.tr('Title')),
          const SizedBox(height: 8),
          FlexFormInput(
            controller: _date,
            hint: context.tr('Select date (YYYY-MM-DD)'),
            readOnly: true,
            onTap: _pickDate,
            suffixIcon: IconButton(
              icon: const Icon(Icons.calendar_month),
              onPressed: _pickDate,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FlexFormInput(
                  controller: _start,
                  hint: context.t('Start (HH:mm)', 'Début (HH:mm)'),
                  readOnly: true,
                  onTap: () => _pickTime(_start),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.schedule),
                    onPressed: () => _pickTime(_start),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FlexFormInput(
                  controller: _end,
                  hint: context.t('End (HH:mm)', 'Fin (HH:mm)'),
                  readOnly: true,
                  onTap: () => _pickTime(_end),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.schedule),
                    onPressed: () => _pickTime(_end),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FlexFormInput(
            controller: _capacity,
            hint: context.t('Capacity', 'Capacité'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 8),
          FlexFormInput(controller: _level, hint: context.tr('Level')),
          const SizedBox(height: 8),
          FlexFormInput(
              controller: _price, hint: context.t('Price TND', 'Prix TND')),
          const SizedBox(height: 12),
          FlexPrimaryButton(
              label: context.tr('Save changes'), onPressed: _save),
        ],
      ),
    );
  }
}
