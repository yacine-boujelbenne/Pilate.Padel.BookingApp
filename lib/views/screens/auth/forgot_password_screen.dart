import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../controllers/auth_controller.dart';
import '../../../services/password_recovery_messages.dart';
import '../../widgets/buttons.dart';
import '../../widgets/auth_login_link.dart';
import '../../widgets/flex_app_bar.dart';
import '../../widgets/form_fields.dart';
import '../../widgets/page_layout.dart';
import '../../widgets/state_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  String? _emailError;
  String? _requestError;
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    final auth = context.read<AuthController>();
    if (auth.isLoading) return;
    final email = _email.text.trim();
    setState(() {
      _requestError = null;
      _emailError = email.isEmpty
          ? 'Enter your email address.'
          : RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)
          ? null
          : 'Enter a valid email address.';
    });
    if (_emailError != null) return;

    FocusScope.of(context).unfocus();
    try {
      await auth.sendPasswordResetEmail(email: email);
      if (mounted) setState(() => _sent = true);
    } catch (error) {
      if (mounted) {
        setState(
          () => _requestError = PasswordRecoveryMessages.sendFailure(error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthController>().isLoading;
    return Scaffold(
      appBar: const FlexAppBar(
        title: 'Reset password',
        showBack: true,
        backTarget: '/login',
      ),
      body: FlexPage(
        maxWidth: 600,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FlexSectionHeader(
                title: 'Let’s get you back.',
                subtitle: 'A fresh start is one email away.',
              ),
              if (_sent)
                Semantics(
                  liveRegion: true,
                  child: FlexEmptyState(
                    icon: Icons.mark_email_read_outlined,
                    text: 'Check your inbox',
                    description: PasswordRecoveryMessages.checkInbox,
                    action: TextButton(
                      onPressed: () => setState(() {
                        _sent = false;
                        _requestError = null;
                        _emailError = null;
                      }),
                      child: const Text('Use a different email'),
                    ),
                  ),
                )
              else ...[
                const Text(
                  'Enter the email address you use for your account to request a password reset link.',
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: 24),
                FlexFormInput(
                  controller: _email,
                  label: 'Email',
                  hint: 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.done,
                  readOnly: loading,
                  errorText: _emailError,
                  onChanged: (_) {
                    if (_emailError != null || _requestError != null) {
                      setState(() {
                        _emailError = null;
                        _requestError = null;
                      });
                    }
                  },
                  onSubmitted: (_) => _sendResetEmail(),
                ),
                if (_requestError != null) ...[
                  const SizedBox(height: 16),
                  Semantics(
                    liveRegion: true,
                    child: FlexSurface(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: AppColors.textMid,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _requestError!,
                              style: AppTextStyles.body,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                FlexPrimaryButton(
                  label: 'Send reset link',
                  isLoading: loading,
                  onPressed: _sendResetEmail,
                ),
              ],
              const SizedBox(height: 12),
              const AuthLoginLink(prompt: 'Remember your password?'),
            ],
          ),
        ),
      ),
    );
  }
}
