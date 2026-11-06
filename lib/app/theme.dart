import 'package:flutter/material.dart';

abstract final class AppColors {
  static const mint = Color(0xFFEBF3EE);
  static const sage = Color(0xFF7A9082);
  static const sageDark = Color(0xFF5A6E62);
  static const sageLight = Color(0xFFA8BDB2);
  static const sagePale = Color(0xFFD4E4DA);
  static const textDark = Color(0xFF2C3A33);
  static const textMid = Color(0xFF4E6057);
  static const textLight = textMid;
  static const white = Color(0xFFFFFFFF);
  static const forest = Color(0xFF284C3B);
  static const ivory = Color(0xFFF7F5ED);
  static const courtTint = Color(0xFFDCE8BD);
  static const amberLight = Color(0xFFFDF0DC);
  static const amberDark = Color(0xFF8A5C0E);
  static const redLight = Color(0xFFFCE8E8);
  static const redDark = Color(0xFFA03030);
  static const greenLight = Color(0xFFE4F0E8);
  static const greenDark = Color(0xFF3D7A4E);
  static const blueLight = Color(0xFFE6F1FB);
  static const waitlistAmber = Color(0xFFFFF3CD);
  static const waitlistBorder = Color(0xFFF0C060);
  static const spotsFull = Color(0xFFC0392B);
  static const background = mint;
  static const surface = white;
  static const primary = sageDark;
  static const border = sagePale;
  static const textPrimary = textDark;
  static const textSecondary = textMid;
}

abstract final class AppSpacing {
  static const xs = 4.0, sm = 8.0, md = 12.0, lg = 16.0;
  static const xl = 24.0, xxl = 32.0, section = 40.0;
}

abstract final class AppRadii {
  static const control = 14.0, card = 20.0, feature = 28.0;
}

abstract final class AppMotion {
  static const fast = Duration(milliseconds: 140);
  static const standard = Duration(milliseconds: 220);
  static const entrance = Duration(milliseconds: 320);
  static const curve = Curves.easeOutCubic;
  static Duration duration(BuildContext context, Duration value) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : value;
}

abstract final class AppShadows {
  static const soft = [
    BoxShadow(color: Color(0x0A2C3A33), blurRadius: 28, offset: Offset(0, 8)),
  ];
}

abstract final class AppTextStyles {
  static const display = TextStyle(
    fontFamily: 'Manrope',
    fontVariations: [FontVariation('wght', 600)],
    fontSize: 34,
    height: 1.18,
    fontWeight: FontWeight.w600,
    letterSpacing: -1.3,
    color: AppColors.textDark,
  );
  static const logoTitle = TextStyle(
    fontFamily: 'Manrope',
    fontVariations: [FontVariation('wght', 700)],
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.5,
    color: AppColors.white,
  );
  static const screenTitle = TextStyle(
    fontFamily: 'Manrope',
    fontVariations: [FontVariation('wght', 600)],
    fontSize: 22,
    height: 1.3,
    fontWeight: FontWeight.w600,
    letterSpacing: -.6,
    color: AppColors.textDark,
  );
  static const modalTitle = TextStyle(
    fontFamily: 'Manrope',
    fontVariations: [FontVariation('wght', 600)],
    fontSize: 24,
    height: 1.3,
    fontWeight: FontWeight.w600,
    letterSpacing: -.6,
    color: AppColors.textDark,
  );
  static const statNumber = TextStyle(
    fontFamily: 'Manrope',
    fontVariations: [FontVariation('wght', 700)],
    fontSize: 30,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: -1,
    color: AppColors.forest,
  );
  static const sectionLabel = TextStyle(
    fontFamily: 'Inter',
    fontSize: 11,
    height: 1.5,
    fontWeight: FontWeight.w600,
    color: AppColors.textMid,
    letterSpacing: 1.1,
  );
  static const sessionTitle = TextStyle(
    fontFamily: 'Manrope',
    fontVariations: [FontVariation('wght', 600)],
    fontSize: 17,
    height: 1.4,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
    letterSpacing: -.3,
  );
  static const sessionMeta = TextStyle(
    fontFamily: 'Inter',
    fontSize: 13,
    height: 1.5,
    color: AppColors.textMid,
  );
  static const buttonPrimary = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    height: 1.4,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
  );
  static const buttonSecondary = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    height: 1.4,
    fontWeight: FontWeight.w600,
    color: AppColors.sageDark,
  );
  static const body = TextStyle(
    fontFamily: 'Inter',
    fontSize: 15,
    height: 1.55,
    color: AppColors.textDark,
  );
  static const chip = TextStyle(
    fontFamily: 'Inter',
    fontSize: 11,
    height: 1.4,
    fontWeight: FontWeight.w600,
  );
  static const navLabel = TextStyle(
    fontFamily: 'Inter',
    fontSize: 11,
    height: 1.3,
    fontWeight: FontWeight.w500,
  );
  static const formLabel = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    height: 1.5,
    fontWeight: FontWeight.w600,
    color: AppColors.textMid,
  );
  static const formInput = TextStyle(
    fontFamily: 'Inter',
    fontSize: 15,
    height: 1.5,
    color: AppColors.textDark,
  );
  static const priceTag = TextStyle(
    fontFamily: 'Inter',
    fontSize: 13,
    height: 1.4,
    fontWeight: FontWeight.w600,
    color: AppColors.forest,
  );
}

ThemeData buildAppTheme() {
  final shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadii.control),
  );
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.sageDark,
      primary: AppColors.sageDark,
      onPrimary: AppColors.white,
      secondary: AppColors.forest,
      surface: AppColors.white,
      onSurface: AppColors.textDark,
      error: AppColors.redDark,
      outline: AppColors.sage,
      outlineVariant: AppColors.sagePale,
    ),
    textTheme: const TextTheme(
      displaySmall: AppTextStyles.display,
      headlineMedium: AppTextStyles.modalTitle,
      titleLarge: AppTextStyles.screenTitle,
      titleMedium: AppTextStyles.sessionTitle,
      bodyLarge: AppTextStyles.body,
      bodyMedium: AppTextStyles.body,
      bodySmall: AppTextStyles.sessionMeta,
      labelLarge: AppTextStyles.buttonSecondary,
      labelSmall: AppTextStyles.chip,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.mint,
      foregroundColor: AppColors.textDark,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      toolbarHeight: 72,
      titleTextStyle: AppTextStyles.screenTitle,
    ),
    cardTheme: CardThemeData(
      color: AppColors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        shape: shape,
        textStyle: AppTextStyles.buttonPrimary,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.sageDark,
        foregroundColor: AppColors.white,
        disabledBackgroundColor: AppColors.sagePale,
        disabledForegroundColor: AppColors.textMid,
        minimumSize: const Size(48, 48),
        elevation: 0,
        shape: shape,
        textStyle: AppTextStyles.buttonPrimary,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: shape,
        foregroundColor: AppColors.forest,
        side: const BorderSide(color: AppColors.sagePale),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        foregroundColor: AppColors.forest,
        textStyle: AppTextStyles.buttonSecondary,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(48, 48),
        foregroundColor: AppColors.forest,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.white,
      labelStyle: AppTextStyles.formLabel,
      hintStyle: AppTextStyles.sessionMeta,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.sagePale),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.forest, width: 1.5),
      ),
      errorMaxLines: 3,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      constraints: BoxConstraints(maxWidth: 640),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: AppTextStyles.modalTitle,
    ),
    dividerTheme: const DividerThemeData(color: AppColors.sagePale, space: 24),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.sageDark,
      linearTrackColor: AppColors.sagePale,
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: AppColors.forest,
      unselectedLabelColor: AppColors.textMid,
      indicatorColor: AppColors.forest,
      dividerColor: AppColors.sagePale,
      labelStyle: AppTextStyles.buttonSecondary,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.forest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentTextStyle: AppTextStyles.body.copyWith(color: AppColors.white),
    ),
  );
}
