import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Clean Dark Palette ──────────────────────────────────
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF1E1E1E);
  static const Color surfaceVariant = Color(0xFF2A2A2A);
  static const Color primary = Color(0xFF5C8AFF);
  static const Color primaryLight = Color(0xFF89ABFF);
  static const Color accent = Color(0xFF5C8AFF);
  static const Color softAccent = Color(0xFFB8CFFF);

  static const Color successGreen = Color(0xFF4CAF50);
  static const Color dangerRed = Color(0xFFEF5350);
  static const Color goldAccent = Color(0xFFFFB74D);

  static const Color cardColor = Color(0xFF1E1E1E);
  static const Color cardBorder = Color(0xFF333333);
  static const Color textPrimary = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFF9E9E9E);

  // ── Legacy aliases (so existing code compiles) ──────────
  static const Color deepPurple = background;
  static const Color purple1 = surface;
  static const Color purple2 = surfaceVariant;
  static const Color accentPurple = primary;
  static const Color lightPurple = primaryLight;
  static const Color glowPurple = accent;
  static const Color softPurple = softAccent;
  static const Color glassWhite = cardColor;
  static const Color glassBorder = cardBorder;

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: primaryLight,
        surface: surface,
        background: background,
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