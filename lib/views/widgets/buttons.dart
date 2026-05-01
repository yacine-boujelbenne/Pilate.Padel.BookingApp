import 'package:flutter/material.dart';

import '../../app/theme.dart';

class FlexPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const FlexPrimaryButton(
      {super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.sageDark,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label, style: AppTextStyles.buttonPrimary),
      ),
    );
  }
}

class FlexSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const FlexSecondaryButton(
      {super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.sagePale,
          foregroundColor: AppColors.sageDark,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label, style: AppTextStyles.buttonSecondary),
      ),
    );
  }
}
