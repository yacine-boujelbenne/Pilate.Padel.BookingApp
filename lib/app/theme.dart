import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const mint = Color(0xFFEBF3EE);
  static const sage = Color(0xFF7A9082);
  static const sageDark = Color(0xFF5A6E62);
  static const sageLight = Color(0xFFA8BDB2);
  static const sagePale = Color(0xFFD4E4DA);
  static const textDark = Color(0xFF2C3A33);
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
  static TextStyle get logoTitle => GoogleFonts.notoSerif(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.white,
  );

  static TextStyle get screenTitle => GoogleFonts.notoSerif(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: AppColors.textDark,
  );

  static TextStyle get modalTitle => GoogleFonts.notoSerif(
    fontSize: 20,
    fontWeight: FontWeight.w400,
    color: AppColors.textDark,
  );

  static TextStyle get statNumber => GoogleFonts.notoSerif(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.sageDark,
  );

  static TextStyle get sectionLabel => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.sage,
    letterSpacing: 0.8,
  );

  static TextStyle get sessionTitle => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );

  static TextStyle get sessionMeta => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.sage,
  );

  static TextStyle get buttonPrimary => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
  );

  static TextStyle get buttonSecondary => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.sageDark,
  );

  static TextStyle get body => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textDark,
  );

  static TextStyle get chip =>
      GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600);

  static TextStyle get navLabel =>
      GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w400);

  static TextStyle get formLabel => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.sage,
    letterSpacing: 0.8,
  );

  static TextStyle get formInput => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textDark,
  );

  static TextStyle get priceTag => GoogleFonts.inter(
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
    textTheme: GoogleFonts.interTextTheme(),
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
