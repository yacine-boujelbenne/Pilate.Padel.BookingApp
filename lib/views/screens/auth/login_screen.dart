import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../controllers/auth_controller.dart';
import '../../widgets/buttons.dart';
import '../../widgets/auth_frame.dart';
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
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      ToastMessage.show(context, 'Enter your email and password to continue.');
      return;
    }
    final auth = context.read<AuthController>();
    try {
      await auth.signIn(email: _email.text.trim(), password: _password.text);
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
    return AuthFrame(
      title: 'Welcome back.',
      subtitle: 'A little time for movement. A place that feels like you.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FlexFormInput(
            controller: _email,
            label: 'Email',
            hint: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.username],
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 18),
          FlexFormInput(
            controller: _password,
            label: 'Password',
            hint: 'Your password',
            obscureText: true,
            autofillHints: const [AutofillHints.password],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              if (!loading) _signIn();
            },
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.push('/forgot-password'),
              child: const Text('Forgot password?'),
            ),
          ),
          const SizedBox(height: 16),
          FlexPrimaryButton(
            label: 'Sign in',
            isLoading: loading,
            onPressed: _signIn,
            icon: Icons.arrow_forward_rounded,
          ),
          const SizedBox(height: 20),
          Center(
            child: TextButton(
              onPressed: () => context.go('/register'),
              child: const Text('New to Fléx? Create an account'),
            ),
          ),
        ],
      ),
    );
  }
}
