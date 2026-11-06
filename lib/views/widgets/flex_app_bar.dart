import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';

class FlexAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  final String? backTarget;
  final String? badgeText;
  final List<Widget>? extraActions;

  const FlexAppBar({
    super.key,
    required this.title,
    this.showBack = false,
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
                badgeText!,
                style: AppTextStyles.chip.copyWith(color: AppColors.sageDark),
              ),
            ),
          ),
        ),
      );
    }

    return AppBar(
      backgroundColor: AppColors.mint,
      elevation: 0,
      toolbarHeight: 72,
      centerTitle: false,
      leading: showBack
          ? Padding(
              padding: const EdgeInsets.all(8),
              child: IconButton(
                tooltip: 'Back',
                onPressed: handleBack,
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  size: 22,
                  color: AppColors.forest,
                ),
              ),
            )
          : null,
      title: Text(title, style: AppTextStyles.screenTitle),
      actions: actionWidgets.isEmpty ? null : actionWidgets,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(72);
}
