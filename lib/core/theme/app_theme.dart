import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import '../utils/responsive_text.dart';
import '../utils/responsive_spacing.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.error,
        background: AppColors.background,
      ),
      // ใช้ Google Fonts แต่ไม่กำหนดขนาดฟอนต์เพื่อให้ responsive system จัดการ
      textTheme: _buildTextTheme(),
      appBarTheme: _buildAppBarTheme(),
      elevatedButtonTheme: _buildElevatedButtonTheme(),
      outlinedButtonTheme: _buildOutlinedButtonTheme(),
      cardTheme: _buildCardTheme(),
      inputDecorationTheme: _buildInputDecorationTheme(),
    );
  }

  /// สร้าง TextTheme แบบ dynamic (ไม่มีขนาดฟอนต์คงที่)
  static TextTheme _buildTextTheme() {
    return GoogleFonts.promptTextTheme().copyWith(
      // จะใช้ responsive system ในการคำนวณขนาดจริง
      displayLarge: GoogleFonts.prompt(
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
      headlineMedium: GoogleFonts.prompt(
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      bodyLarge: GoogleFonts.prompt(
        fontWeight: FontWeight.normal,
        color: AppColors.textPrimary,
      ),
      bodyMedium: GoogleFonts.prompt(
        fontWeight: FontWeight.normal,
        color: AppColors.textSecondary,
      ),
      labelLarge: GoogleFonts.prompt(
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),
    );
  }

  /// AppBar Theme แบบ responsive
  static AppBarTheme _buildAppBarTheme() {
    return AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.prompt(
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  /// ElevatedButton Theme แบบ responsive
  static ElevatedButtonThemeData _buildElevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        // ไม่กำหนด padding คงที่ จะใช้ responsive system
        textStyle: GoogleFonts.prompt(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// OutlinedButton Theme แบบ responsive
  static OutlinedButtonThemeData _buildOutlinedButtonTheme() {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        // ไม่กำหนด padding คงที่ จะใช้ responsive system
        textStyle: GoogleFonts.prompt(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Card Theme แบบ responsive
  static CardThemeData _buildCardTheme() {
    return CardThemeData(
      color: AppColors.surface,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      // ไม่กำหนด margin คงที่ จะใช้ responsive system
    );
  }

  /// InputDecoration Theme แบบ responsive
  static InputDecorationTheme _buildInputDecorationTheme() {
    return InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      labelStyle: GoogleFonts.prompt(color: AppColors.textSecondary),
      floatingLabelStyle: GoogleFonts.prompt(color: AppColors.primary),
      // ไม่กำหนด padding คงที่ จะใช้ responsive system
    );
  }

  /// Helper method สำหรับสร้าง responsive button style
  static ButtonStyle responsiveButtonStyle(BuildContext context, {
    Color? backgroundColor,
    Color? foregroundColor,
    double? borderRadius,
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor ?? AppColors.primary,
      foregroundColor: foregroundColor ?? Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius ?? 12),
      ),
      padding: ResponsiveSpacing.buttonPadding(context),
      textStyle: GoogleFonts.prompt(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  /// Helper method สำหรับสร้าง responsive card style
  static CardThemeData responsiveCardTheme(BuildContext context) {
    return CardThemeData(
      color: AppColors.surface,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: ResponsiveSpacing.custom(context, 8),
    );
  }

  /// Helper method สำหรับสร้าง responsive input decoration
  static InputDecorationTheme responsiveInputDecorationTheme(BuildContext context) {
    return InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: ResponsiveSpacing.formFieldPadding(context),
      labelStyle: GoogleFonts.prompt(color: AppColors.textSecondary),
      floatingLabelStyle: GoogleFonts.prompt(color: AppColors.primary),
    );
  }
}
