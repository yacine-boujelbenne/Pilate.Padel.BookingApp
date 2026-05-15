import 'package:flutter/material.dart';

import '../../app/theme.dart';

class FlexPrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;

  const FlexPrimaryButton(
      {super.key, required this.label, required this.onPressed});

  @override
  State<FlexPrimaryButton> createState() => _FlexPrimaryButtonState();
}

class _FlexPrimaryButtonState extends State<FlexPrimaryButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: widget.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: _isHovered
                ? AppColors.sage.withValues(alpha: 0.9)
                : AppColors.sageDark,
            foregroundColor: AppColors.white,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: _isHovered ? 4 : 2,
            shadowColor: _isHovered
                ? AppColors.sageDark.withValues(alpha: 0.4)
                : AppColors.sageDark.withValues(alpha: 0.2),
          ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: AppTextStyles.buttonPrimary.copyWith(
              color: AppColors.white,
              fontSize: _isHovered ? 16 : 15,
            ),
            child: Text(widget.label),
          ),
        ),
      ),
    );
  }
}

class FlexSecondaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;

  const FlexSecondaryButton(
      {super.key, required this.label, required this.onPressed});

  @override
  State<FlexSecondaryButton> createState() => _FlexSecondaryButtonState();
}

class _FlexSecondaryButtonState extends State<FlexSecondaryButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: widget.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: _isHovered ? AppColors.mint : AppColors.sagePale,
            foregroundColor: AppColors.sageDark,
            elevation: _isHovered ? 2 : 0,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            side: BorderSide(
              color: _isHovered ? AppColors.sage : AppColors.sagePale,
              width: _isHovered ? 1.5 : 1,
            ),
          ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: AppTextStyles.buttonSecondary.copyWith(
              fontSize: _isHovered ? 15 : 14,
            ),
            child: Text(widget.label),
          ),
        ),
      ),
    );
  }
}