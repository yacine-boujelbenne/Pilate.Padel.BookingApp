import 'package:flutter/material.dart';
import '../../app/theme.dart';

class DetailRow extends StatelessWidget {
  const DetailRow({super.key, required this.keyLabel, required this.value});
  final String keyLabel;
  final String value;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 14),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: AppColors.sagePale)),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 320 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.4) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(keyLabel, style: AppTextStyles.sessionMeta),
              const SizedBox(height: 4),
              Text(
                value,
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Text(keyLabel, style: AppTextStyles.sessionMeta),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    ),
  );
}
