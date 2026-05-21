import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/coach_controller.dart';
import '../../../controllers/session_controller.dart';
import '../../../l10n/locale_text.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/buttons.dart';
import '../../widgets/chip_badge.dart';
import '../../widgets/flex_app_bar.dart';
import '../../widgets/form_fields.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/toast_message.dart';
import '../../widgets/modern_components.dart';

class CoachHomeScreen extends StatefulWidget {
  const CoachHomeScreen({super.key});

  @override
  State<CoachHomeScreen> createState() => _CoachHomeScreenState();
}

class _CoachHomeScreenState extends State<CoachHomeScreen> {
  Future<void> _loadDashboard() async {
    final coachController = context.read<CoachController>();
    await coachController.fetchCoachSchedule();
    if (!mounted) return;
    await coachController.fetchCoachTrainees();
    if (!mounted) return;
    await coachController.fetchFillRateStats();
  }

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
          title: Text(context.t('Propose edit', 'Proposer une modification')),
          content: StatefulBuilder(
            builder: (context, setState) => SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FlexFormInput(
                      controller: titleController, hint: context.tr('Title')),
                  const SizedBox(height: 8),
                  FlexFormInput(
                      controller: dateController,
                      hint:
                          context.t('Date (YYYY-MM-DD)', 'Date (YYYY-MM-DD)')),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: FlexFormInput(
                            controller: startController,
                            hint: context.t('Start (HH:mm)', 'Début (HH:mm)')),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FlexFormInput(
                            controller: endController,
                            hint: context.t('End (HH:mm)', 'Fin (HH:mm)')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  FlexFormInput(
                      controller: maxController,
                      hint: context.t('Max participants', 'Participants max'),
                      keyboardType: TextInputType.number),
                  const SizedBox(height: 8),
                  FlexDropdown(
                    value: level,
                    items: [
                      DropdownMenuItem(
                          value: 'all', child: Text(context.tr('All levels'))),
                      DropdownMenuItem(
                          value: 'beginner',
                          child: Text(context.tr('Beginner'))),
                      DropdownMenuItem(
                          value: 'intermediate',
                          child: Text(context.tr('Intermediate'))),
                      DropdownMenuItem(
                          value: 'advanced',
                          child: Text(context.tr('Advanced'))),
                    ],
                    onChanged: (value) =>
                        setState(() => level = value ?? 'all'),
                  ),
                  const SizedBox(height: 8),
                  FlexFormInput(
                      controller: priceController,
                      hint: context.t('Price TND', 'Prix TND'),
                      keyboardType: TextInputType.number),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(context.tr('Cancel')),
            ),
            TextButton(
              onPressed: () async {
                final selectedDate =
                    DateTime.tryParse(dateController.text.trim());
                if (selectedDate == null) {
                  ToastMessage.show(context,
                      context.tr('Please enter a valid date (YYYY-MM-DD)'));
                  return;
                }

                final startParts = startController.text.trim().split(':');
                final endParts = endController.text.trim().split(':');
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
                      context, context.tr('End time must be after start time'));
                  return;
                }

                final max = int.tryParse(maxController.text.trim()) ?? 10;
                if (max <= 0) {
                  ToastMessage.show(context,
                      context.tr('Max participants must be greater than 0'));
                  return;
                }

                final price = double.tryParse(priceController.text.trim()) ?? 0;
                final sessionController = context.read<SessionController>();

                try {
                  await sessionController.proposeSessionEdit(
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
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                    ToastMessage.show(
                        dialogContext,
                        context.t('Edit request sent',
                            'Demande de modification envoyée'));
                  }
                } catch (_) {
                  if (dialogContext.mounted) {
                    final error = sessionController.error ??
                        context.t('Could not submit edit request',
                            'Impossible d’envoyer la demande de modification');
                    ToastMessage.show(dialogContext, error);
                  }
                }
              },
              child: Text(context.tr('Send')),
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
      _loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final c = context.watch<CoachController>();
    final schedule = c.schedule;
    final profile = auth.profile;
    final displayName = profile == null || profile.fullName.trim().isEmpty
        ? 'Coach'
        : profile.fullName.trim();
    final speciality = profile?.speciality?.trim().isNotEmpty == true
        ? profile!.speciality!.trim()
        : 'Coach portal';
    final initials = profile == null
        ? 'C'
        : '${profile.firstName.isNotEmpty ? profile.firstName[0] : ''}${profile.lastName.isNotEmpty ? profile.lastName[0] : ''}'
            .trim()
            .toUpperCase();

    return Scaffold(
      appBar: FlexAppBar(
        title: context.tr('Coach Portal'),
        badgeText: context.tr('Coach'),
        showBack: false,
        extraActions: [
          IconButton(
            tooltip: context.tr('Settings'),
            icon: const Icon(Icons.settings, color: AppColors.sageDark),
            onPressed: () => context.go('/settings', extra: '/coach/home'),
          ),
          IconButton(
            tooltip: context.tr('Sign out'),
            icon: const Icon(Icons.logout, color: AppColors.sageDark),
            onPressed: () async {
              await context.read<AuthController>().signOut();
              if (context.mounted) context.go('/');
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
            child: Row(
              children: [
                AvatarWidget(initials: initials, size: 52),
                SizedBox(width: 10),
                Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [Text(displayName), Text(speciality)]),
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
            children: [
              StatCard(
                  value: c.sessionsToday.toString(),
                  label: context.t('Sessions today', 'Séances du jour')),
              StatCard(
                  value: c.sessionsWeek.toString(),
                  label: context.t('Sessions week', 'Séances de la semaine')),
              StatCard(
                  value:
                      '${(c.averageFillRate * 100).clamp(0, 100).toStringAsFixed(0)}%',
                  label: context.t('Average fill', 'Taux moyen')),
              StatCard(
                  value: c.upcomingSessions.toString(),
                  label: context.tr('Upcoming')),
            ],
          ),
          const SizedBox(height: 12),
          Text(context.tr('YOUR SESSIONS'), style: AppTextStyles.sectionLabel),
          const SizedBox(height: 8),
          if (schedule.isEmpty)
            Padding(
              padding: EdgeInsets.all(12),
              child: Text(context.tr('No sessions yet')),
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
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (booked > 0)
                          TextButton.icon(
                            onPressed: () => context.go(
                              '/sessions/${item['id']}/attendees',
                              extra: '/coach/home',
                            ),
                            icon: const Icon(Icons.people, size: 16),
                            label: Text(
                                '${context.tr('View')} Attendees ($booked)'),
                          ),
                        const SizedBox(width: 8),
                        if (status == 'scheduled')
                          TextButton(
                            onPressed: () => _openEditRequestDialog(item),
                            child: Text(context.t(
                                'Propose edit', 'Proposer une modification')),
                          )
                        else if (status == 'pending')
                          Text(
                              context.t('Awaiting admin approval',
                                  'En attente de validation admin'),
                              style: AppTextStyles.sessionMeta),
                      ],
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 12),
          Text(context.tr('SESSION FILL RATE BY DAY'),
              style: AppTextStyles.sectionLabel),
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
              label: context.t('+ Create new session', '+ Créer une séance'),
              onPressed: () => context.go('/coach/sessions/new')),
        ],
      ),
    );
  }
}
