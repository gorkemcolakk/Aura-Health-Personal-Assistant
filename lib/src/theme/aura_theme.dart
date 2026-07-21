import 'package:flutter/material.dart';

class AuraTheme {
  static ThemeData light() {
    const ink = Color(0xFF172026);
    const teal = Color(0xFF1A8C83);
    const coral = Color(0xFFE76F51);
    const mist = Color(0xFFF4F7F4);

    final scheme = ColorScheme.fromSeed(
      seedColor: teal,
      brightness: Brightness.light,
      primary: teal,
      secondary: coral,
      surface: Colors.white,
      onSurface: ink,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: mist,
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontWeight: FontWeight.w800, height: 1.05),
        headlineMedium: TextStyle(fontWeight: FontWeight.w800, height: 1.1),
        titleLarge: TextStyle(fontWeight: FontWeight.w800),
        titleMedium: TextStyle(fontWeight: FontWeight.w700),
        bodyLarge: TextStyle(height: 1.35),
        bodyMedium: TextStyle(height: 1.35),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: ink.withValues(alpha: .10)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: ink.withValues(alpha: .10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: teal, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  static ThemeData dark() {
    const teal = Color(0xFF1A8C83);
    const coral = Color(0xFFE76F51);
    const background = Color(0xFF121212);
    const surface = Color(0xFF1E1E1E);

    final scheme = ColorScheme.fromSeed(
      seedColor: teal,
      brightness: Brightness.dark,
      primary: teal,
      secondary: coral,
      surface: surface,
      onSurface: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontWeight: FontWeight.w800, height: 1.05),
        headlineMedium: TextStyle(fontWeight: FontWeight.w800, height: 1.1),
        titleLarge: TextStyle(fontWeight: FontWeight.w800),
        titleMedium: TextStyle(fontWeight: FontWeight.w700),
        bodyLarge: TextStyle(height: 1.35),
        bodyMedium: TextStyle(height: 1.35),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: .10)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: .10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: teal, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
