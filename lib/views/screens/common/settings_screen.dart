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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
            SwitchListTile(
              value: settings.remindersEnabled,
              activeThumbColor: AppColors.sageDark,
              title: Text(context.t('Session reminders', 'Rappels de session')),
              subtitle: Text(context.t(
                'Remind me before my booked sessions even when the app is closed.',
                'Me rappeler avant mes séances réservées même lorsque l\'application est fermée.',
              )),
              onChanged: settings.isLoading
                  ? null
                  : (value) async {
                      await settings.updateSettings(remindersEnabled: value);
                      if (settings.error != null && context.mounted) {
                        ToastMessage.show(context, settings.error!);
                      }
                    },
            ),
          const SizedBox(height: 12),
          Text('ACCOUNT', style: AppTextStyles.sectionLabel),
          const SizedBox(height: 8),
          FlexSecondaryButton(
            label: 'Manage account',
            onPressed: () =>
                context.go('/account/manage', extra: '/member/profile'),
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
    );
  }
}
