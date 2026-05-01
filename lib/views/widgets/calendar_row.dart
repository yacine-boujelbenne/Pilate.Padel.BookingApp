import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';

class CalendarRow extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelected;

  const CalendarRow({
    super.key,
    required this.selectedDate,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List<DateTime>.generate(7, (i) => now.add(Duration(days: i)));
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final day = days[index];
          final active = DateUtils.isSameDay(day, selectedDate);
          return InkWell(
            onTap: () => onSelected(day),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 60,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: active ? AppColors.sageDark : AppColors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: active ? AppColors.sageDark : AppColors.sagePale),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE').format(day).toUpperCase(),
                    style: AppTextStyles.chip.copyWith(
                      color: active ? AppColors.white : AppColors.sage,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('d').format(day),
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: active ? AppColors.white : AppColors.sageDark,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
