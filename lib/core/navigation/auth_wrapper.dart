import 'package:app_restaurante/services/auth_service.dart';
import 'package:app_restaurante/ui/views/auth/login_view.dart';
import 'package:app_restaurante/ui/views/home_screen.dart';
import 'package:app_restaurante/ui/viewmodels/home_viewmodel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Widget que gestiona la persistencia de sesión
/// Escucha los cambios en el estado de autenticación y redirige automáticamente
/// UBICACIÓN: core/navigation/ (lógica de routing, no es UI ni servicio)
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    try {
      final authService = AuthService();

      return StreamBuilder<User?>(
        stream: authService.authStateChanges,
        builder: (context, snapshot) {
          // Mientras se verifica el estado de autenticación
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // Si hay un usuario autenticado
          if (snapshot.hasData) {
            // TODO: Añadir lógica de redirección según rol (Admin -> Panel / Cliente -> Home)
            return ChangeNotifierProvider(
              create: (_) => HomeViewModel(),
              child: const HomeScreen(title: 'Restaurante'),
            );
          }

          // Si no hay usuario autenticado, mostrar login
          return const LoginView();
        },
      );
    } catch (e) {
      // En caso de error (ej: Firebase no inicializado en tests)
      return const Scaffold(
        body: Center(child: Text('Error al inicializar la aplicación')),
      );
    }
  }
}
