import 'package:app_restaurante/core/navigation/app_routes.dart';
import 'package:app_restaurante/core/widgets/home_button.dart';
import 'package:app_restaurante/core/widgets/loading_overlay.dart';
import 'package:app_restaurante/ui/viewmodels/firestore/dish_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Pantalla de lista de platos.
/// Muestra todos los platos disponibles usando DishViewModel para obtener datos de Firestore.
/// Permite navegar a la vista de detalle de un plato o crear un nuevo plato.
/// Incluye manejo de estado de carga y errores mediante LoadingOverlay.

class DishesListView extends StatelessWidget {
  const DishesListView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewmodel = context.watch<DishViewModel>();

    // Cargar platos solo una vez
    if (!viewmodel.isWatchingDishes) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        viewmodel.watchDishes();
      });
    }

    return LoadingOverlay(
      isLoading: viewmodel.isLoading,
      // tengo la impresión de que se podría crear una variable global para el loading
      // tener un setter del value tambien global y llamarlo cada vez que haga falta
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Lista de Platos'),
          actions: const [HomeButton()],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            context.go(AppRoutes.dishFormCreate());
          },
          tooltip: 'Añadir Plato',
          child: const Icon(Icons.add),
        ),
        body: _buildBody(viewmodel, context),
      ),
    );
  }

  Widget _buildBody(DishViewModel viewModel, BuildContext context) {
    if (viewModel.errorMessage.isNotEmpty) {
      return Center(child: Text(viewModel.errorMessage));
    }

    if (viewModel.dishes.isEmpty) {
      return const Center(child: Text("No hay platos disponibles"));
    }

    return ListView.builder(
      itemCount: viewModel.dishes.length,
      itemBuilder: (context, index) {
        final dish = viewModel.dishes[index];

        return ListTile(
          title: Text(dish.name ?? ''),
          subtitle: Text(dish.category ?? ''),
          trailing: Text(dish.price?.toStringAsFixed(2) ?? '-'),
          onTap: () {
            context.go(AppRoutes.dishDetail(dish.id!));
          },
        );
      },
    );
  }
}
