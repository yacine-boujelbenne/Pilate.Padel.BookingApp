import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../controllers/auth_controller.dart';
import '../../widgets/buttons.dart';
import '../../widgets/flex_app_bar.dart';
import '../../widgets/form_fields.dart';
import '../../widgets/toast_message.dart';

class ManageAccountScreen extends StatefulWidget {
  const ManageAccountScreen({super.key});

  @override
  State<ManageAccountScreen> createState() => _ManageAccountScreenState();
}

class _ManageAccountScreenState extends State<ManageAccountScreen> {
  late final TextEditingController _first;
  late final TextEditingController _last;

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
      ToastMessage.show(context, 'Please enter your first and last name');
      return;
    }

    final auth = context.read<AuthController>();
    try {
      await auth.updateProfileNames(firstName: first, lastName: last);
      if (!mounted) return;
      ToastMessage.show(context, 'Account updated');
      context.pop();
    } catch (_) {
      if (mounted) {
        ToastMessage.show(context, auth.error ?? 'Could not update account');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthController>().isLoading;
    return Scaffold(
      appBar: const FlexAppBar(title: 'Manage Account', showBack: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FlexFormInput(controller: _first, hint: 'First name'),
          const SizedBox(height: 8),
          FlexFormInput(controller: _last, hint: 'Last name'),
          const SizedBox(height: 16),
          FlexPrimaryButton(
            label: loading ? 'Saving...' : 'Save changes',
            onPressed: loading ? null : _save,
          ),
          const SizedBox(height: 8),
          FlexSecondaryButton(
            label: 'Cancel',
            onPressed: loading ? null : () => context.pop(),
          ),
        ],
      ),
    );
  }
}
