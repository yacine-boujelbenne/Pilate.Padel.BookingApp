import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../controllers/auth_controller.dart';
import '../../../l10n/locale_text.dart';
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
      setState(() =>
          _error = context.t('Email is required', 'L\'e-mail est requis'));
      return;
    }

    final auth = context.read<AuthController>();
    try {
      await auth.sendPasswordResetEmail(email: _email.text.trim());
      if (!mounted) return;
      ToastMessage.show(
          context,
          context.t('Password reset email sent. Check your inbox.',
              'E-mail de réinitialisation envoyé. Vérifiez votre boîte de réception.'));
      context.go('/login');
    } catch (_) {
      if (mounted) {
        setState(() => _error = auth.error ??
            context.t('Failed to send reset email',
                'Échec de l\'envoi de l\'e-mail de réinitialisation'));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthController>().isLoading;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.white,
        title: Text(
            context.t('Reset password', 'Réinitialiser le mot de passe'),
            style: AppTextStyles.screenTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.t('FORGOT PASSWORD', 'MOT DE PASSE OUBLIÉ'),
                  style: AppTextStyles.sectionLabel),
              const SizedBox(height: 10),
              Text(
                context.t(
                  'Enter your email address and we\'ll send you a link to reset your password.',
                  'Entrez votre adresse e-mail et nous vous enverrons un lien pour réinitialiser votre mot de passe.',
                ),
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 20),
              Text(context.t('EMAIL', 'E-MAIL'),
                  style: AppTextStyles.formLabel),
              const SizedBox(height: 6),
              FlexFormInput(
                controller: _email,
                hint: context.t('you@email.com', 'vous@exemple.com'),
                keyboardType: TextInputType.emailAddress,
                errorText: _error,
              ),
              const SizedBox(height: 20),
              FlexPrimaryButton(
                label: loading
                    ? context.t('Sending...', 'Envoi...')
                    : context.t('Send reset link',
                        'Envoyer le lien de réinitialisation'),
                onPressed: loading ? null : _sendResetEmail,
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => context.go('/login'),
                  child: Text(
                      context.t('Back to login', 'Retour à la connexion'),
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
