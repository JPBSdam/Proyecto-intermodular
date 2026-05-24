import 'package:flutter/material.dart';

class AppTheme {
  static const double kFormMaxWidth = 480.0;
  static const double kContentMaxWidth = 800.0;

  static double webHPad(
    BuildContext context, {
    double maxWidth = kContentMaxWidth,
  }) {
    final w = MediaQuery.sizeOf(context).width;
    return w > maxWidth ? (w - maxWidth) / 2.0 : 0.0;
  }

  // 🎨 CONFIGURACIÓN DE COLORES CENTRALIZADA
  static const Color brandPrimary = Color(0xFF494E2C);
  static const Color brandBackground = Color(0xFFFDEADF);
  static const Color brandSurface = Colors.white;
  static const Color brandSecondary = Color(0xFFF1B35D);
  static const Color brandDetail = Color(0xFFC88181);
  static const Color brandSuccess = Color(0xFF2E7D32);
  static const Color brandError = Color(0xFFB00020);
  static const Color brandWarning = Color(0xFFED6C02);
  static const Color brandInfo = Color(0xFF0288D1);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: brandPrimary,
        primary: brandPrimary,
        secondary: brandSecondary,
        surface: brandSurface,
        error: brandError,
        tertiary: brandSuccess,
      ),
      scaffoldBackgroundColor: brandBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: brandBackground,
        foregroundColor: brandPrimary,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: brandPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 2,
        ),
      ),
      cardTheme: const CardThemeData(color: brandSurface, elevation: 0),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: brandPrimary,
        foregroundColor: brandSecondary,
        elevation: 3,
      ),
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: brandPrimary,
      brightness: Brightness.dark,
      secondary: brandSecondary,
      error: brandError,
      tertiary: brandSuccess,
    );

    return ThemeData.dark(useMaterial3: true).copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF12140B),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF12140B),
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 2,
        ),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainer,
        elevation: 0,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.secondary,
        elevation: 3,
      ),
    );
  }
}
