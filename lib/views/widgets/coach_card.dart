import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'avatar_widget.dart';

class CoachCard extends StatelessWidget {
  final String name;
  final String speciality;
  final VoidCallback? onEdit;

  const CoachCard({
    super.key,
    required this.name,
    required this.speciality,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          AvatarWidget(initials: name.isNotEmpty ? name[0] : 'C', size: 44),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: AppTextStyles.body
                        .copyWith(fontWeight: FontWeight.w700)),
                Text(speciality, style: AppTextStyles.sessionMeta),
              ],
            ),
          ),
          if (onEdit != null)
            TextButton(
              onPressed: onEdit,
              child: Text(
                'Edit',
                style: AppTextStyles.buttonSecondary,
              ),
            ),
        ],
      ),
    );
  }
}
