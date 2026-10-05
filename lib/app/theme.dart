import 'package:flutter/material.dart';

class AppColors {
  static const forest = Color(0xFF173F35);
  static const lime = Color(0xFFD9EF9F);
  static const peach = Color(0xFFF0C6AE);
  static const border = Color(0xFFE4E8E0);
  static const mint = Color(0xFFF6F5EF);
  static const sage = Color(0xFF7A9082);
  static const sageDark = Color(0xFF173F35);
  static const sageLight = Color(0xFFA8BDB2);
  static const sagePale = Color(0xFFD4E4DA);
  static const textDark = Color(0xFF173F35);
  static const textMid = Color(0xFF4E6057);
  static const textLight = Color(0xFF7A9082);
  static const white = Color(0xFFFFFFFF);
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
}

class AppTextStyles {
  static TextStyle get logoTitle => const TextStyle(
        fontFamily: 'FlexSerif',
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.white,
      );

  static TextStyle get screenTitle => const TextStyle(
        fontFamily: 'FlexSerif',
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      );

  static TextStyle get modalTitle => const TextStyle(
        fontFamily: 'FlexSerif',
        fontSize: 26,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      );

  static TextStyle get statNumber => const TextStyle(
        fontFamily: 'FlexSerif',
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.sageDark,
      );

  static TextStyle get sectionLabel => const TextStyle(
        fontFamily: 'FlexSans',
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.sage,
        letterSpacing: 0.8,
      );

  static TextStyle get sessionTitle => const TextStyle(
        fontFamily: 'FlexSans',
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      );

  static TextStyle get sessionMeta => const TextStyle(
        fontFamily: 'FlexSans',
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.sage,
      );

  static TextStyle get buttonPrimary => const TextStyle(
        fontFamily: 'FlexSans',
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.white,
      );

  static TextStyle get buttonSecondary => const TextStyle(
        fontFamily: 'FlexSans',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.sageDark,
      );

  static TextStyle get body => const TextStyle(
        fontFamily: 'FlexSans',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textDark,
      );

  static TextStyle get chip => const TextStyle(
      fontFamily: 'FlexSans', fontSize: 11, fontWeight: FontWeight.w600);

  static TextStyle get navLabel => const TextStyle(
      fontFamily: 'FlexSans', fontSize: 10, fontWeight: FontWeight.w400);

  static TextStyle get formLabel => const TextStyle(
        fontFamily: 'FlexSans',
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.sage,
        letterSpacing: 0.8,
      );

  static TextStyle get formInput => const TextStyle(
        fontFamily: 'FlexSans',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textDark,
      );

  static TextStyle get priceTag => const TextStyle(
        fontFamily: 'FlexSans',
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: AppColors.sageDark,
      );
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.mint,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.sageDark,
      primary: AppColors.sageDark,
      secondary: AppColors.sage,
      surface: AppColors.white,
    ),
    textTheme: ThemeData.light().textTheme.apply(fontFamily: 'FlexSans'),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.mint,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        minimumSize: const Size(48, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: AppColors.mint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        borderSide: BorderSide(color: AppColors.sagePale),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        borderSide: BorderSide(color: AppColors.sagePale),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        borderSide: BorderSide(color: AppColors.sage, width: 1.2),
      ),
    ),
  );
}
