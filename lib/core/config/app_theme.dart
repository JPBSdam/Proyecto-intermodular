import 'package:flutter/material.dart';

class AppTheme {
  // 🎨 CONFIGURACIÓN DE COLORES CENTRALIZADA
  static const Color brandPrimary = Color(0xFF6750A4);
  static const Color brandBackground = Color(0xFFFEF7F7);
  static const Color brandSurface = Colors.white;
  static const Color brandSecondary = Color(0xFFE91E63);
  static const Color brandSuccess = Color(0xFF2E7D32); // Verde esmeralda
  static const Color brandError = Color(0xFFB00020); // Rojo error
  static const Color brandWarning = Color(0xFFED6C02); // Naranja aviso
  static const Color brandInfo = Color(0xFF0288D1); // Azul info

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: brandPrimary,
        primary: brandPrimary,
        secondary: brandSecondary,
        surface: brandSurface,
        error: brandError,
        tertiary: brandSuccess, // Usamos tertiary para éxito por defecto
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
