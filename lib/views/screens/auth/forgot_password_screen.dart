import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../controllers/auth_controller.dart';
import '../../widgets/buttons.dart';
import '../../widgets/form_fields.dart';
import '../../widgets/toast_message.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    setState(() => _error = null);

    if (_email.text.trim().isEmpty) {
      setState(() => _error = 'Email is required');
      return;
    }

    final auth = context.read<AuthController>();
    try {
      await auth.sendPasswordResetEmail(email: _email.text.trim());
      if (!mounted) return;
      ToastMessage.show(context, 'Password reset email sent. Check your inbox.');
      context.go('/login');
    } catch (_) {
      if (mounted) {
        setState(() => _error = auth.error ?? 'Failed to send reset email');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthController>().isLoading;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.white,
        title: Text('Reset password', style: AppTextStyles.screenTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('FORGOT PASSWORD', style: AppTextStyles.sectionLabel),
              const SizedBox(height: 10),
              Text(
                'Enter your email address and we\'ll send you a link to reset your password.',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 20),
              Text('EMAIL', style: AppTextStyles.formLabel),
              const SizedBox(height: 6),
              FlexFormInput(
                controller: _email,
                hint: 'you@email.com',
                keyboardType: TextInputType.emailAddress,
                errorText: _error,
              ),
              const SizedBox(height: 20),
              FlexPrimaryButton(
                label: loading ? 'Sending...' : 'Send reset link',
                onPressed: loading ? null : _sendResetEmail,
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => context.go('/login'),
                  child: Text('Back to login', style: AppTextStyles.buttonSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
