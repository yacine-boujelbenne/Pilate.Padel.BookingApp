import 'package:flutter/material.dart';

import '../../app/theme.dart';

class DetailRow extends StatelessWidget {
  final String keyLabel;
  final String value;

  const DetailRow({super.key, required this.keyLabel, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.sagePale)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(keyLabel,
              style: AppTextStyles.body.copyWith(color: AppColors.sage)),
          Text(value,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
