import 'package:app_restaurante/core/navigation/app_routes.dart';
import 'package:app_restaurante/core/widgets/confirmation_dialog.dart';
import 'package:app_restaurante/core/widgets/loading_overlay.dart';
import 'package:app_restaurante/data/model/dish.dart';
import 'package:app_restaurante/data/model/menu.dart';
import 'package:app_restaurante/ui/viewmodels/firestore/dish_viewmodel.dart';
import 'package:app_restaurante/ui/viewmodels/firestore/menu_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class MenuDetailView extends StatefulWidget {
  final String menuId;

  const MenuDetailView({super.key, required this.menuId});

  @override
  State<MenuDetailView> createState() => _MenuDetailViewState();
}

class _MenuDetailViewState extends State<MenuDetailView> {
  @override
  void initState() {
    super.initState();
    // Aseguramos que los ViewModels estén escuchando datos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final menuVM = context.read<MenuViewModel>();
      final dishVM = context.read<DishViewModel>();
      if (!menuVM.isWatchingMenus) menuVM.watchMenus();
      if (!dishVM.isWatchingDishes) dishVM.watchDishes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final menuViewModel = context.watch<MenuViewModel>();
    final dishViewModel = context.watch<DishViewModel>();
    final primaryColor = Theme.of(context).colorScheme.primary;

    // Buscamos el menú en tiempo real dentro de la lista del ViewModel
    final Menu? menu = menuViewModel.menus.cast<Menu?>().firstWhere(
      (m) => m?.id == widget.menuId,
      orElse: () => null,
    );

    if (menu == null && !menuViewModel.isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text("Menú no encontrado")),
      );
    }

    // Obtenemos los platos reales vinculados
    final List<Dish> menuDishes = dishViewModel.dishes
        .where((d) => menu?.dishes?.contains(d.id) ?? false)
        .toList();

    return LoadingOverlay(
      isLoading: menuViewModel.isLoading || dishViewModel.isLoading,
      child: Scaffold(
        backgroundColor: const Color(0xFFFEF7F7),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: primaryColor),
            onPressed: () => context.pop(),
          ),
          actions: [
            if (menu != null) ...[
              IconButton(
                icon: Icon(Icons.edit_outlined, color: primaryColor),
                onPressed: () => context.push(AppRoutes.menuFormEdit(menu.id!)),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () => _handleDelete(context, menuViewModel, menu),
              ),
            ],
          ],
        ),
        body: menu == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      menu.name ?? 'Menú Especial',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${menu.price?.toStringAsFixed(2) ?? "0.00"} €',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildSectionHeader(
                      'Composición del Menú',
                      Icons.restaurant,
                    ),
                    const SizedBox(height: 16),
                    if (menuDishes.isEmpty && !dishViewModel.isLoading)
                      Text(
                        "No hay platos seleccionados",
                        style: TextStyle(color: Colors.grey.shade500),
                      )
                    else
                      ...menuDishes.map(
                        (dish) => _buildDishTile(dish, primaryColor),
                      ),
                    const SizedBox(height: 32),
                    if (menu.description != null &&
                        menu.description!.isNotEmpty) ...[
                      _buildSectionHeader('Notas', Icons.notes),
                      const SizedBox(height: 12),
                      Text(
                        menu.description!,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade600,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildDishTile(Dish dish, Color primaryColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryColor.withAlpha(10),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check, color: primaryColor, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              dish.name ?? '',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
          Text(
            dish.category ?? '',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDelete(
    BuildContext context,
    MenuViewModel vm,
    Menu menu,
  ) async {
    final confirm = await showDialogYesNo(
      context,
      title: '¿Eliminar menú?',
      cuestion: "Esta acción no se puede deshacer.",
    );
    if (confirm != true) return;

    await vm.deleteMenu(menu.id!);

    if (context.mounted) {
      context.go(AppRoutes.menus);
    }
  }
}
