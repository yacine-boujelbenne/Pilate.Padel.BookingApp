import 'package:flutter/material.dart';

/// Modern color palette for the application
/// Supports glassmorphism, gradients, and smooth color transitions
class ModernColors {
  ModernColors._(); // Private constructor to prevent instantiation

  /// Primary Color System
  /// Deep purple/indigo with modern aesthetic
  static const Color primaryDarkest = Color(0xFF1A0E3A);
  static const Color primaryDark = Color(0xFF2D1B5E);
  static const Color primary = Color(0xFF4D3BA8);
  static const Color primaryLight = Color(0xFF6B5DB8);
  static const Color primaryLightest = Color(0xFF8B7FCC);

  /// Secondary Color System
  /// Accent teal/cyan for highlights
  static const Color secondaryDark = Color(0xFF0E7B7A);
  static const Color secondary = Color(0xFF17A2A2);
  static const Color secondaryLight = Color(0xFF4DB8B8);
  static const Color secondaryLightest = Color(0xFF8FD9D9);

  /// Background System
  static const Color backgroundDark = Color(0xFFF5F5F7);
  static const Color background = Color(0xFFFAFAFC);
  static const Color backgroundLight = Color(0xFFFFFFFF);

  /// Surface Colors (for cards and containers)
  static const Color surfaceGlass = Color(0xFFFFFFFF); // With opacity
  static const Color surfaceAlt = Color(0xFFF9F9FB);
  static const Color surfaceElevated = Color(0xFFFFFFFF);

  /// Text Colors
  static const Color textPrimary = Color(0xFF1D1D1F);
  static const Color textSecondary = Color(0xFF6F6F77);
  static const Color textTertiary = Color(0xFFA1A1A6);
  static const Color textInverse = Color(0xFFFFFFFF);

  /// Status Colors
  static const Color successDark = Color(0xFF0F7A3B);
  static const Color success = Color(0xFF15A946);
  static const Color successLight = Color(0xFF34C759);
  static const Color successLightest = Color(0xFF8FD9B8);

  static const Color warningDark = Color(0xFFA85C00);
  static const Color warning = Color(0xFFEB8A00);
  static const Color warningLight = Color(0xFFF5A623);
  static const Color warningLightest = Color(0xFFFFE4B5);

  static const Color errorDark = Color(0xFFC5192D);
  static const Color error = Color(0xFFFF3B30);
  static const Color errorLight = Color(0xFFFF6B6B);
  static const Color errorLightest = Color(0xFFFFD9D4);

  static const Color infoDark = Color(0xFF0A5FCC);
  static const Color info = Color(0xFF007AFF);
  static const Color infoLight = Color(0xFF3FA8FF);
  static const Color infoLightest = Color(0xFFD9E8FF);

  /// Glass Effect Colors (with transparency)
  static Color get glassDark => const Color(0xFFFFFFFF).withOpacity(0.1);
  static Color get glassMedium => const Color(0xFFFFFFFF).withOpacity(0.15);
  static Color get glassLight => const Color(0xFFFFFFFF).withOpacity(0.25);
  static Color get glassLighter => const Color(0xFFFFFFFF).withOpacity(0.35);

  /// Gradient Definitions
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryToPurpleGradient = LinearGradient(
    colors: [primary, Color(0xFF7B3FF2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [backgroundDark, backgroundLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [success, successLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [warning, warningLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient errorGradient = LinearGradient(
    colors: [error, errorLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Animated Color Transitions (for animations)
  static Color lerpPrimary(double t) {
    return Color.lerp(primaryDark, primaryLight, t) ?? primary;
  }

  static Color lerpSecondary(double t) {
    return Color.lerp(secondaryDark, secondaryLight, t) ?? secondary;
  }

  static Color lerpText(double t) {
    return Color.lerp(textPrimary, textSecondary, t) ?? textPrimary;
  }

  /// Divider and Border Colors
  static const Color dividerLight = Color(0xFFE5E5E7);
  static const Color dividerMedium = Color(0xFFD0D0D5);
  static const Color dividerDark = Color(0xFFBBBBBF);

  /// Overlay Colors
  static Color overlayScrim = const Color(0xFF000000).withOpacity(0.4);
  static Color overlayLight = const Color(0xFFFFFFFF).withOpacity(0.7);
  static Color overlayMedium = const Color(0xFF000000).withOpacity(0.25);
}
