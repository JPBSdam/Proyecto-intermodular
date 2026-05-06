import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:app_restaurante/core/navigation/app_router.dart';
import 'package:app_restaurante/core/config/app_theme.dart';
import 'package:app_restaurante/core/widgets/fcm_init_wrapper.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // FcmInitWrapper envuelve toda la app para reaccionar a cambios de sesión:
    // - Al iniciar sesión → guarda el token FCM y escucha la cola de notificaciones
    // - Al cerrar sesión  → deja de escuchar la cola
    return FcmInitWrapper(
      child: MaterialApp.router(
        title: 'SabrosApp',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: appRouter,
        locale: const Locale('es', 'ES'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('es', 'ES'), Locale('en', 'US')],
      ),
    );
  }
}
