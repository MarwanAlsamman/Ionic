import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ── Brand Colors ─────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF6C63FF);       // Purple
  static const Color primaryDark = Color(0xFF4C47CC);
  static const Color secondary = Color(0xFF00D4AA);     // Teal
  static const Color accent = Color(0xFFFF6B6B);        // Coral
  static const Color warning = Color(0xFFFFBE0B);       // Yellow
  static const Color success = Color(0xFF2ECC71);       // Green
  static const Color error = Color(0xFFE74C3C);         // Red

  // ── Background ───────────────────────────────────────────────────────────
  static const Color backgroundDark = Color(0xFF1A1A2E);
  static const Color backgroundCard = Color(0xFF16213E);
  static const Color backgroundElevated = Color(0xFF0F3460);

  // ── Answer Button Colors ─────────────────────────────────────────────────
  static const Color optionA = Color(0xFF4361EE);
  static const Color optionB = Color(0xFF7209B7);
  static const Color optionC = Color(0xFF3A0CA3);
  static const Color optionD = Color(0xFF560BAD);

  // ── Text ─────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0BEC5);

  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: backgroundDark,
        colorScheme: const ColorScheme.dark(
          primary: primary,
          secondary: secondary,
          error: error,
          surface: backgroundCard,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(
          ThemeData.dark().textTheme,
        ).copyWith(
          displayLarge: GoogleFonts.poppins(
            fontSize: 32, fontWeight: FontWeight.bold, color: textPrimary,
          ),
          displayMedium: GoogleFonts.poppins(
            fontSize: 24, fontWeight: FontWeight.bold, color: textPrimary,
          ),
          titleLarge: GoogleFonts.poppins(
            fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary,
          ),
          bodyLarge: GoogleFonts.poppins(
            fontSize: 16, color: textPrimary,
          ),
          bodyMedium: GoogleFonts.poppins(
            fontSize: 14, color: textSecondary,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: GoogleFonts.poppins(
              fontSize: 16, fontWeight: FontWeight.w600,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: backgroundCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primary, width: 2),
          ),
          hintStyle: const TextStyle(color: textSecondary),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        cardTheme: CardThemeData(
          color: backgroundCard,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: backgroundDark,
          elevation: 0,
          centerTitle: true,
          foregroundColor: textPrimary,
        ),
      );
}
