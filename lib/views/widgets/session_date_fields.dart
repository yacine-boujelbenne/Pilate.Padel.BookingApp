import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'form_fields.dart';

class SessionDateFields extends StatelessWidget {
  const SessionDateFields({
    super.key,
    required this.date,
    required this.start,
    required this.end,
  });
  final TextEditingController date, start, end;
  Future<void> _date(BuildContext context) async {
    final result = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(date.text) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (result != null) date.text = DateFormat('yyyy-MM-dd').format(result);
  }

  Future<void> _time(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final parts = controller.text.split(':');
    final hour = parts.length == 2 ? int.tryParse(parts[0]) : null;
    final minute = parts.length == 2 ? int.tryParse(parts[1]) : null;
    final result = await showTimePicker(
      context: context,
      initialTime:
          hour != null &&
              minute != null &&
              hour >= 0 &&
              hour < 24 &&
              minute >= 0 &&
              minute < 60
          ? TimeOfDay(hour: hour, minute: minute)
          : TimeOfDay.now(),
    );
    if (result != null) {
      controller.text =
          '${result.hour.toString().padLeft(2, '0')}:${result.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      FlexFormInput(
        controller: date,
        hint: 'Session date',
        readOnly: true,
        onTap: () => _date(context),
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: FlexFormInput(
              controller: start,
              hint: 'Start time',
              readOnly: true,
              onTap: () => _time(context, start),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FlexFormInput(
              controller: end,
              hint: 'End time',
              readOnly: true,
              onTap: () => _time(context, end),
            ),
          ),
        ],
      ),
    ],
  );
}
