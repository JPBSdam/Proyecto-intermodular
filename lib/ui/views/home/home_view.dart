import 'package:app_restaurante/core/navigation/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:app_restaurante/ui/viewmodels/home/home_viewmodel.dart';

/// Pantalla principal de la aplicación
/// Muestra información del usuario, indica si es anónimo,
/// permite navegar a la lista de platos y menús,
/// y proporciona la opción de cerrar sesión.
/// La lógica de negocio y estado se maneja mediante HomeViewModel.

class HomeView extends StatefulWidget {
  const HomeView({super.key, this.title = 'SabrosApp'});

  final String title;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            title: Text(widget.title),
            actions: [
              IconButton(
                icon: const Icon(Icons.account_circle),
                tooltip: 'Perfil',
                onPressed: () => _showProfileSheet(context, viewModel),
              ),
            ],
          ),
          body: _buildBody(viewModel),
        );
      },
    );
  }

  /// Muestra un bottom sheet diferente según el estado de autenticación:
  /// - Invitado / anónimo → opciones para iniciar sesión o registrarse
  /// - Autenticado → nombre/email y opción de cerrar sesión
  void _showProfileSheet(BuildContext context, HomeViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        if (viewModel.isGuest) {
          // ── Invitado / anónimo ──────────────────────────────────────
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.account_circle_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Accede a tu cuenta',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Inicia sesión o regístrate para gestionar tus reservas y perfil.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.go(AppRoutes.login);
                    },
                    child: const Text('Iniciar Sesión'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.go(AppRoutes.register);
                    },
                    child: const Text('Registrarse'),
                  ),
                ),
              ],
            ),
          );
        } else {
          // ── Usuario autenticado ─────────────────────────────────────
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.account_circle, size: 64),
                const SizedBox(height: 8),
                Text(
                  viewModel.displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text(
                      'Cerrar Sesión',
                      style: TextStyle(color: Colors.red),
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      final success = await viewModel.signOut();
                      if (!success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(viewModel.errorMessage),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildBody(HomeViewModel viewModel) {
    // Mostrar indicador de carga
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Mostrar error si existe
    if (viewModel.errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(viewModel.errorMessage),
            const SizedBox(height: 16),
          ],
        ),
      );
    }

    // Mostrar contenido principal
    return SingleChildScrollView(
      child: Column(
        children: [
          // Saludo personalizado si está autenticado con cuenta real
          if (!viewModel.isGuest)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Icon(Icons.account_circle, size: 80),
                  const SizedBox(height: 8),
                  Text(
                    '¡Hola, ${viewModel.displayName}!',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    '¿Qué te apetece comer hoy?',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),

          // Banner informativo para invitados (anónimos o sin cuenta)
          if (viewModel.isGuest)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Explora nuestra carta sin cuenta. ¡Inicia sesión para reservar!',
                      style: TextStyle(color: Colors.deepOrange),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.login),
                    child: const Text('Entrar'),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.restaurant),
                    label: const Text("Ver Platos"),
                    onPressed: () {
                      context.go(AppRoutes.dishes);
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.menu_book),
                    label: const Text("Ver Menús"),
                    onPressed: () {
                      context.go(AppRoutes.menus);
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.menu_book),
                    label: const Text("Ver Mi perfil"),
                    onPressed: () {
                      context.go(AppRoutes.profile);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
