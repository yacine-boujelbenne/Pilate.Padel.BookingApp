import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../controllers/locale_controller.dart';
import '../../l10n/locale_text.dart';

class FlexAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  final String? backTarget;
  final String? badgeText;
  final List<Widget>? extraActions;

  const FlexAppBar({
    super.key,
    required this.title,
    this.showBack = true,
    this.backTarget,
    this.badgeText,
    this.extraActions,
  });

  @override
  Widget build(BuildContext context) {
    void handleBack() {
      if (GoRouter.of(context).canPop()) {
        context.pop();
        return;
      }

      if (backTarget != null && backTarget!.isNotEmpty) {
        context.go(backTarget!);
        return;
      }

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }

    final actionWidgets = <Widget>[];
    if (extraActions != null) {
      actionWidgets.addAll(extraActions!);
    }

    if (badgeText != null) {
      actionWidgets.add(
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.sagePale,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                context.tr(badgeText!),
                style: AppTextStyles.chip.copyWith(color: AppColors.sageDark),
              ),
            ),
          ),
        ),
      );
    }

    actionWidgets.add(
      Consumer<LocaleController>(
        builder: (context, localeController, _) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                final newLang =
                    localeController.currentLanguageCode == 'en' ? 'fr' : 'en';
                localeController.setLocale(newLang);
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.sagePale),
                ),
                child: Text(
                  localeController.currentLanguageCode.toUpperCase(),
                  style: AppTextStyles.chip.copyWith(color: AppColors.sageDark),
                ),
              ),
            ),
          );
        },
      ),
    );

    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      centerTitle: true,
      leading: showBack
          ? Padding(
              padding: const EdgeInsets.all(8),
              child: InkWell(
                onTap: handleBack,
                borderRadius: BorderRadius.circular(10),
                child: Ink(
                  decoration: BoxDecoration(
                    color: AppColors.mint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_back,
                      size: 20, color: AppColors.sageDark),
                ),
              ),
            )
          : null,
      title: Text(context.tr(title), style: AppTextStyles.screenTitle),
      actions: actionWidgets.isEmpty ? null : actionWidgets,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}
