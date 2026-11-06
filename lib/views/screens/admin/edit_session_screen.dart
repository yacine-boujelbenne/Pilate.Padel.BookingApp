import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../controllers/session_controller.dart';
import '../../widgets/buttons.dart';
import '../../widgets/flex_app_bar.dart';
import '../../widgets/form_fields.dart';
import '../../widgets/page_layout.dart';
import '../../widgets/state_widgets.dart';
import '../../widgets/toast_message.dart';

class EditSessionScreen extends StatefulWidget {
  const EditSessionScreen({super.key, required this.sessionId});
  final String sessionId;
  @override
  State<EditSessionScreen> createState() => _EditSessionScreenState();
}

class _EditSessionScreenState extends State<EditSessionScreen> {
  final _title = TextEditingController();
  final _price = TextEditingController();
  String _level = 'all';
  bool _loading = true, _failed = false, _saving = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final session = await context.read<SessionController>().fetchSession(
        widget.sessionId,
      );
      if (!mounted) return;
      if (session == null) {
        setState(() => _failed = true);
        return;
      }
      _title.text = session.title;
      _price.text = session.priceTnd.toString();
      _level = session.level;
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final price = double.tryParse(_price.text.trim());
    if (_title.text.trim().isEmpty ||
        price == null ||
        !price.isFinite ||
        price < 0) {
      ToastMessage.show(
        context,
        'Enter a title and a valid, non-negative session price.',
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await context.read<SessionController>().updateSession(widget.sessionId, {
        'title': _title.text.trim(),
        'level': _level,
        'price_tnd': price,
      });
      if (mounted) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/admin/sessions');
        }
      }
    } catch (_) {
      if (mounted) {
        ToastMessage.show(
          context,
          'Could not save this session. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const FlexAppBar(
      title: 'Edit session',
      showBack: true,
      backTarget: '/admin/sessions',
    ),
    body: FlexPage(
      maxWidth: 600,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const FlexSectionHeader(
            title: 'A few thoughtful adjustments.',
            subtitle: 'Update the details your members see.',
          ),
          if (_loading)
            const FlexLoading()
          else if (_failed)
            FlexErrorCard(
              message: 'This session could not be loaded.',
              onRetry: _load,
            )
          else ...[
            FlexFormInput(controller: _title, hint: 'Session title'),
            const SizedBox(height: 16),
            FlexDropdown(
              value: _level,
              label: 'Level',
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All levels')),
                DropdownMenuItem(value: 'beginner', child: Text('Beginner')),
                DropdownMenuItem(
                  value: 'intermediate',
                  child: Text('Intermediate'),
                ),
                DropdownMenuItem(value: 'advanced', child: Text('Advanced')),
              ],
              onChanged: (value) => setState(() => _level = value ?? 'all'),
            ),
            const SizedBox(height: 16),
            FlexFormInput(
              controller: _price,
              hint: 'Session price · TND',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 24),
            FlexPrimaryButton(
              label: 'Save changes',
              onPressed: _save,
              isLoading: _saving,
            ),
          ],
        ],
      ),
    ),
  );
}
