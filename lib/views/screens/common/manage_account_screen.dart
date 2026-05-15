import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../controllers/auth_controller.dart';
import '../../../l10n/locale_text.dart';
import '../../widgets/buttons.dart';
import '../../widgets/flex_app_bar.dart';
import '../../widgets/form_fields.dart';
import '../../widgets/toast_message.dart';

class ManageAccountScreen extends StatefulWidget {
  final String backTarget;

  const ManageAccountScreen({super.key, required this.backTarget});

  @override
  State<ManageAccountScreen> createState() => _ManageAccountScreenState();
}

class _ManageAccountScreenState extends State<ManageAccountScreen> {
  late final TextEditingController _first;
  late final TextEditingController _last;

  void _goBack() {
    if (GoRouter.of(context).canPop()) {
      context.pop();
      return;
    }
    context.go(widget.backTarget);
  }

  @override
  void initState() {
    super.initState();
    final profile = context.read<AuthController>().profile;
    _first = TextEditingController(text: profile?.firstName ?? '');
    _last = TextEditingController(text: profile?.lastName ?? '');
  }

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final first = _first.text.trim();
    final last = _last.text.trim();
    if (first.isEmpty || last.isEmpty) {
      ToastMessage.show(
          context,
          context.t('Please enter your first and last name',
              'Veuillez saisir votre prénom et votre nom'));
      return;
    }

    final auth = context.read<AuthController>();
    try {
      await auth.updateProfileNames(firstName: first, lastName: last);
      if (!mounted) return;
      ToastMessage.show(
          context, context.t('Account updated', 'Compte mis à jour'));
      _goBack();
    } catch (_) {
      if (mounted) {
        ToastMessage.show(
            context,
            auth.error ??
                context.t('Could not update account',
                    'Impossible de mettre à jour le compte'));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthController>().isLoading;
    return Scaffold(
      appBar: FlexAppBar(
        title: context.t('Manage account', 'Gérer le compte'),
        showBack: true,
        backTarget: widget.backTarget,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FlexFormInput(
              controller: _first, hint: context.t('First name', 'Prénom')),
          const SizedBox(height: 8),
          FlexFormInput(controller: _last, hint: context.t('Last name', 'Nom')),
          const SizedBox(height: 16),
          FlexPrimaryButton(
            label:
                loading ? context.tr('Saving...') : context.tr('Save changes'),
            onPressed: loading ? null : _save,
          ),
          const SizedBox(height: 8),
          FlexSecondaryButton(
            label: context.t('Change password', 'Changer le mot de passe'),
            onPressed: () => context.push('/reset-password'),
          ),
          const SizedBox(height: 8),
          FlexSecondaryButton(
            label: context.tr('Cancel'),
            onPressed: loading ? null : _goBack,
          ),
        ],
      ),
    );
  }
}
