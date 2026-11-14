import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Fonte única de cores, tipografia e componentes do app.
/// Telas e widgets NÃO devem declarar cores/estilos de texto próprios.
class NiceTheme {
  NiceTheme._();

  // ---- Cores ----
  static const red = Color(0xFFB50000);
  static const brightRed = Color(0xFFE01414);
  static const darkRed = Color(0xFF750000);
  static const black = Color(0xFF0B0B0C);
  static const charcoal = Color(0xFF202020);
  static const softGray = Color(0xFFE8E8E8);
  static const lightGray = Color(0xFFF4F4F4);
  static const midGray = Color(0xFF858585);
  static const textGray = Color(0xFF777777);
  static const white = Color(0xFFFFFFFF);
  static const success = Color(0xFF1B7F3B);
  static const transparent = Color(0x00000000);

  // ---- Medidas ----
  static const radius = 8.0;
  static const pillRadius = 28.0;
  static const maxContentWidth = 1280.0;
  static const tabletBreakpoint = 640.0;
  static const desktopBreakpoint = 1024.0;

  // ---- Gradientes e sombras ----
  static const heroOverlay = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xCC000000), Color(0x00000000)],
  );
  static const bottomOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x00000000), Color(0xCC000000)],
  );
  static const topShadow = [
    BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, -8)),
  ];
  static const softShadow = [
    BoxShadow(color: Color(0x1F000000), blurRadius: 8, offset: Offset(0, 4)),
  ];

  // ---- Tipografia ----
  static TextStyle _display(double size, {FontWeight weight = FontWeight.w900, double height = 1.05, double spacing = -0.5}) =>
      GoogleFonts.archivo(fontSize: size, fontWeight: weight, height: height, letterSpacing: spacing, color: charcoal);

  static TextStyle _body(double size, {FontWeight weight = FontWeight.w400, Color color = charcoal, double height = 1.45, double spacing = 0}) =>
      GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color, height: height, letterSpacing: spacing);

  static TextTheme _textTheme() {
    return TextTheme(
      displayLarge: _display(72),
      displayMedium: _display(52),
      displaySmall: _display(34),
      headlineLarge: _display(32, weight: FontWeight.w800),
      headlineMedium: _display(26, weight: FontWeight.w800),
      headlineSmall: _display(22, weight: FontWeight.w800),
      titleLarge: _display(18, weight: FontWeight.w800, height: 1.2, spacing: 0),
      titleMedium: _body(16, weight: FontWeight.w800, color: red),
      titleSmall: _body(14, weight: FontWeight.w700),
      bodyLarge: _body(16, height: 1.55),
      bodyMedium: _body(14),
      bodySmall: _body(12, color: textGray),
      labelLarge: _body(14, weight: FontWeight.w700, spacing: 0.4),
      labelMedium: _body(12, weight: FontWeight.w700, color: red, spacing: 1.2),
      labelSmall: _body(10, weight: FontWeight.w600, color: textGray),
    );
  }

  static TextStyle chipLabel({required bool selected}) =>
      _body(13, weight: FontWeight.w700, color: selected ? white : textGray);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: red,
      primary: red,
      secondary: charcoal,
      surface: white,
      error: brightRed,
    );
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide.none,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: white,
      textTheme: _textTheme(),
      dividerTheme: const DividerThemeData(color: softGray, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: white,
        foregroundColor: charcoal,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: _display(18, weight: FontWeight.w800, spacing: 0),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: red,
          foregroundColor: white,
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
          textStyle: _body(14, weight: FontWeight.w800, spacing: 0.6),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: charcoal,
          minimumSize: const Size(0, 52),
          side: const BorderSide(color: softGray, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
          textStyle: _body(14, weight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: red,
          textStyle: _body(13, weight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightGray,
        hintStyle: _body(14, color: textGray),
        labelStyle: _body(14, color: textGray),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: red, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: brightRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: brightRed, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: lightGray,
        selectedColor: red,
        showCheckmark: false,
        side: BorderSide.none,
        labelStyle: chipLabel(selected: false),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(pillRadius)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? white : midGray,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? red : softGray,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(transparent),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: charcoal,
        contentTextStyle: _body(14, color: white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: white,
        titleTextStyle: _display(20, weight: FontWeight.w800, spacing: 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: white,
        showDragHandle: true,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: red),
      sliderTheme: const SliderThemeData(
        activeTrackColor: red,
        thumbColor: red,
        inactiveTrackColor: softGray,
        overlayColor: Color(0x1FB50000),
      ),
      radioTheme: const RadioThemeData(fillColor: WidgetStatePropertyAll(red)),
      bottomAppBarTheme: const BottomAppBarThemeData(color: red, surfaceTintColor: transparent),
    );
  }
}
