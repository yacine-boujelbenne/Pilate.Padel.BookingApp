import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme.dart';

class ToastMessage {
  static void show(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (_) => Positioned(
        bottom: 90,
        left: 24,
        right: 24,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.sageDark,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(message,
                  style: AppTextStyles.body.copyWith(color: AppColors.white)),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Timer(const Duration(milliseconds: 2500), entry.remove);
  }
}
