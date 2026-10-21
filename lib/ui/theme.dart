import 'package:flutter/material.dart';

/// Neon "code arena" dark theme, friendly for kids.
class AppTheme {
  static const bg = Color(0xFF0E1420);
  static const bgAlt = Color(0xFF151E30);
  static const card = Color(0xFF1B2740);
  static const cardEdge = Color(0xFF2A3A5E);
  static const accent = Color(0xFF4CC2FF);
  static const accent2 = Color(0xFFFFC94D);
  static const good = Color(0xFF4ADE80);
  static const bad = Color(0xFFFF6B6B);
  static const textHi = Color(0xFFF1F5FF);
  static const textLo = Color(0xFF9AA7C7);

  static ThemeData get theme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        colorScheme: const ColorScheme.dark(
          primary: accent,
          secondary: accent2,
          surface: card,
          error: bad,
          onSurface: textHi,
        ),
        cardTheme: CardThemeData(
          color: card,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: cardEdge),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: bgAlt,
          foregroundColor: textHi,
          elevation: 0,
          centerTitle: false,
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: card,
          contentTextStyle: TextStyle(color: textHi),
        ),
        dividerColor: cardEdge,
        useMaterial3: true,
      );
}
