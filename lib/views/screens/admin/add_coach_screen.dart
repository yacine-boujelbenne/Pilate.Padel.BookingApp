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
    try {
      await context.read<AuthController>().createCoachAccount(
            firstName: _first.text,
            lastName: _last.text,
            email: _email.text,
            phone: _phone.text,
            speciality: _spec.text,
          );
      if (!mounted) return;
      ToastMessage.show(context, 'Coach account created!');
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) ToastMessage.show(context, 'Failed to create coach account');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const FlexAppBar(title: 'Add Coach', showBack: true),
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
          FlexPrimaryButton(label: 'Create account', onPressed: _create),
        ],
      ),
    );
  }
}
