import 'package:flutter/material.dart';

import '../../app/theme.dart';

class FlexAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  final String? badgeText;
  final List<Widget>? extraActions;

  const FlexAppBar({
    super.key,
    required this.title,
    this.showBack = false,
    this.badgeText,
    this.extraActions,
  });

  @override
  Widget build(BuildContext context) {
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
      backgroundColor: AppColors.white,
      elevation: 0,
      centerTitle: true,
      leading: showBack
          ? Padding(
              padding: const EdgeInsets.all(8),
              child: InkWell(
                onTap: () => Navigator.of(context).maybePop(),
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
      title: Text(title, style: AppTextStyles.screenTitle),
      actions: actionWidgets.isEmpty ? null : actionWidgets,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}
