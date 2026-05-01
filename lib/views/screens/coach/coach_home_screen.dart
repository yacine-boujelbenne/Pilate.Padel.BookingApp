import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../controllers/coach_controller.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/buttons.dart';
import '../../widgets/chip_badge.dart';
import '../../widgets/flex_app_bar.dart';
import '../../widgets/stat_card.dart';

class CoachHomeScreen extends StatefulWidget {
  const CoachHomeScreen({super.key});

  @override
  State<CoachHomeScreen> createState() => _CoachHomeScreenState();
}

class _CoachHomeScreenState extends State<CoachHomeScreen> {
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
    return Scaffold(
      appBar: const FlexAppBar(title: 'Coach Portal', badgeText: 'Coach'),
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
          Text('TODAY\'S SCHEDULE', style: AppTextStyles.sectionLabel),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14)),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('09:00'),
                Text('Reformer A'),
                Text('8/10'),
                ChipBadge(text: 'Open', variant: ChipBadgeVariant.sage)
              ],
            ),
          ),
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
