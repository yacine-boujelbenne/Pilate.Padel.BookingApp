import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../controllers/auth_controller.dart';
import '../../../l10n/locale_text.dart';
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
  var _showPassword = true;

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
        ToastMessage.show(context,
            auth.error ?? context.t('Login failed', 'Échec de la connexion'));
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
              Text(context.t('Sign in', 'Connexion'),
                  style: AppTextStyles.modalTitle),
              const SizedBox(height: 16),
              Text(context.t('EMAIL', 'E-MAIL'),
                  style: AppTextStyles.formLabel),
              const SizedBox(height: 6),
              FlexFormInput(
                  controller: _email,
                  hint: context.t('you@email.com', 'vous@exemple.com')),
              const SizedBox(height: 10),
              Text(context.t('PASSWORD', 'MOT DE PASSE'),
                  style: AppTextStyles.formLabel),
              const SizedBox(height: 6),
              FlexFormInput(
                  controller: _password,
                  hint: '••••••••',
                  suffixIcon: IconButton(
                    icon: Icon(_showPassword
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () =>
                        setState(() => _showPassword = !_showPassword),
                  ),
                  obscureText: _showPassword),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push('/forgot-password'),
                  child: Text(
                      context.t('Forgot password?', 'Mot de passe oublié ?'),
                      style: AppTextStyles.sessionMeta),
                ),
              ),
              const SizedBox(height: 12),
              FlexPrimaryButton(
                  label: loading
                      ? context.t('Signing in...', 'Connexion...')
                      : context.t('Sign in', 'Connexion'),
                  onPressed: loading ? null : _signIn),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => context.go('/register'),
                  child: Text(
                      context.t('No account? Register',
                          'Pas de compte ? Inscrivez-vous'),
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
