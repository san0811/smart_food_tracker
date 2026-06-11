import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFF050505);
  static const Color panel = Color(0xFF111111);
  static const Color panelSoft = Color(0xFF1A1A1A);
  static const Color surface = Color(0xFFF5F1EA);
  static const Color surfaceMuted = Color(0xFFE6DED2);
  static const Color actionBlue = Color(0xFFD6B58A);
  static const Color actionBlueOnDark = Color(0xFFF3E3B3);
  static const Color accent = Color(0xFFD6B58A);
  static const Color success = Color(0xFF8DB596);
  static const Color warning = Color(0xFFE5C07B);

  static ThemeData get darkTheme {
    const scheme = ColorScheme.dark(
      primary: surface,
      secondary: accent,
      surface: panel,
      error: Color(0xFFE06C75),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Color(0xFFF1ECE3),
          height: 1.45,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Color(0xFFB9B2A8),
          height: 1.5,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: panel,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(34),
          side: const BorderSide(color: Color(0x14FFFFFF)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: panelSoft,
        hintStyle: const TextStyle(color: Color(0xFF8A857D)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(26),
          borderSide: const BorderSide(color: Color(0x22FFFFFF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(26),
          borderSide: const BorderSide(color: Color(0x22FFFFFF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(26),
          borderSide: const BorderSide(color: surface),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: actionBlue,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size.square(44),
          shape: const CircleBorder(),
        ),
      ),
    );
  }
}
