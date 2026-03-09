import 'package:app_restaurante/pages/auth_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:app_restaurante/core/navigation/app_router.dart';
import 'package:app_restaurante/core/config/app_theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SabrosApp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      home: const AuthWrapper(), // Gestionar la Persistencia
    );
  }
}
