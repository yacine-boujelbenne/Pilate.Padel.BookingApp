import 'package:flutter/material.dart';

import '../../app/theme.dart';

class AvatarWidget extends StatelessWidget {
  final String initials;
  final double size;

  const AvatarWidget({super.key, required this.initials, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
          shape: BoxShape.circle, color: AppColors.sagePale),
      alignment: Alignment.center,
      child: Text(
        initials.toUpperCase(),
        style: AppTextStyles.body
            .copyWith(fontWeight: FontWeight.w600, color: AppColors.sageDark),
      ),
    );
  }
}
