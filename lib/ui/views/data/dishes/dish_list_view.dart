import 'package:cached_network_image/cached_network_image.dart';
import 'package:app_restaurante/core/config/app_theme.dart';
import 'package:app_restaurante/core/navigation/app_routes.dart';
import 'package:app_restaurante/core/widgets/app_card.dart';
import 'package:app_restaurante/core/widgets/app_bottom_nav.dart';
import 'package:app_restaurante/core/widgets/loading_overlay.dart';
import 'package:app_restaurante/core/widgets/sabros_app_bar.dart';
import 'package:app_restaurante/data/model/dish.dart';
import 'package:app_restaurante/ui/viewmodels/firestore/dish_viewmodel.dart';
import 'package:app_restaurante/ui/viewmodels/home/home_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class DishesListView extends StatefulWidget {
  const DishesListView({super.key});

  @override
  State<DishesListView> createState() => _DishesListViewState();
}

class _DishesListViewState extends State<DishesListView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    final viewmodel = context.read<DishViewModel>();
    if (!viewmodel.isWatchingDishes) {
      viewmodel.watchDishes();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final viewmodel = context.watch<DishViewModel>();
    final homeVM = context.watch<HomeViewModel>();

    // Solo el ADMIN puede crear platos
    final bool isAdmin = homeVM.userRole == 'ADMIN';

    final filteredDishes = viewmodel.dishes.where((d) {
      return (d.name ?? "").toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    final groupedDishes = <String, List<Dish>>{};
    for (var dish in filteredDishes) {
      final cat = dish.category ?? 'Otros';
      if (!groupedDishes.containsKey(cat)) groupedDishes[cat] = [];
      groupedDishes[cat]!.add(dish);
    }

    final categoryOrder = ['Entrante', 'Principal', 'Postre', 'Bebida', 'Otro'];
    final sortedCategories = groupedDishes.keys.toList()
      ..sort((a, b) {
        int indexA = categoryOrder.indexOf(a);
        int indexB = categoryOrder.indexOf(b);
        if (indexA == -1) indexA = 99;
        if (indexB == -1) indexB = 99;
        return indexA.compareTo(indexB);
      });

    return LoadingOverlay(
      isLoading: viewmodel.isLoading,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: SabrosAppBar(
          pageTitle: 'NUESTRA CARTA',
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
                onPressed: () => context.push(AppRoutes.dishFormCreate()),
                icon: const Icon(Icons.add),
                label: const Text('Añadir plato'),
              )
            : null,
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppTheme.webHPad(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nuestra Carta',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Explora nuestros sabores seleccionados',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              _buildSearchBar(theme),
              if (viewmodel.errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    viewmodel.errorMessage,
                    style: TextStyle(color: colorScheme.error),
                  ),
                ),
              Expanded(
                child: viewmodel.dishes.isEmpty && !viewmodel.isLoading
                    ? _buildEmptyState(theme)
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                        itemCount: sortedCategories.length,
                        itemBuilder: (context, catIndex) {
                          final category = sortedCategories[catIndex];
                          final categoryDishes = groupedDishes[category]!;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildCategoryHeader(category, theme),
                              ...categoryDishes.map(
                                (dish) => _buildDishCard(
                                  context,
                                  dish,
                                  theme,
                                  isAdmin,
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
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
            hintText: 'Busca tu plato favorito...',
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

  Widget _buildCategoryHeader(String category, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: AppTheme.brandDetail,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            category.toUpperCase(),
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: AppTheme.brandDetail,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDishCard(
    BuildContext context,
    Dish dish,
    ThemeData theme,
    bool isAdmin,
  ) {
    final colorScheme = theme.colorScheme;
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onTap: () => context.push(AppRoutes.dishDetail(dish.id!)),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: (dish.urlImage != null && dish.urlImage!.isNotEmpty)
                ? CachedNetworkImage(
                    imageUrl: dish.urlImage!,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: 60,
                      height: 60,
                      color: AppTheme.brandPrimary.withAlpha(20),
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 60,
                      height: 60,
                      color: AppTheme.brandPrimary.withAlpha(20),
                      child: const Icon(Icons.restaurant, size: 24),
                    ),
                  )
                : Container(
                    width: 60,
                    height: 60,
                    color: colorScheme.primary.withAlpha(20),
                    child: Icon(
                      Icons.restaurant,
                      color: colorScheme.primary,
                      size: 24,
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dish.name ?? 'Plato sin nombre',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (dish.price != null) ...[
                  Text(
                    '${dish.price!.toStringAsFixed(2)}€',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
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
              onPressed: () => context.push(AppRoutes.dishFormEdit(dish.id!)),
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
            Icons.restaurant_menu,
            size: 64,
            color: theme.colorScheme.onSurface.withAlpha(30),
          ),
          const SizedBox(height: 16),
          Text(
            "No hemos encontrado platos",
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
