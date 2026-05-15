import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/locale_controller.dart';
import '../../../controllers/settings_controller.dart';
import '../../../l10n/locale_text.dart';
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
        title: context.t('Settings', 'Paramètres'),
        showBack: true,
        backTarget: widget.backTarget,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(context.t('NOTIFICATIONS', 'NOTIFICATIONS'),
              style: AppTextStyles.sectionLabel),
          const SizedBox(height: 8),
          SwitchListTile(
            value: settings.pushEnabled,
            activeThumbColor: AppColors.sageDark,
            title: Text(context.t('Push notifications', 'Notifications push')),
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
            title: Text(context.t('Email updates', 'Mises à jour par e-mail')),
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
            title: Text(context.t('SMS alerts', 'Alertes SMS')),
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
          Text(context.t('LANGUAGE', 'LANGUE'),
              style: AppTextStyles.sectionLabel),
          const SizedBox(height: 8),
          Consumer<LocaleController>(
            builder: (context, localeController, _) {
              return Row(
                children: [
                  Expanded(
                    child: _LanguageButton(
                      label: 'English',
                      isSelected: localeController.currentLanguageCode == 'en',
                      onTap: () => localeController.setLocale('en'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _LanguageButton(
                      label: 'Français',
                      isSelected: localeController.currentLanguageCode == 'fr',
                      onTap: () => localeController.setLocale('fr'),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Text(context.t('ACCOUNT', 'COMPTE'),
              style: AppTextStyles.sectionLabel),
          const SizedBox(height: 8),
          FlexSecondaryButton(
            label: context.t('Manage account', 'Gérer le compte'),
            onPressed: () =>
                context.go('/account/manage', extra: '/member/profile'),
          ),
          const SizedBox(height: 8),
          FlexPrimaryButton(
            label: context.t('Sign out', 'Se déconnecter'),
            onPressed: () async {
              await context.read<AuthController>().signOut();
              if (context.mounted) context.go('/');
            },
          ),
        ],
      ),
    );
  }
}

class _LanguageButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.sageDark : AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.sageDark : AppColors.sagePale,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.buttonSecondary.copyWith(
              color: isSelected ? AppColors.white : AppColors.sageDark,
            ),
          ),
        ),
      ),
    );
  }
}
