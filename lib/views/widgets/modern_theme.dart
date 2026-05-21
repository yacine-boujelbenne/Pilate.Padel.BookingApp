import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'modern_colors.dart';

/// Modern Design System
/// Defines spacing, border radius, shadows, typography and animation curves
/// for a cohesive, contemporary UI experience
class ModernSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double huge = 48.0;
}

class ModernRadius {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double full = 1000.0;
}

/// Modern elevation and shadow system
class ModernShadows {
  /// Soft shadow for subtle elevation
  static const BoxShadow soft = BoxShadow(
    color: Color(0x0A000000),
    offset: Offset(0, 1),
    blurRadius: 2,
    spreadRadius: 0,
  );

  /// Medium shadow for interactive elements
  static const BoxShadow medium = BoxShadow(
    color: Color(0x14000000),
    offset: Offset(0, 4),
    blurRadius: 8,
    spreadRadius: 0,
  );

  /// High shadow for prominent elements
  static const BoxShadow high = BoxShadow(
    color: Color(0x24000000),
    offset: Offset(0, 12),
    blurRadius: 24,
    spreadRadius: 0,
  );

  /// Extra high shadow for modals and overlays
  static const BoxShadow extraHigh = BoxShadow(
    color: Color(0x33000000),
    offset: Offset(0, 20),
    blurRadius: 40,
    spreadRadius: -8,
  );

  static List<BoxShadow> softElevation = [soft];
  static List<BoxShadow> mediumElevation = [medium];
  static List<BoxShadow> highElevation = [high];
  static List<BoxShadow> extraHighElevation = [extraHigh];
}

/// Modern Typography System
class ModernTypography {
  /// Display - Large, bold headings
  static TextStyle get displayLarge => GoogleFonts.notoSerif(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    height: 1.2,
    color: ModernColors.textPrimary,
  );

  static TextStyle get displayMedium => GoogleFonts.notoSerif(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    height: 1.3,
    color: ModernColors.textPrimary,
  );

  static TextStyle get displaySmall => GoogleFonts.notoSerif(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    height: 1.4,
    color: ModernColors.textPrimary,
  );

  /// Headline - Section titles
  static TextStyle get headlineLarge => GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: ModernColors.textPrimary,
  );

  static TextStyle get headlineMedium => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.5,
    color: ModernColors.textPrimary,
  );

  static TextStyle get headlineSmall => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
    color: ModernColors.textPrimary,
  );

  /// Title - Card titles, buttons
  static TextStyle get titleLarge => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
    color: ModernColors.textPrimary,
  );

  static TextStyle get titleMedium => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.5,
    color: ModernColors.textPrimary,
  );

  static TextStyle get titleSmall => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.6,
    letterSpacing: 0.4,
    color: ModernColors.textSecondary,
  );

  /// Body - Main content text
  static TextStyle get bodyLarge => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: ModernColors.textPrimary,
  );

  static TextStyle get bodyMedium => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: ModernColors.textPrimary,
  );

  static TextStyle get bodySmall => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: ModernColors.textSecondary,
  );

  /// Label - Buttons, chips, tags
  static TextStyle get labelLarge => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.1,
    color: ModernColors.textPrimary,
  );

  static TextStyle get labelMedium => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.2,
    color: ModernColors.textSecondary,
  );

  static TextStyle get labelSmall => GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.3,
    color: ModernColors.textTertiary,
  );
}

/// Custom Animation Curves for smooth transitions
class ModernCurves {
  /// Subtle ease-in for entrances
  static const Curve easeInSubtle = Curves.easeInQuad;

  /// Subtle ease-out for exits
  static const Curve easeOutSubtle = Curves.easeOutQuad;

  /// Smooth ease-in-out for interactive elements
  static const Curve easeInOutSmooth = Curves.easeInOutCubic;

  /// Quick response for UI feedback
  static const Curve snappy = Curves.easeOutQuart;

  /// Bouncy spring-like animation
  static const Curve bouncy = Curves.elasticOut;
}

/// Custom ThemeData for the application
class ModernTheme {
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: ModernColors.background,
      canvasColor: ModernColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: ModernColors.primary,
        brightness: Brightness.light,
        primary: ModernColors.primary,
        onPrimary: ModernColors.textInverse,
        primaryContainer: ModernColors.primaryLight,
        onPrimaryContainer: ModernColors.textPrimary,
        secondary: ModernColors.secondary,
        onSecondary: ModernColors.textInverse,
        secondaryContainer: ModernColors.secondaryLight,
        onSecondaryContainer: ModernColors.textPrimary,
        tertiary: ModernColors.successLight,
        onTertiary: ModernColors.textInverse,
        error: ModernColors.error,
        onError: ModernColors.textInverse,
        errorContainer: ModernColors.errorLightest,
        onErrorContainer: ModernColors.error,
        background: ModernColors.background,
        onBackground: ModernColors.textPrimary,
        surface: ModernColors.surfaceGlass,
        onSurface: ModernColors.textPrimary,
        outline: ModernColors.dividerMedium,
        outlineVariant: ModernColors.dividerLight,
      ),
      textTheme: TextTheme(
        displayLarge: ModernTypography.displayLarge,
        displayMedium: ModernTypography.displayMedium,
        displaySmall: ModernTypography.displaySmall,
        headlineLarge: ModernTypography.headlineLarge,
        headlineMedium: ModernTypography.headlineMedium,
        headlineSmall: ModernTypography.headlineSmall,
        titleLarge: ModernTypography.titleLarge,
        titleMedium: ModernTypography.titleMedium,
        titleSmall: ModernTypography.titleSmall,
        bodyLarge: ModernTypography.bodyLarge,
        bodyMedium: ModernTypography.bodyMedium,
        bodySmall: ModernTypography.bodySmall,
        labelLarge: ModernTypography.labelLarge,
        labelMedium: ModernTypography.labelMedium,
        labelSmall: ModernTypography.labelSmall,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ModernColors.surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: ModernSpacing.lg,
          vertical: ModernSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ModernRadius.md),
          borderSide: const BorderSide(color: ModernColors.dividerMedium),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ModernRadius.md),
          borderSide: const BorderSide(color: ModernColors.dividerLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ModernRadius.md),
          borderSide: const BorderSide(
            color: ModernColors.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ModernRadius.md),
          borderSide: const BorderSide(color: ModernColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ModernRadius.md),
          borderSide: const BorderSide(
            color: ModernColors.error,
            width: 2,
          ),
        ),
        labelStyle: ModernTypography.labelMedium,
        hintStyle: ModernTypography.bodyMedium.copyWith(
          color: ModernColors.textTertiary,
        ),
        helperStyle: ModernTypography.bodySmall,
        errorStyle: ModernTypography.bodySmall.copyWith(
          color: ModernColors.error,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ModernColors.primary,
          foregroundColor: ModernColors.textInverse,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: ModernSpacing.lg,
            vertical: ModernSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ModernRadius.lg),
          ),
          textStyle: ModernTypography.labelLarge.copyWith(
            color: ModernColors.textInverse,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ModernColors.primary,
          side: const BorderSide(color: ModernColors.primary),
          padding: const EdgeInsets.symmetric(
            horizontal: ModernSpacing.lg,
            vertical: ModernSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ModernRadius.lg),
          ),
          textStyle: ModernTypography.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ModernColors.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: ModernSpacing.md,
            vertical: ModernSpacing.sm,
          ),
          textStyle: ModernTypography.labelLarge,
        ),
      ),
      cardTheme: CardTheme(
        color: ModernColors.surfaceGlass,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ModernRadius.lg),
          side: const BorderSide(
            color: ModernColors.dividerLight,
            width: 1,
          ),
        ),
        shadowColor: const Color(0x1A000000),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: ModernColors.surfaceAlt,
        disabledColor: ModernColors.dividerLight,
        selectedColor: ModernColors.primary,
        secondarySelectedColor: ModernColors.secondary,
        padding: const EdgeInsets.symmetric(
          horizontal: ModernSpacing.md,
          vertical: ModernSpacing.sm,
        ),
        labelStyle: ModernTypography.labelMedium,
        secondaryLabelStyle: ModernTypography.labelMedium.copyWith(
          color: ModernColors.textInverse,
        ),
        brightness: Brightness.light,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ModernRadius.full),
          side: const BorderSide(color: ModernColors.dividerLight),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: ModernColors.backgroundLight,
        foregroundColor: ModernColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: ModernTypography.headlineSmall,
      ),
      iconTheme: const IconThemeData(color: ModernColors.textPrimary),
      dividerTheme: const DividerThemeData(
        color: ModernColors.dividerLight,
        thickness: 1,
      ),
    );
  }

  /// Ready for future dark theme implementation
  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: ModernColors.primaryDarkest,
      canvasColor: ModernColors.primaryDarkest,
      colorScheme: ColorScheme.fromSeed(
        seedColor: ModernColors.primary,
        brightness: Brightness.dark,
        primary: ModernColors.primaryLight,
        secondary: ModernColors.secondaryLight,
        error: ModernColors.error,
      ),
      textTheme: TextTheme(
        displayLarge: ModernTypography.displayLarge.copyWith(
          color: ModernColors.textInverse,
        ),
        displayMedium: ModernTypography.displayMedium.copyWith(
          color: ModernColors.textInverse,
        ),
        displaySmall: ModernTypography.displaySmall.copyWith(
          color: ModernColors.textInverse,
        ),
        headlineLarge: ModernTypography.headlineLarge.copyWith(
          color: ModernColors.textInverse,
        ),
        headlineMedium: ModernTypography.headlineMedium.copyWith(
          color: ModernColors.textInverse,
        ),
        headlineSmall: ModernTypography.headlineSmall.copyWith(
          color: ModernColors.textInverse,
        ),
        titleLarge: ModernTypography.titleLarge.copyWith(
          color: ModernColors.textInverse,
        ),
        titleMedium: ModernTypography.titleMedium.copyWith(
          color: ModernColors.textInverse,
        ),
        titleSmall: ModernTypography.titleSmall.copyWith(
          color: ModernColors.textTertiary,
        ),
        bodyLarge: ModernTypography.bodyLarge.copyWith(
          color: ModernColors.textInverse,
        ),
        bodyMedium: ModernTypography.bodyMedium.copyWith(
          color: ModernColors.textInverse,
        ),
        bodySmall: ModernTypography.bodySmall.copyWith(
          color: ModernColors.textTertiary,
        ),
        labelLarge: ModernTypography.labelLarge.copyWith(
          color: ModernColors.textInverse,
        ),
        labelMedium: ModernTypography.labelMedium.copyWith(
          color: ModernColors.textTertiary,
        ),
        labelSmall: ModernTypography.labelSmall.copyWith(
          color: ModernColors.textTertiary,
        ),
      ),
    );
  }
}
