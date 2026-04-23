import 'package:flutter/material.dart';

class AppTheme {
  // 🎨 CONFIGURACIÓN DE COLORES CENTRALIZADA
  static const Color brandPrimary = Colors.deepPurple;
  static const Color brandBackground = Color(0xFFFEF7F7);
  static const Color brandSurface = Colors.white;
  static const Color brandSecondary = Color(0xFFE91E63);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: brandPrimary,
        primary: brandPrimary,
        surface: brandSurface,
      ),
      scaffoldBackgroundColor: brandBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: brandSurface,
        foregroundColor: brandPrimary,
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
    );
  }

  static ThemeData get darkTheme {
    return ThemeData.dark(useMaterial3: true).copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: brandPrimary,
        brightness: Brightness.dark,
      ),
    );
  }
}
