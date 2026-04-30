// lib/core/theme/app_theme.dart
// Material 3 theme with light/dark mode support

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ─── Brand Colors ──────────────────────────────────────────────────────────
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF1D4ED8);

  static const Color accentAmber = Color(0xFFF59E0B);
  static const Color successGreen = Color(0xFF10B981);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color warningOrange = Color(0xFFF97316);
  static const Color infoBlue = Color(0xFF06B6D4);

  // ─── Light Theme ──────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryBlue,
      brightness: Brightness.light,
      primary: primaryBlue,
      secondary: accentAmber,
      error: errorRed,
      surface: const Color(0xFFF8FAFC),
      onSurface: const Color(0xFF0F172A),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _buildTextTheme(Brightness.light),
      appBarTheme: _buildAppBarTheme(colorScheme, Brightness.light),
      cardTheme: _buildCardTheme(Brightness.light),
      elevatedButtonTheme: _buildElevatedButtonTheme(colorScheme),
      outlinedButtonTheme: _buildOutlinedButtonTheme(colorScheme),
      textButtonTheme: _buildTextButtonTheme(colorScheme),
      inputDecorationTheme: _buildInputDecorationTheme(colorScheme),
      bottomNavigationBarTheme: _buildBottomNavTheme(colorScheme, Brightness.light),
      floatingActionButtonTheme: _buildFABTheme(colorScheme),
      chipTheme: _buildChipTheme(colorScheme),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE2E8F0),
        thickness: 1,
      ),
      scaffoldBackgroundColor: const Color(0xFFF1F5F9),
      snackBarTheme: _buildSnackBarTheme(colorScheme),
    );
  }

  // ─── Dark Theme ───────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryBlue,
      brightness: Brightness.dark,
      primary: primaryLight,
      secondary: accentAmber,
      error: const Color(0xFFF87171),
      surface: const Color(0xFF1E293B),
      onSurface: const Color(0xFFF1F5F9),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _buildTextTheme(Brightness.dark),
      appBarTheme: _buildAppBarTheme(colorScheme, Brightness.dark),
      cardTheme: _buildCardTheme(Brightness.dark),
      elevatedButtonTheme: _buildElevatedButtonTheme(colorScheme),
      outlinedButtonTheme: _buildOutlinedButtonTheme(colorScheme),
      textButtonTheme: _buildTextButtonTheme(colorScheme),
      inputDecorationTheme: _buildInputDecorationTheme(colorScheme),
      bottomNavigationBarTheme: _buildBottomNavTheme(colorScheme, Brightness.dark),
      floatingActionButtonTheme: _buildFABTheme(colorScheme),
      chipTheme: _buildChipTheme(colorScheme),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF334155),
        thickness: 1,
      ),
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      snackBarTheme: _buildSnackBarTheme(colorScheme),
    );
  }

  // ─── Text Theme ───────────────────────────────────────────────────────────
  static TextTheme _buildTextTheme(Brightness brightness) {
    final baseColor = brightness == Brightness.light
        ? const Color(0xFF0F172A)
        : const Color(0xFFF1F5F9);
    final subtleColor = brightness == Brightness.light
        ? const Color(0xFF475569)
        : const Color(0xFF94A3B8);

    return TextTheme(
      displayLarge: GoogleFonts.poppins(
        fontSize: 57, fontWeight: FontWeight.w700, color: baseColor,
      ),
      displayMedium: GoogleFonts.poppins(
        fontSize: 45, fontWeight: FontWeight.w700, color: baseColor,
      ),
      displaySmall: GoogleFonts.poppins(
        fontSize: 36, fontWeight: FontWeight.w600, color: baseColor,
      ),
      headlineLarge: GoogleFonts.poppins(
        fontSize: 32, fontWeight: FontWeight.w600, color: baseColor,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: 28, fontWeight: FontWeight.w600, color: baseColor,
      ),
      headlineSmall: GoogleFonts.poppins(
        fontSize: 24, fontWeight: FontWeight.w600, color: baseColor,
      ),
      titleLarge: GoogleFonts.poppins(
        fontSize: 22, fontWeight: FontWeight.w600, color: baseColor,
      ),
      titleMedium: GoogleFonts.poppins(
        fontSize: 16, fontWeight: FontWeight.w500, color: baseColor,
      ),
      titleSmall: GoogleFonts.poppins(
        fontSize: 14, fontWeight: FontWeight.w500, color: baseColor,
      ),
      bodyLarge: GoogleFonts.poppins(
        fontSize: 16, fontWeight: FontWeight.w400, color: baseColor,
      ),
      bodyMedium: GoogleFonts.poppins(
        fontSize: 14, fontWeight: FontWeight.w400, color: baseColor,
      ),
      bodySmall: GoogleFonts.poppins(
        fontSize: 12, fontWeight: FontWeight.w400, color: subtleColor,
      ),
      labelLarge: GoogleFonts.poppins(
        fontSize: 14, fontWeight: FontWeight.w600, color: baseColor,
      ),
      labelMedium: GoogleFonts.poppins(
        fontSize: 12, fontWeight: FontWeight.w500, color: subtleColor,
      ),
      labelSmall: GoogleFonts.poppins(
        fontSize: 11, fontWeight: FontWeight.w500, color: subtleColor,
      ),
    );
  }

  static AppBarTheme _buildAppBarTheme(ColorScheme cs, Brightness brightness) {
    return AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: brightness == Brightness.light
          ? Colors.white
          : const Color(0xFF1E293B),
      foregroundColor: cs.onSurface,
      centerTitle: false,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: cs.onSurface,
      ),
    );
  }

  static CardTheme _buildCardTheme(Brightness brightness) {
    return CardTheme(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: brightness == Brightness.light
              ? const Color(0xFFE2E8F0)
              : const Color(0xFF334155),
          width: 1,
        ),
      ),
      color: brightness == Brightness.light
          ? Colors.white
          : const Color(0xFF1E293B),
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme(ColorScheme cs) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: cs.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    );
  }

  static OutlinedButtonThemeData _buildOutlinedButtonTheme(ColorScheme cs) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: cs.primary,
        side: BorderSide(color: cs.primary, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    );
  }

  static TextButtonThemeData _buildTextButtonTheme(ColorScheme cs) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: cs.primary,
        textStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }

  static InputDecorationTheme _buildInputDecorationTheme(ColorScheme cs) {
    return InputDecorationTheme(
      filled: true,
      fillColor: cs.brightness == Brightness.light
          ? const Color(0xFFF8FAFC)
          : const Color(0xFF0F172A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.outline.withOpacity(0.5)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.outline.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: GoogleFonts.poppins(fontSize: 14),
      hintStyle: GoogleFonts.poppins(fontSize: 14, color: cs.onSurface.withOpacity(0.5)),
    );
  }

  static BottomNavigationBarThemeData _buildBottomNavTheme(
      ColorScheme cs, Brightness brightness) {
    return BottomNavigationBarThemeData(
      backgroundColor: brightness == Brightness.light
          ? Colors.white
          : const Color(0xFF1E293B),
      selectedItemColor: cs.primary,
      unselectedItemColor: cs.onSurface.withOpacity(0.5),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600),
      unselectedLabelStyle: GoogleFonts.poppins(fontSize: 11),
    );
  }

  static FloatingActionButtonThemeData _buildFABTheme(ColorScheme cs) {
    return FloatingActionButtonThemeData(
      backgroundColor: cs.primary,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  static ChipThemeData _buildChipTheme(ColorScheme cs) {
    return ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      labelStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
    );
  }

  static SnackBarThemeData _buildSnackBarTheme(ColorScheme cs) {
    return SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
