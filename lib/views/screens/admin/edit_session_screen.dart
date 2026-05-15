import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../controllers/session_controller.dart';
import '../../../l10n/locale_text.dart';
import '../../widgets/buttons.dart';
import '../../widgets/flex_app_bar.dart';
import '../../widgets/form_fields.dart';

class EditSessionScreen extends StatefulWidget {
  final String sessionId;

  const EditSessionScreen({super.key, required this.sessionId});

  @override
  State<EditSessionScreen> createState() => _EditSessionScreenState();
}

class _EditSessionScreenState extends State<EditSessionScreen> {
  final _title = TextEditingController();
  final _level = TextEditingController();
  final _price = TextEditingController();

  void _goBack() {
    if (GoRouter.of(context).canPop()) {
      context.pop();
      return;
    }
    context.go('/admin/sessions');
  }

  @override
  void initState() {
    super.initState();
    final session = context
        .read<SessionController>()
        .sessions
        .where((s) => s.id == widget.sessionId)
        .firstOrNull;
    _title.text = session?.title ?? '';
    _level.text = session?.level ?? '';
    _price.text = session?.priceTnd.toString() ?? '';
  }

  @override
  void dispose() {
    _title.dispose();
    _level.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await context.read<SessionController>().updateSession(widget.sessionId, {
      'title': _title.text,
      'level': _level.text,
      'price_tnd': double.tryParse(_price.text) ?? 0,
    });
    if (!mounted) return;
    _goBack();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FlexAppBar(
        title: context.tr('Edit Session'),
        showBack: true,
        backTarget: '/admin/sessions',
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FlexFormInput(controller: _title, hint: context.tr('Title')),
          const SizedBox(height: 8),
          FlexFormInput(controller: _level, hint: context.tr('Level')),
          const SizedBox(height: 8),
          FlexFormInput(
              controller: _price, hint: context.t('Price TND', 'Prix TND')),
          const SizedBox(height: 12),
          FlexPrimaryButton(
              label: context.tr('Save changes'), onPressed: _save),
        ],
      ),
    );
  }
}
