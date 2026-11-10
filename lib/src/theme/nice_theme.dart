import 'package:flutter/material.dart';

class NiceTheme {
  static const red = Color(0xFFB50000);
  static const darkRed = Color(0xFF750000);
  static const charcoal = Color(0xFF202020);
  static const softGray = Color(0xFFE8E8E8);
  static const textGray = Color(0xFF777777);

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: red,
        primary: red,
        secondary: charcoal,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: Colors.white,
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontWeight: FontWeight.w800, color: textGray),
        titleLarge: TextStyle(fontWeight: FontWeight.w800, color: charcoal),
        titleMedium: TextStyle(fontWeight: FontWeight.w800, color: red),
        bodySmall: TextStyle(color: textGray),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.68),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      ),
    );
  }
}
