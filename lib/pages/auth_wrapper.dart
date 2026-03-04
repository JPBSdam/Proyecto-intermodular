import 'package:app_restaurante/pages/home_page.dart';
import 'package:app_restaurante/pages/login_page.dart';
import 'package:app_restaurante/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Widget que gestiona la persistencia de sesión
/// Escucha los cambios en el estado de autenticación y redirige automáticamente
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Mientras se verifica el estado de autenticación
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Si hay un usuario autenticado
        if (snapshot.hasData) {
          // Aquí más adelante puedes añadir lógica para redirigir según el rol
          // Por ahora, todos van al HomePage
          return const MyHomePage(title: 'Restaurante');
        }

        // Si no hay usuario autenticado, mostrar login
        return const LoginPage();
      },
    );
  }
}

