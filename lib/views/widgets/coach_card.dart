import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'avatar_widget.dart';

class CoachCard extends StatelessWidget {
  final String name;
  final String speciality;
  final String? imageUrl;
  final VoidCallback? onEdit;
  final VoidCallback? onTap;

  const CoachCard({
    super.key,
    required this.name,
    required this.speciality,
    this.onEdit,
    this.imageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
        child: Row(
          children: [
            AvatarWidget(
              initials: name.isNotEmpty ? name[0] : 'C',
              size: 48,
              imageUrl: imageUrl,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(speciality, style: AppTextStyles.sessionMeta),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: AppColors.sageDark,
              ),
            if (onEdit != null)
              TextButton(
                onPressed: onEdit,
                child: Text('Edit', style: AppTextStyles.buttonSecondary),
              ),
          ],
        ),
      ),
    );
  }
}
