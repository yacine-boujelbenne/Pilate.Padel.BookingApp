import '../../widgets/page_layout.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../controllers/auth_controller.dart';
import '../../widgets/buttons.dart';
import '../../widgets/auth_login_link.dart';
import '../../widgets/flex_app_bar.dart';
import '../../widgets/form_fields.dart';
import '../../widgets/toast_message.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  String? _error;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_password.text != _confirm.text) {
      setState(() => _error = 'Passwords do not match');
      return;
    }
    setState(() => _error = null);

    final auth = context.read<AuthController>();
    try {
      await auth.register(
        firstName: _first.text.trim(),
        lastName: _last.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        password: _password.text,
      );
      if (!mounted) return;
      ToastMessage.show(context, 'Account created. Please verify your email.');
      context.go('/login');
    } catch (_) {
      if (mounted) {
        setState(() => _error = auth.error ?? 'Registration failed');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthController>().isLoading;
    return Scaffold(
      appBar: const FlexAppBar(
        title: 'Create account',
        showBack: true,
        backTarget: '/login',
      ),
      body: FlexPage(
        maxWidth: 600,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FlexSectionHeader(
                  title: 'Make room for you.',
                  subtitle: 'Join Fléx and find a rhythm that fits your life.',
                ),
                Text('MEMBER REGISTRATION', style: AppTextStyles.sectionLabel),
                const SizedBox(height: 10),
                FlexFormInput(controller: _first, hint: 'First name'),
                const SizedBox(height: 8),
                FlexFormInput(controller: _last, hint: 'Last name'),
                const SizedBox(height: 8),
                FlexFormInput(
                  controller: _email,
                  hint: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 8),
                FlexFormInput(
                  controller: _phone,
                  hint: 'Phone',
                  keyboardType: TextInputType.phone,
                  autofillHints: const [AutofillHints.telephoneNumber],
                ),
                const SizedBox(height: 8),
                FlexFormInput(
                  controller: _password,
                  hint: 'Password',
                  obscureText: true,
                ),
                const SizedBox(height: 8),
                FlexFormInput(
                  controller: _confirm,
                  hint: 'Confirm password',
                  obscureText: true,
                  errorText: _error,
                ),
                const SizedBox(height: 14),
                FlexPrimaryButton(
                  label: 'Create account',
                  isLoading: loading,
                  onPressed: _register,
                ),
                const SizedBox(height: 12),
                const AuthLoginLink(prompt: 'Already have an account?'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
