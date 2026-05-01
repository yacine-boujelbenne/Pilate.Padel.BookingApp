import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../controllers/auth_controller.dart';
import '../../widgets/buttons.dart';
import '../../widgets/form_fields.dart';
import '../../widgets/toast_message.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final auth = context.read<AuthController>();
    try {
      await auth.signIn(
          email: _email.text.trim(), password: _password.text.trim());
      final role = auth.profile?.role;
      if (!mounted) return;
      if (role == 'admin') {
        context.go('/admin/home');
      } else if (role == 'coach') {
        context.go('/coach/home');
      } else {
        context.go('/member/home');
      }
    } catch (_) {
      if (mounted) {
        ToastMessage.show(context, auth.error ?? 'Login failed');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthController>().isLoading;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text('Sign in', style: AppTextStyles.modalTitle),
              const SizedBox(height: 16),
              Text('EMAIL', style: AppTextStyles.formLabel),
              const SizedBox(height: 6),
              FlexFormInput(controller: _email, hint: 'you@email.com'),
              const SizedBox(height: 10),
              Text('PASSWORD', style: AppTextStyles.formLabel),
              const SizedBox(height: 6),
              FlexFormInput(
                  controller: _password, hint: '••••••••', obscureText: true),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: Text('Forgot password?',
                      style: AppTextStyles.sessionMeta),
                ),
              ),
              const SizedBox(height: 12),
              FlexPrimaryButton(
                  label: loading ? 'Signing in...' : 'Sign in',
                  onPressed: loading ? null : _signIn),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => context.go('/register'),
                  child: Text('No account? Register',
                      style: AppTextStyles.buttonSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
