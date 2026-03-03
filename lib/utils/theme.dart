import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Purple Glassmorphism Palette
  static const Color deepPurple = Color(0xFF0D0D1A);
  static const Color purple1 = Color(0xFF1A0A2E);
  static const Color purple2 = Color(0xFF16213E);
  static const Color accentPurple = Color(0xFF7B2FBE);
  static const Color lightPurple = Color(0xFFAA6FE0);
  static const Color glowPurple = Color(0xFF9D4EDD);
  static const Color softPurple = Color(0xFFE0AAFF);

  static const Color successGreen = Color(0xFF00E676);
  static const Color dangerRed = Color(0xFFFF4569);
  static const Color goldAccent = Color(0xFFFFD700);

  static const Color glassWhite = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0D0);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: deepPurple,
      colorScheme: const ColorScheme.dark(
        primary: accentPurple,
        secondary: lightPurple,
        surface: purple1,
        background: deepPurple,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(
        ThemeData.dark().textTheme,
      ).apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: GoogleFonts.poppins(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
    );
  }
}