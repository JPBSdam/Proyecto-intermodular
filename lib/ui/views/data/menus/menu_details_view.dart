import 'package:app_restaurante/core/navigation/app_routes.dart';
import 'package:app_restaurante/core/widgets/app_badge.dart';
import 'package:app_restaurante/core/widgets/app_bottom_nav.dart';
import 'package:app_restaurante/core/widgets/app_card.dart';
import 'package:app_restaurante/core/widgets/confirmation_dialog.dart';
import 'package:app_restaurante/core/widgets/loading_overlay.dart';
import 'package:app_restaurante/core/widgets/sabros_app_bar.dart';
import 'package:app_restaurante/data/model/dish.dart';
import 'package:app_restaurante/data/model/menu.dart';
import 'package:app_restaurante/ui/viewmodels/firestore/dish_viewmodel.dart';
import 'package:app_restaurante/ui/viewmodels/firestore/menu_viewmodel.dart';
import 'package:app_restaurante/ui/viewmodels/home/home_viewmodel.dart';
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
    final homeVM = context.watch<HomeViewModel>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final bool isAdmin = homeVM.userRole == 'ADMIN';

    // Buscamos el menú en tiempo real dentro de la lista del ViewModel
    final Menu? menu = menuViewModel.menus.cast<Menu?>().firstWhere(
      (m) => m?.id == widget.menuId,
      orElse: () => null,
    );

    final bool isNotFound = menu == null && !menuViewModel.isLoading;

    // Obtenemos los platos reales vinculados
    final List<Dish> menuDishes = dishViewModel.dishes
        .where((d) => menu?.dishes?.contains(d.id) ?? false)
        .toList();

    return LoadingOverlay(
      isLoading: menuViewModel.isLoading || dishViewModel.isLoading,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: SabrosAppBar(
          pageTitle: isNotFound ? 'NO ENCONTRADO' : 'DETALLE MENÚ',
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => context.pop(),
          ),
          actions: [
            if (menu != null && isAdmin) ...[
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => context.push(AppRoutes.menuFormEdit(menu.id!)),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _handleDelete(context, menuViewModel, menu),
              ),
            ],
          ],
        ),
        body: isNotFound
            ? const Center(child: Text("El menú solicitado no existe."))
            : (menu == null
                  ? const Center(child: CircularProgressIndicator())
                  : _buildContent(
                      menu,
                      menuDishes,
                      theme,
                      colorScheme,
                      dishViewModel.isLoading,
                    )),
        bottomNavigationBar: const AppBottomNav(),
      ),
    );
  }

  Widget _buildContent(
    Menu menu,
    List<Dish> menuDishes,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDishLoading,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera: Nombre y Precio
          Center(
            child: Column(
              children: [
                Text(
                  (menu.name ?? 'MENÚ ESPECIAL').toUpperCase(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 16),
                AppBadge.success(
                  label: '${menu.price?.toStringAsFixed(2) ?? "0.00"} €',
                  icon: Icons.payments_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // Descripción si existe
          if (menu.description != null && menu.description!.isNotEmpty) ...[
            _buildSectionHeader('DESCRIPCIÓN', Icons.notes_outlined, theme),
            const SizedBox(height: 12),
            Text(
              menu.description!,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),
          ],

          // Composición
          _buildSectionHeader(
            'COMPOSICIÓN DEL MENÚ',
            Icons.restaurant_outlined,
            theme,
          ),
          const SizedBox(height: 16),
          if (menuDishes.isEmpty && !isDishLoading)
            Text(
              "No hay platos asignados a este menú.",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            ...menuDishes.map((dish) => _buildDishTile(dish, theme)),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withAlpha(50),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.done, color: colorScheme.primary, size: 16),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dish.name ?? '',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (dish.category != null)
                  Text(
                    dish.category!.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      letterSpacing: 1.0,
                    ),
                  ),
              ],
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
      title: '¿ELIMINAR MENÚ?',
      cuestion:
          "Esta acción no se puede deshacer y el menú desaparecerá de la lista.",
    );
    if (confirm != true) return;

    await vm.deleteMenu(menu.id!);

    if (context.mounted) {
      context.go(AppRoutes.menus);
    }
  }
}
