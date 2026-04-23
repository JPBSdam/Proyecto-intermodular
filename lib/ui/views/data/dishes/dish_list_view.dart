import 'package:app_restaurante/core/navigation/app_routes.dart';
import 'package:app_restaurante/core/widgets/app_drawer.dart';
import 'package:app_restaurante/core/widgets/app_bottom_nav.dart';
import 'package:app_restaurante/core/widgets/app_logo_title.dart';
import 'package:app_restaurante/core/widgets/app_user_avatar.dart';
import 'package:app_restaurante/core/widgets/loading_overlay.dart';
import 'package:app_restaurante/data/model/dish.dart';
import 'package:app_restaurante/ui/viewmodels/firestore/dish_viewmodel.dart';
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
    final viewmodel = context.watch<DishViewModel>();
    final primaryColor = Theme.of(context).colorScheme.primary;

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
      // tengo la impresión de que se podría crear una variable global para el loading
      // tener un setter del value tambien global y llamarlo cada vez que haga falta
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        drawer: const AppDrawer(),
        appBar: _buildAppBar(context, primaryColor),
        bottomNavigationBar: const AppBottomNav(currentIndex: 1),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.push(AppRoutes.dishFormCreate()),
          backgroundColor: primaryColor,
          elevation: 4,
          child: const Icon(Icons.add, color: Colors.white, size: 30),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => context.go(AppRoutes.home),
                    child: Row(
                      children: [
                        Icon(
                          Icons.arrow_back,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Volver al Inicio',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Nuestra Carta',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            _buildSearchBar(primaryColor),
            Expanded(
              child: viewmodel.dishes.isEmpty && !viewmodel.isLoading
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                      itemCount: sortedCategories.length,
                      itemBuilder: (context, catIndex) {
                        final category = sortedCategories[catIndex];
                        final categoryDishes = groupedDishes[category]!;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildCategoryHeader(category, primaryColor),
                            ...categoryDishes.map(
                              (dish) =>
                                  _buildDishCard(context, dish, primaryColor),
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
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, Color primaryColor) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: primaryColor),
      centerTitle: true,
      title: const AppLogoTitle(),
      actions: const [AppUserAvatar()],
    );
  }

  Widget _buildSearchBar(Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(12),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (val) => setState(() => _searchQuery = val),
          decoration: InputDecoration(
            hintText: 'Busca tu plato favorito...',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
            prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
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

  Widget _buildCategoryHeader(String category, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            category == 'Entrante'
                ? 'Entrantes'
                : category == 'Principal'
                ? 'Principales'
                : '${category}s',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDishCard(BuildContext context, Dish dish, Color primaryColor) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.dishDetail(dish.id!)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dish.name ?? 'Plato sin nombre',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                      color: Colors.black87,
                    ),
                  ),
                  if (dish.price != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${dish.price!.toStringAsFixed(2)}€',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.chevron_right, color: primaryColor, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_menu, size: 80, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          Text(
            "No hay platos en esta sección",
            style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
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
