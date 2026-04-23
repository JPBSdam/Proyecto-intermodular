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

import '../../../../core/widgets/app_card.dart';
import '../../../viewmodels/home/home_viewmodel.dart';

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
    final homeVM = context.watch<HomeViewModel>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final bool isAdmin = homeVM.userRole == 'ADMIN';

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
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: colorScheme.primary),
            onPressed: () => context.pop(),
          ),
          actions: [
            if (menu != null && isAdmin) ...[
              IconButton(
                icon: Icon(Icons.edit_outlined, color: colorScheme.primary),
                onPressed: () => context.push(AppRoutes.menuFormEdit(menu.id!)),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: colorScheme.error),
                onPressed: () => _handleDelete(context, menuViewModel, menu),
              ),
            ],
          ],
        ),
        body: menu == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      menu.name ?? 'Menú Especial',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withAlpha(25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${menu.price?.toStringAsFixed(2) ?? "0.00"} €',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildSectionHeader(
                      'Composición del Menú',
                      Icons.restaurant,
                      theme,
                    ),
                    const SizedBox(height: 16),
                    if (menuDishes.isEmpty && !dishViewModel.isLoading)
                      Text(
                        "No hay platos seleccionados",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      )
                    else
                      ...menuDishes.map((dish) => _buildDishTile(dish, theme)),
                    const SizedBox(height: 32),
                    if (menu.description != null &&
                        menu.description!.isNotEmpty) ...[
                      _buildSectionHeader('Notas', Icons.notes, theme),
                      const SizedBox(height: 12),
                      Text(
                        menu.description!,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
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

  Widget _buildSectionHeader(String title, IconData icon, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.primary.withAlpha(180)),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurfaceVariant,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildDishTile(Dish dish, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.primary.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check, color: colorScheme.primary, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              dish.name ?? '',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            dish.category ?? '',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
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
