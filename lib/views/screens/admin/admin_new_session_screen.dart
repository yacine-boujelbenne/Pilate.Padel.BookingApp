import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/locale_text.dart';
import '../../../services/supabase_service.dart';
import '../../../controllers/session_controller.dart';
import '../../widgets/buttons.dart';
import '../../widgets/flex_app_bar.dart';
import '../../widgets/form_fields.dart';
import '../../widgets/toast_message.dart';

class AdminNewSessionScreen extends StatefulWidget {
  const AdminNewSessionScreen({super.key});

  @override
  State<AdminNewSessionScreen> createState() => _AdminNewSessionScreenState();
}

class _AdminNewSessionScreenState extends State<AdminNewSessionScreen> {
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
  String? _selectedCoachId;
  List<Map<String, dynamic>> _coaches = [];
  bool _loadingCoaches = false;

  @override
  void initState() {
    super.initState();
    _loadCoaches();
    _loadStudios();
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

  Future<void> _loadCoaches() async {
    setState(() => _loadingCoaches = true);
    try {
      final res = await SupabaseService.instance.client
          .from('profiles')
          .select('id, first_name, last_name')
          .eq('role', 'coach')
          .order('first_name');
      _coaches = (res as List).cast<Map<String, dynamic>>();
      if (_coaches.isNotEmpty) {
        _selectedCoachId = _coaches.first['id'] as String?;
      }
    } catch (e) {
      if (mounted) {
        ToastMessage.show(context, context.tr('Could not load coaches'));
      }
    } finally {
      setState(() => _loadingCoaches = false);
    }
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
    } catch (e) {
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
    context.go('/admin/sessions');
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

  Future<void> _createSession() async {
    if (_selectedCoachId == null) {
      ToastMessage.show(context, context.tr('Please select a coach'));
      return;
    }

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
        'coach_id': _selectedCoachId,
        'studio_id': _selectedStudioId,
        'title': _title.text.trim(),
        'level': _level,
        'start_at': startAt.toIso8601String(),
        'end_at': endAt.toIso8601String(),
        'max_participants': maxParticipants,
        'booked_count': 0,
        'price_tnd': price,
        'status': 'scheduled',
      });
      if (!mounted) return;
      // Ensure admin sessions list is refreshed and navigate back
      await context.read<SessionController>().fetchAllSessions();
      if (!mounted) return;
      ToastMessage.show(context, context.tr('Session created'));
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
        title: context.tr('Create Session (Admin)'),
        showBack: true,
        backTarget: '/admin/sessions',
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_loadingCoaches)
            const Center(child: CircularProgressIndicator())
          else ...[
            if (_coaches.isEmpty)
              Padding(
                padding: EdgeInsets.all(12),
                child: Text(context.tr('No coaches available')),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.tr('Assign Coach')),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCoachId,
                    items: _coaches
                        .map((c) => DropdownMenuItem(
                              value: c['id'] as String,
                              child: Text(
                                  '${c['first_name'] ?? ''} ${c['last_name'] ?? ''}'),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCoachId = v),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
          ],
          FlexFormInput(controller: _title, hint: context.tr('Session name')),
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
