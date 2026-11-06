import '../../widgets/page_layout.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/settings_controller.dart';
import '../../widgets/buttons.dart';
import '../../widgets/flex_app_bar.dart';
import '../../widgets/toast_message.dart';

class SettingsScreen extends StatefulWidget {
  final String backTarget;

  const SettingsScreen({super.key, required this.backTarget});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsController>().loadSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    return Scaffold(
      appBar: FlexAppBar(
        title: 'Settings',
        showBack: true,
        backTarget: widget.backTarget,
      ),
      body: FlexPage(
        maxWidth: 720,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const FlexSectionHeader(
              title: 'Make yourself at home',
              subtitle: 'Your account and notification preferences.',
            ),
            if (settings.isLoading) const LinearProgressIndicator(),
            Text('NOTIFICATIONS', style: AppTextStyles.sectionLabel),
            const SizedBox(height: 8),
            SwitchListTile(
              value: settings.pushEnabled,
              activeThumbColor: AppColors.sageDark,
              title: const Text('Push notifications'),
              onChanged: settings.isLoading
                  ? null
                  : (value) async {
                      await settings.updateSettings(pushEnabled: value);
                      if (settings.error != null && context.mounted) {
                        ToastMessage.show(context, settings.error!);
                      }
                    },
            ),
            SwitchListTile(
              value: settings.emailEnabled,
              activeThumbColor: AppColors.sageDark,
              title: const Text('Email updates'),
              onChanged: settings.isLoading
                  ? null
                  : (value) async {
                      await settings.updateSettings(emailEnabled: value);
                      if (settings.error != null && context.mounted) {
                        ToastMessage.show(context, settings.error!);
                      }
                    },
            ),
            SwitchListTile(
              value: settings.smsEnabled,
              activeThumbColor: AppColors.sageDark,
              title: const Text('SMS alerts'),
              onChanged: settings.isLoading
                  ? null
                  : (value) async {
                      await settings.updateSettings(smsEnabled: value);
                      if (settings.error != null && context.mounted) {
                        ToastMessage.show(context, settings.error!);
                      }
                    },
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => showAboutDialog(
                context: context,
                applicationName: 'Fléx Pilates & Padel',
                applicationVersion: '1.0.0',
                applicationLegalese:
                    'Movement. Balance. Community.\nVisual asset credits are included in Licenses.',
              ),
              icon: const Icon(Icons.info_outline_rounded),
              label: const Text('About Fléx & credits'),
            ),
            const SizedBox(height: 12),
            Text('ACCOUNT', style: AppTextStyles.sectionLabel),
            const SizedBox(height: 8),
            FlexSecondaryButton(
              label: 'Manage account',
              onPressed: () =>
                  context.go('/account/manage', extra: widget.backTarget),
            ),
            const SizedBox(height: 8),
            FlexPrimaryButton(
              label: 'Sign out',
              onPressed: () async {
                await context.read<AuthController>().signOut();
                if (context.mounted) context.go('/login');
              },
            ),
          ],
        ),
      ),
    );
  }
}
