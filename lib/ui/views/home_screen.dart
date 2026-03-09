import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_restaurante/ui/viewmodels/home_viewmodel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.title = 'SabrosApp'});

  final String title;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Cargar datos cuando se inicia la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<HomeViewModel>().loadHomeData();
      }
    });
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
            ElevatedButton(
              onPressed: () => viewModel.loadHomeData(),
              child: const Text('Reintentar'),
            ),
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

          // Lista de menús
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Menús disponibles:',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                if (viewModel.menus.isEmpty)
                  const Center(child: Text('No hay menús disponibles'))
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: viewModel.menus.length,
                    itemBuilder: (context, index) {
                      return Card(
                        child: ListTile(
                          title: Text(viewModel.menus[index]),
                          leading: const Icon(Icons.restaurant_menu),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            // TODO: Navegar a detalle del menú
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Seleccionaste: ${viewModel.menus[index]}',
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
