import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../controllers/auth_controller.dart';
import '../../widgets/buttons.dart';
import '../../widgets/form_fields.dart';
import '../../widgets/toast_message.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    setState(() => _error = null);

    if (_password.text.isEmpty) {
      setState(() => _error = 'Password is required');
      return;
    }

    if (_password.text != _confirm.text) {
      setState(() => _error = 'Passwords do not match');
      return;
    }

    if (_password.text.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters');
      return;
    }

    final auth = context.read<AuthController>();
    try {
      await auth.updatePassword(newPassword: _password.text);
      if (!mounted) return;
      ToastMessage.show(context, 'Password updated successfully.');
      context.go('/login');
    } catch (_) {
      if (mounted) {
        setState(() => _error = auth.error ?? 'Failed to reset password');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthController>().isLoading;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.white,
        title: Text('New password', style: AppTextStyles.screenTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('RESET PASSWORD', style: AppTextStyles.sectionLabel),
              const SizedBox(height: 10),
              Text(
                'Enter your new password below.',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 20),
              Text('NEW PASSWORD', style: AppTextStyles.formLabel),
              const SizedBox(height: 6),
              FlexFormInput(
                controller: _password,
                hint: '••••••••',
                obscureText: true,
              ),
              const SizedBox(height: 10),
              Text('CONFIRM PASSWORD', style: AppTextStyles.formLabel),
              const SizedBox(height: 6),
              FlexFormInput(
                controller: _confirm,
                hint: '••••••••',
                obscureText: true,
                errorText: _error,
              ),
              const SizedBox(height: 20),
              FlexPrimaryButton(
                label: loading ? 'Updating...' : 'Update password',
                onPressed: loading ? null : _resetPassword,
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => context.go('/login'),
                  child: Text('Cancel', style: AppTextStyles.buttonSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
