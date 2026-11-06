import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../app/theme.dart';

class CalendarRow extends StatelessWidget {
  const CalendarRow({
    super.key,
    required this.selectedDate,
    required this.onSelected,
  });
  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelected;
  @override
  Widget build(BuildContext context) {
    final now = DateUtils.dateOnly(DateTime.now());
    final offset = DateUtils.dateOnly(selectedDate).difference(now).inDays;
    final start = DateTime(
      now.year,
      now.month,
      now.day + (offset < 0 ? 0 : offset ~/ 7 * 7),
    );
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return SizedBox(
      height: 84 + (scale - 1).clamp(0, 2) * 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final day = DateTime(start.year, start.month, start.day + index);
          final active = DateUtils.isSameDay(day, selectedDate);
          return Semantics(
            button: true,
            selected: active,
            label: DateFormat('EEEE d MMMM').format(day),
            child: InkWell(
              onTap: () => onSelected(day),
              borderRadius: BorderRadius.circular(18),
              child: AnimatedContainer(
                duration: AppMotion.duration(context, AppMotion.standard),
                width: 64 + (scale - 1).clamp(0, 2) * 12,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: active ? AppColors.sageDark : AppColors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: active ? AppColors.sageDark : AppColors.sagePale,
                  ),
                ),
                child: ExcludeSemantics(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('EEE').format(day),
                        style: AppTextStyles.chip.copyWith(
                          color: active ? AppColors.white : AppColors.textMid,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${day.day}',
                        style: AppTextStyles.sessionTitle.copyWith(
                          color: active ? AppColors.white : AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
