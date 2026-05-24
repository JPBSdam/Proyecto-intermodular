import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:app_restaurante/core/navigation/app_router.dart';
import 'package:app_restaurante/core/config/app_theme.dart';
import 'package:app_restaurante/core/widgets/fcm_init_wrapper.dart';
import 'package:app_restaurante/ui/viewmodels/theme_viewmodel.dart';
import 'package:provider/provider.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeViewModel>().themeMode;
    return FcmInitWrapper(
      child: MaterialApp.router(
        title: 'SabrosApp',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
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
