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
                icon: const Icon(Icons.logout),
                tooltip: 'Cerrar Sesión',
                onPressed: () async {
                  final success = await viewModel.signOut();
                  if (!success) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(viewModel.errorMessage),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                  // Si success = true, AuthWrapper redirige automáticamente
                },
              ),
            ],
          ),
          body: _buildBody(viewModel),
        );
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
          // Banner de usuario anónimo
          if (viewModel.isAnonymous)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Estás navegando como invitado. Algunas funciones están limitadas.',
                      style: TextStyle(color: Colors.deepOrange),
                    ),
                  ),
                ],
              ),
            ),

          // Información del usuario autenticado
          if (viewModel.currentUser != null && !viewModel.isAnonymous)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Icon(Icons.account_circle, size: 80),
                  const SizedBox(height: 8),
                  Text(
                    '¡Hola! ¿Qué te apetece comer?',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    viewModel.displayName,
                    style: Theme.of(context).textTheme.bodyMedium,
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
