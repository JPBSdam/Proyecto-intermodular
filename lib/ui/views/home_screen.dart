import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_restaurante/ui/viewmodels/home_viewmodel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('SabrosApp - Home'),
      ),
      body: Consumer<HomeViewModel>(
        builder: (context, viewModel, child) {
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Welcome to SabrosApp!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                const Text('Menús disponibles:'),
                const SizedBox(height: 16),
                // Mostrar lista de menús
                Expanded(
                  child: ListView.builder(
                    itemCount: viewModel.menus.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(viewModel.menus[index]),
                        leading: const Icon(Icons.restaurant_menu),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
