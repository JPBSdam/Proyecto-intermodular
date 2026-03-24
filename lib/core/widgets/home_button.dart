import 'package:app_restaurante/core/navigation/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Botón que te lleva a home

class HomeButton extends StatelessWidget {
  const HomeButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.home),
      tooltip: 'Ir al inicio',
      onPressed: () {
        context.go(AppRoutes.home);
      },
    );
  }
}
