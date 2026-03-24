import 'package:app_restaurante/core/navigation/app_routes.dart';
import 'package:app_restaurante/core/widgets/home_button.dart';
import 'package:app_restaurante/core/widgets/loading_overlay.dart';
import 'package:app_restaurante/ui/viewmodels/firestore/menu_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class MenuListView extends StatelessWidget {
  const MenuListView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewmodel = context.watch<MenuViewModel>();

    // Cargar menús solo una vez
    if (!viewmodel.isWatchingMenus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        viewmodel.watchMenus();
      });
    }

    return LoadingOverlay(
      isLoading: viewmodel.isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Menús"),
          actions: const [HomeButton()],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            context.go(AppRoutes.menuFormCreate());
          },
          tooltip: 'Añadir Menú',
          child: const Icon(Icons.add),
        ),
        body: _buildBody(context, viewmodel),
      ),
    );
  }

  Widget _buildBody(BuildContext context, MenuViewModel viewmodel) {
    if (viewmodel.errorMessage.isNotEmpty) {
      return Center(child: Text(viewmodel.errorMessage));
    }

    if (viewmodel.menus.isEmpty) {
      return const Center(child: Text("No hay menús disponibles"));
    }

    return ListView.builder(
      itemCount: viewmodel.menus.length,
      itemBuilder: (context, index) {
        final menu = viewmodel.menus[index];

        return ListTile(
          title: Text(menu.name ?? ''),
          subtitle: Text("${menu.price?.toStringAsFixed(2) ?? '-'} €"),
          onTap: () {
            if (menu.id == null || menu.id!.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ID de menú inválido')),
              );
              return;
            }
            context.go(AppRoutes.menuDetail(menu.id!));
          },
        );
      },
    );
  }
}
