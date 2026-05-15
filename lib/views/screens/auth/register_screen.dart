import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../controllers/auth_controller.dart';
import '../../../l10n/locale_text.dart';
import '../../widgets/buttons.dart';
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
      setState(() => _error = context.t(
          'Passwords do not match', 'Les mots de passe ne correspondent pas'));
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
      ToastMessage.show(
          context,
          context.t('Account created. Please verify your email.',
              'Compte créé. Veuillez vérifier votre e-mail.'));
      context.go('/login');
    } catch (_) {
      if (mounted) {
        setState(() => _error = auth.error ??
            context.t('Registration failed', 'Échec de l\'inscription'));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthController>().isLoading;
    return Scaffold(
      appBar: AppBar(
          backgroundColor: AppColors.white,
          title: Text(context.t('Register', 'Inscription'),
              style: AppTextStyles.screenTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.t('MEMBER REGISTRATION', 'INSCRIPTION MEMBRE'),
                  style: AppTextStyles.sectionLabel),
              const SizedBox(height: 10),
              FlexFormInput(
                  controller: _first, hint: context.t('First name', 'Prénom')),
              const SizedBox(height: 8),
              FlexFormInput(
                  controller: _last, hint: context.t('Last name', 'Nom')),
              const SizedBox(height: 8),
              FlexFormInput(
                  controller: _email, hint: context.t('Email', 'E-mail')),
              const SizedBox(height: 8),
              FlexFormInput(
                  controller: _phone, hint: context.t('Phone', 'Téléphone')),
              const SizedBox(height: 8),
              FlexFormInput(
                  controller: _password,
                  hint: context.t('Password', 'Mot de passe'),
                  obscureText: true),
              const SizedBox(height: 8),
              FlexFormInput(
                  controller: _confirm,
                  hint: context.t(
                      'Confirm password', 'Confirmer le mot de passe'),
                  obscureText: true,
                  errorText: _error),
              const SizedBox(height: 14),
              FlexPrimaryButton(
                  label: loading
                      ? context.t('Creating...', 'Création...')
                      : context.t('Create account', 'Créer un compte'),
                  onPressed: loading ? null : _register),
            ],
          ),
        ),
      ),
    );
  }
}
