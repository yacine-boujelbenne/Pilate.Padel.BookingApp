import 'package:flutter/material.dart';
import '../../app/theme.dart';

class FlexFormInput extends StatefulWidget {
  const FlexFormInput({
    super.key,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.obscureText = false,
    this.errorText,
    this.onTap,
    this.readOnly = false,
    this.label,
    this.onChanged,
    this.autofillHints,
    this.textInputAction,
    this.onSubmitted,
  });
  final TextEditingController controller;
  final String hint;
  final String? label;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? errorText;
  final VoidCallback? onTap;
  final bool readOnly;
  final ValueChanged<String>? onChanged;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  @override
  State<FlexFormInput> createState() => _FlexFormInputState();
}

class _FlexFormInputState extends State<FlexFormInput> {
  bool _showPassword = false;
  @override
  Widget build(BuildContext context) => TextField(
    controller: widget.controller,
    keyboardType: widget.keyboardType,
    obscureText: widget.obscureText && !_showPassword,
    autocorrect: !widget.obscureText,
    enableSuggestions: !widget.obscureText,
    readOnly: widget.readOnly,
    onTap: widget.onTap,
    onChanged: widget.onChanged,
    autofillHints: widget.autofillHints,
    textInputAction: widget.textInputAction,
    onSubmitted: widget.onSubmitted,
    style: AppTextStyles.formInput,
    decoration: InputDecoration(
      labelText: widget.label ?? widget.hint,
      hintText: widget.label == null ? null : widget.hint,
      errorText: widget.errorText,
      suffixIcon: widget.obscureText
          ? IconButton(
              tooltip: _showPassword ? 'Hide password' : 'Show password',
              onPressed: () => setState(() => _showPassword = !_showPassword),
              icon: Icon(
                _showPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
              ),
            )
          : null,
    ),
  );
}

class FlexDropdown<T> extends StatelessWidget {
  const FlexDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.label,
  });
  final String? value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;
  final String? label;
  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    initialValue: value,
    isExpanded: true,
    onChanged: onChanged,
    items: items,
    style: AppTextStyles.formInput,
    dropdownColor: AppColors.white,
    decoration: InputDecoration(labelText: label),
  );
}
