import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../controllers/auth_controller.dart';
import '../../../l10n/locale_text.dart';
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
      setState(() => _error =
          context.t('Password is required', 'Le mot de passe est requis'));
      return;
    }

    if (_password.text != _confirm.text) {
      setState(() => _error = context.t(
          'Passwords do not match', 'Les mots de passe ne correspondent pas'));
      return;
    }

    if (_password.text.length < 6) {
      setState(() => _error = context.t(
          'Password must be at least 6 characters',
          'Le mot de passe doit contenir au moins 6 caractères'));
      return;
    }

    final auth = context.read<AuthController>();
    try {
      await auth.updatePassword(newPassword: _password.text);
      if (!mounted) return;
      ToastMessage.show(
          context,
          context.t('Password updated successfully.',
              'Mot de passe mis à jour avec succès.'));
      context.go('/login');
    } catch (_) {
      if (mounted) {
        setState(() => _error = auth.error ??
            context.t('Failed to reset password',
                'Échec de la réinitialisation du mot de passe'));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthController>().isLoading;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.white,
        title: Text(context.t('New password', 'Nouveau mot de passe'),
            style: AppTextStyles.screenTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.t('RESET PASSWORD', 'RÉINITIALISER LE MOT DE PASSE'),
                  style: AppTextStyles.sectionLabel),
              const SizedBox(height: 10),
              Text(
                context.t('Enter your new password below.',
                    'Entrez votre nouveau mot de passe ci-dessous.'),
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 20),
              Text(context.t('NEW PASSWORD', 'NOUVEAU MOT DE PASSE'),
                  style: AppTextStyles.formLabel),
              const SizedBox(height: 6),
              FlexFormInput(
                controller: _password,
                hint: '••••••••',
                obscureText: true,
              ),
              const SizedBox(height: 10),
              Text(context.t('CONFIRM PASSWORD', 'CONFIRMER LE MOT DE PASSE'),
                  style: AppTextStyles.formLabel),
              const SizedBox(height: 6),
              FlexFormInput(
                controller: _confirm,
                hint: '••••••••',
                obscureText: true,
                errorText: _error,
              ),
              const SizedBox(height: 20),
              FlexPrimaryButton(
                label: loading
                    ? context.t('Updating...', 'Mise à jour...')
                    : context.t(
                        'Update password', 'Mettre à jour le mot de passe'),
                onPressed: loading ? null : _resetPassword,
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => context.go('/login'),
                  child: Text(context.t('Cancel', 'Annuler'),
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
