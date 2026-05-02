import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/coach_controller.dart';
import '../../../controllers/session_controller.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/buttons.dart';
import '../../widgets/chip_badge.dart';
import '../../widgets/flex_app_bar.dart';
import '../../widgets/form_fields.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/toast_message.dart';

class CoachHomeScreen extends StatefulWidget {
  const CoachHomeScreen({super.key});

  @override
  State<CoachHomeScreen> createState() => _CoachHomeScreenState();
}

class _CoachHomeScreenState extends State<CoachHomeScreen> {
  DateTime _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  ChipBadgeVariant _statusVariant(String status) {
    if (status == 'pending') return ChipBadgeVariant.amber;
    if (status == 'cancelled') return ChipBadgeVariant.red;
    return ChipBadgeVariant.sage;
  }

  Future<void> _openEditRequestDialog(Map<String, dynamic> session) async {
    final coachId = context.read<AuthController>().user?.id;
    final sessionId = session['id'] as String?;
    if (coachId == null || sessionId == null) return;

    final startAt = _parseDate(session['start_at']);
    final endAt = _parseDate(session['end_at']);

    final titleController =
        TextEditingController(text: (session['title'] as String?) ?? '');
    final dateController =
        TextEditingController(text: DateFormat('yyyy-MM-dd').format(startAt));
    final startController =
        TextEditingController(text: DateFormat('HH:mm').format(startAt));
    final endController =
        TextEditingController(text: DateFormat('HH:mm').format(endAt));
    final maxController = TextEditingController(
        text:
            ((session['max_participants'] as num?)?.toInt() ?? 10).toString());
    final priceController = TextEditingController(
        text: ((session['price_tnd'] as num?)?.toDouble() ?? 0)
            .toStringAsFixed(0));
    String level = (session['level'] as String?) ?? 'all';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Propose edit'),
          content: StatefulBuilder(
            builder: (context, setState) => SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FlexFormInput(controller: titleController, hint: 'Title'),
                  const SizedBox(height: 8),
                  FlexFormInput(
                      controller: dateController, hint: 'Date (YYYY-MM-DD)'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: FlexFormInput(
                            controller: startController, hint: 'Start (HH:mm)'),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FlexFormInput(
                            controller: endController, hint: 'End (HH:mm)'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  FlexFormInput(
                      controller: maxController,
                      hint: 'Max participants',
                      keyboardType: TextInputType.number),
                  const SizedBox(height: 8),
                  FlexDropdown(
                    value: level,
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All levels')),
                      DropdownMenuItem(
                          value: 'beginner', child: Text('Beginner')),
                      DropdownMenuItem(
                          value: 'intermediate', child: Text('Intermediate')),
                      DropdownMenuItem(
                          value: 'advanced', child: Text('Advanced')),
                    ],
                    onChanged: (value) =>
                        setState(() => level = value ?? 'all'),
                  ),
                  const SizedBox(height: 8),
                  FlexFormInput(
                      controller: priceController,
                      hint: 'Price TND',
                      keyboardType: TextInputType.number),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final selectedDate =
                    DateTime.tryParse(dateController.text.trim());
                if (selectedDate == null) {
                  ToastMessage.show(
                      context, 'Please enter a valid date (YYYY-MM-DD)');
                  return;
                }

                final startParts = startController.text.trim().split(':');
                final endParts = endController.text.trim().split(':');
                if (startParts.length != 2 || endParts.length != 2) {
                  ToastMessage.show(
                      context, 'Please enter valid times (HH:mm)');
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
                      context, 'Please enter valid times (HH:mm)');
                  return;
                }

                final start = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  startHour,
                  startMinute,
                );
                final end = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  endHour,
                  endMinute,
                );

                if (!end.isAfter(start)) {
                  ToastMessage.show(
                      context, 'End time must be after start time');
                  return;
                }

                final max = int.tryParse(maxController.text.trim()) ?? 10;
                if (max <= 0) {
                  ToastMessage.show(
                      context, 'Max participants must be greater than 0');
                  return;
                }

                final price = double.tryParse(priceController.text.trim()) ?? 0;

                try {
                  await context.read<SessionController>().proposeSessionEdit(
                    sessionId: sessionId,
                    coachId: coachId,
                    changes: {
                      'proposed_title': titleController.text.trim(),
                      'proposed_start_at': start.toIso8601String(),
                      'proposed_end_at': end.toIso8601String(),
                      'proposed_max_participants': max,
                      'proposed_price_tnd': price,
                      'proposed_level': level,
                    },
                  );
                  if (!mounted) return;
                  Navigator.of(dialogContext).pop();
                  ToastMessage.show(context, 'Edit request sent');
                } catch (_) {
                  if (mounted) {
                    final error = context.read<SessionController>().error ??
                        'Could not submit edit request';
                    ToastMessage.show(context, error);
                  }
                }
              },
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CoachController>().fetchCoachSchedule();
      context.read<CoachController>().fetchCoachTrainees();
      context.read<CoachController>().fetchFillRateStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<CoachController>();
    final schedule = c.schedule;

    return Scaffold(
      appBar: FlexAppBar(
        title: 'Coach Portal',
        badgeText: 'Coach',
        extraActions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings, color: AppColors.sageDark),
            onPressed: () => context.go('/settings'),
          ),
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout, color: AppColors.sageDark),
            onPressed: () async {
              await context.read<AuthController>().signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16)),
            child: const Row(
              children: [
                AvatarWidget(initials: 'CB', size: 52),
                SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Coach Ben Ali'),
                  Text('Reformer Specialist')
                ]),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: const [
              StatCard(value: '4', label: 'Sessions today'),
              StatCard(value: '18', label: 'Sessions week'),
              StatCard(value: '79%', label: 'Fill rate'),
              StatCard(value: '4.9', label: 'Rating'),
            ],
          ),
          const SizedBox(height: 12),
          Text('YOUR SESSIONS', style: AppTextStyles.sectionLabel),
          const SizedBox(height: 8),
          if (schedule.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('No sessions yet'),
            )
          else
            ...schedule.map((item) {
              final startAt = _parseDate(item['start_at']);
              final endAt = _parseDate(item['end_at']);
              final status = (item['status'] as String?) ?? 'scheduled';
              final booked = (item['booked_count'] as num?)?.toInt() ?? 0;
              final max = (item['max_participants'] as num?)?.toInt() ?? 0;
              final timeRange =
                  '${DateFormat('HH:mm').format(startAt)} - ${DateFormat('HH:mm').format(endAt)}';
              final title = (item['title'] as String?) ?? 'Session';
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(14)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: AppTextStyles.body),
                              const SizedBox(height: 2),
                              Text(timeRange, style: AppTextStyles.sessionMeta),
                            ],
                          ),
                        ),
                        Text('$booked/$max', style: AppTextStyles.sessionMeta),
                        const SizedBox(width: 8),
                        ChipBadge(
                            text: status, variant: _statusVariant(status)),
                      ],
                    ),
                    if (status == 'scheduled')
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => _openEditRequestDialog(item),
                          child: const Text('Propose edit'),
                        ),
                      )
                    else if (status == 'pending')
                      Text('Awaiting admin approval',
                          style: AppTextStyles.sessionMeta),
                  ],
                ),
              );
            }),
          const SizedBox(height: 12),
          Text('SESSION FILL RATE BY DAY', style: AppTextStyles.sectionLabel),
          const SizedBox(height: 8),
          Container(
            height: 120,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14)),
            child: BarChart(
              BarChartData(
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        const labels = ['M', 'T', 'W', 'T', 'F'];
                        return Text(labels[value.toInt()],
                            style: AppTextStyles.navLabel
                                .copyWith(color: AppColors.sage));
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(c.fillRates.length, (i) {
                  return BarChartGroupData(x: i, barRods: [
                    BarChartRodData(
                      toY: c.fillRates[i] * 100,
                      width: 16,
                      borderRadius: BorderRadius.circular(4),
                      color: i == DateTime.now().weekday - 1
                          ? AppColors.sageDark
                          : AppColors.sage,
                    ),
                  ]);
                }),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FlexPrimaryButton(
              label: '+ Create new session',
              onPressed: () => context.go('/coach/sessions/new')),
        ],
      ),
    );
  }
}
