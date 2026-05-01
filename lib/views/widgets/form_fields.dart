import 'package:flutter/material.dart';

import '../../app/theme.dart';

class FlexFormInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? errorText;
  final VoidCallback? onTap;
  final bool readOnly;

  const FlexFormInput({
    super.key,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.obscureText = false,
    this.errorText,
    this.onTap,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      readOnly: readOnly,
      onTap: onTap,
      style: AppTextStyles.formInput,
      decoration: InputDecoration(
        hintText: hint,
        errorText: errorText,
        hintStyle: AppTextStyles.formInput.copyWith(color: AppColors.textLight),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
      ),
    );
  }
}

class FlexDropdown<T> extends StatelessWidget {
  final String? value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  const FlexDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.sagePale),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          onChanged: onChanged,
          items: items,
          style: AppTextStyles.formInput,
          dropdownColor: AppColors.white,
        ),
      ),
    );
  }
}
