import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_styles.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryBlue,
        onPrimary: AppColors.textWhite,
        primaryContainer: AppColors.primaryLight,
        onPrimaryContainer: AppColors.primaryDark,
        surface: AppColors.cardSurface,
        onSurface: AppColors.textDark,
        error: AppColors.absentRed,
        onError: AppColors.textWhite,
      ),
      textTheme: baseTextTheme.copyWith(
        headlineLarge: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
          letterSpacing: -0.3,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: AppColors.textDark,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textDark,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppStyles.cardBorderRadius,
          side: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: AppColors.textWhite,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: AppStyles.buttonBorderRadius,
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
          side: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: AppStyles.buttonBorderRadius,
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: AppStyles.cardBorderRadius,
          borderSide: const BorderSide(color: AppColors.borderLight, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppStyles.cardBorderRadius,
          borderSide: const BorderSide(color: AppColors.borderLight, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppStyles.cardBorderRadius,
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppStyles.cardBorderRadius,
          borderSide: const BorderSide(color: AppColors.absentRed, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppStyles.cardBorderRadius,
          borderSide: const BorderSide(color: AppColors.absentRed, width: 1.8),
        ),
        hintStyle: GoogleFonts.inter(
          color: AppColors.textMuted,
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.inter(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.cardSurface,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}
