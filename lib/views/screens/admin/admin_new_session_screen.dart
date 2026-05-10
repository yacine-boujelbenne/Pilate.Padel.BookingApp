import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../services/supabase_service.dart';
import '../../../controllers/session_controller.dart';
import '../../../controllers/admin_controller.dart';
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
  String _level = 'all';
  String? _selectedCoachId;
  List<Map<String, dynamic>> _coaches = [];
  List<Map<String, dynamic>> _studios = [];
  bool _loadingCoaches = false;
  bool _loadingStudios = false;

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
    if (mounted) setState(() => _loadingCoaches = true);
    try {
      final res = await SupabaseService.instance.client
          .from('profiles')
          .select('id, first_name, last_name, role, speciality')
          .limit(1000)  // Prevent full table scan
          ; // No server-side order to avoid timeout
      
      final allProfiles = (res as List).cast<Map<String, dynamic>>();
      // Sort client-side if needed
      allProfiles.sort((a, b) {
        final aName = ((a['first_name'] as String?) ?? '').toLowerCase();
        final bName = ((b['first_name'] as String?) ?? '').toLowerCase();
        return aName.compareTo(bName);
      });
      print('DEBUG: Total profiles loaded: ${allProfiles.length}');
      
      // Filter coaches with case-insensitive comparison
      _coaches = allProfiles
          .where((p) {
            final role = (p['role'] as String?)?.toLowerCase().trim();
            print('DEBUG: Profile role: $role');
            return role == 'coach';
          })
          .toList();
      
      print('DEBUG: Coaches found: ${_coaches.length}');
      
      if (_coaches.isNotEmpty) {
        _selectedCoachId = _coaches.first['id'] as String?;
      }
    } catch (e, stackTrace) {
      print('ERROR loading coaches: $e\n$stackTrace');
      if (mounted) {
        ToastMessage.show(context, 'Could not load coaches: $e');
      }
    } finally {
      if (mounted) setState(() => _loadingCoaches = false);
    }
  }

  Future<void> _loadStudios() async {
    if (mounted) setState(() => _loadingStudios = true);
    try {
      final res = await SupabaseService.instance.client
          .from('studios')
          .select('id, name')
          .limit(1000)  // Prevent full table scan
          ; // No server-side order to avoid timeout
      _studios = (res as List).cast<Map<String, dynamic>>();
      print('DEBUG: Studios loaded: ${_studios.length}');
      print('DEBUG: Studios data: $_studios');
      if (_studios.isNotEmpty) {
        _selectedStudioId = _studios.first['id'] as String?;
      }
    } catch (e, stackTrace) {
      print('ERROR loading studios: $e\n$stackTrace');
      if (mounted) ToastMessage.show(context, 'Could not load studios: $e');
    } finally {
      if (mounted) setState(() => _loadingStudios = false);
    }
  }

  void _goBack() {
    context.go('/admin/sessions');
  }

  Future<void> _createSession() async {
    if (_selectedCoachId == null) {
      ToastMessage.show(context, 'Please select a coach');
      return;
    }

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
      ToastMessage.show(context, 'Session created');
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
        title: 'Create Session (Admin)',
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'No coaches found',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'To create a session, you need at least one coach account. '
                      'Coaches can sign up through the app or be created via database.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Assign Coach'),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    value: _selectedCoachId,
                    isExpanded: true,
                    items: _coaches
                        .map((c) => DropdownMenuItem(
                              value: c['id'] as String,
                              child: Text(
                                  '${c['first_name'] ?? ''} ${c['last_name'] ?? ''} - ${c['speciality'] ?? 'N/A'}'),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCoachId = v),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
          ],

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
            const Center(child: CircularProgressIndicator())
          else if (_studios.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange, width: 1),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No studios found',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'At least one studio needs to be created in the database.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select Studio'),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  value: _selectedStudioId,
                  isExpanded: true,
                  items: _studios
                      .map((s) => DropdownMenuItem(
                            value: s['id'] as String,
                            child: Text(s['name'] as String),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedStudioId = v),
                ),
                const SizedBox(height: 12),
              ],
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
