import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers/auth_controller.dart';
import '../../widgets/buttons.dart';
import '../../widgets/flex_app_bar.dart';
import '../../widgets/form_fields.dart';
import '../../widgets/toast_message.dart';

class AddCoachScreen extends StatefulWidget {
  const AddCoachScreen({super.key});

  @override
  State<AddCoachScreen> createState() => _AddCoachScreenState();
}

class _AddCoachScreenState extends State<AddCoachScreen> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();
  final _spec = TextEditingController();
  final _phone = TextEditingController();

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _email.dispose();
    _spec.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_first.text.trim().isEmpty ||
        _last.text.trim().isEmpty ||
        _email.text.trim().isEmpty ||
        _spec.text.trim().isEmpty ||
        _phone.text.trim().isEmpty) {
      ToastMessage.show(context, 'Please fill in all fields');
      return;
    }

    final auth = context.read<AuthController>();
    try {
      final tempPassword = await auth.createCoachAccount(
        firstName: _first.text.trim(),
        lastName: _last.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        speciality: _spec.text.trim(),
      );
      if (!mounted) return;
      if (tempPassword != null && tempPassword.isNotEmpty) {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Coach account created'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Temporary password (shown once):'),
                const SizedBox(height: 8),
                SelectableText(tempPassword),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
        if (!mounted) return;
      }
      ToastMessage.show(context, 'Coach account created!');
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ToastMessage.show(
            context, auth.error ?? 'Failed to create coach account');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthController>().isLoading;
    return Scaffold(
      appBar: const FlexAppBar(
        title: 'Add Coach',
        showBack: true,
        backTarget: '/admin/home',
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FlexFormInput(controller: _first, hint: 'First name'),
          const SizedBox(height: 8),
          FlexFormInput(controller: _last, hint: 'Last name'),
          const SizedBox(height: 8),
          FlexFormInput(controller: _email, hint: 'Email'),
          const SizedBox(height: 8),
          FlexFormInput(controller: _spec, hint: 'Speciality'),
          const SizedBox(height: 8),
          FlexFormInput(controller: _phone, hint: 'Phone'),
          const SizedBox(height: 12),
          FlexPrimaryButton(
            label: loading ? 'Creating...' : 'Create account',
            onPressed: loading ? null : _create,
          ),
        ],
      ),
    );
  }
}
