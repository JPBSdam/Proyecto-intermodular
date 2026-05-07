import 'package:app_restaurante/core/navigation/app_routes.dart';
import 'package:app_restaurante/core/widgets/app_card.dart';
import 'package:app_restaurante/core/widgets/app_bottom_nav.dart';
import 'package:app_restaurante/core/widgets/loading_overlay.dart';
import 'package:app_restaurante/core/widgets/sabros_app_bar.dart';
import 'package:app_restaurante/ui/viewmodels/firestore/menu_viewmodel.dart';
import 'package:app_restaurante/ui/viewmodels/home/home_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class MenuListView extends StatefulWidget {
  const MenuListView({super.key});

  @override
  State<MenuListView> createState() => _MenuListViewState();
}

class _MenuListViewState extends State<MenuListView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    final viewmodel = context.read<MenuViewModel>();
    if (!viewmodel.isWatchingMenus) {
      viewmodel.watchMenus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final viewmodel = context.watch<MenuViewModel>();
    final homeVM = context.watch<HomeViewModel>();

    final bool isAdmin = homeVM.userRole == 'ADMIN';

    final filteredMenus = viewmodel.menus.where((m) {
      return (m.name ?? "").toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return LoadingOverlay(
      isLoading: viewmodel.isLoading,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: SabrosAppBar(
          pageTitle: 'NUESTROS MENÚS',
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.home);
              }
            },
          ),
        ),
        bottomNavigationBar: const AppBottomNav(),
        floatingActionButton: isAdmin
            ? FloatingActionButton.extended(
                onPressed: () => context.push(AppRoutes.menuFormCreate()),
                icon: const Icon(Icons.add),
                label: const Text('Añadir menú'),
              )
            : null,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nuestros Menús',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Degusta nuestras mejores combinaciones',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            _buildSearchBar(theme),
            Expanded(
              child: filteredMenus.isEmpty && !viewmodel.isLoading
                  ? _buildEmptyState(theme)
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                      itemCount: filteredMenus.length,
                      itemBuilder: (context, index) {
                        final menu = filteredMenus[index];
                        return _buildMenuCard(context, menu, theme, isAdmin);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withAlpha(12),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (val) => setState(() => _searchQuery = val),
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: 'Encuentra el menú ideal...',
            hintStyle: TextStyle(
              color: colorScheme.onSurfaceVariant.withAlpha(150),
            ),
            prefixIcon: Icon(Icons.search, color: colorScheme.primary),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 15,
              horizontal: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    dynamic menu,
    ThemeData theme,
    bool isAdmin,
  ) {
    final colorScheme = theme.colorScheme;
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      onTap: () => context.push(AppRoutes.menuDetail(menu.id!)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.restaurant_menu,
              color: colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  menu.name ?? 'Menú sin nombre',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${menu.price?.toStringAsFixed(2) ?? "0.00"}€',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (isAdmin)
            IconButton(
              icon: Icon(
                Icons.edit_outlined,
                color: colorScheme.onSurfaceVariant,
                size: 20,
              ),
              onPressed: () => context.push(AppRoutes.menuFormEdit(menu.id!)),
            ),
          Icon(
            Icons.chevron_right,
            color: colorScheme.onSurfaceVariant.withAlpha(100),
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.menu_book,
            size: 64,
            color: theme.colorScheme.onSurface.withAlpha(30),
          ),
          const SizedBox(height: 16),
          Text(
            "No se han encontrado menús",
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
