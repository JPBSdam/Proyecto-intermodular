import 'package:app_restaurante/core/navigation/app_routes.dart';
import 'package:app_restaurante/core/widgets/confirmation_dialog.dart';
import 'package:app_restaurante/core/widgets/home_button.dart';
import 'package:app_restaurante/core/widgets/loading_overlay.dart';
import 'package:app_restaurante/data/model/dish.dart';
import 'package:app_restaurante/data/model/menu.dart';
import 'package:app_restaurante/ui/viewmodels/firestore/dish_viewmodel.dart';
import 'package:app_restaurante/ui/viewmodels/firestore/menu_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Pantalla de detalle de Menú.
/// - Muestra la información de un menú específico: nombre, descripción,
///   precio, disponibilidad y lista de platos incluidos.
/// - Permite editar o eliminar el menú usando `MenuViewModel`.
/// - Obtiene los datos de los platos incluidos desde `DishViewModel`.
/// - Utiliza `LoadingOverlay` para indicar carga mientras se recuperan
///   los datos o se ejecuta alguna acción.

class MenuDetailView extends StatefulWidget {
  final String menuId;

  const MenuDetailView({super.key, required this.menuId});

  @override
  State<MenuDetailView> createState() => _MenuDetailViewState();
}

class _MenuDetailViewState extends State<MenuDetailView> {
  late final MenuViewModel _menuViewModel;
  late final DishViewModel _dishViewModel;

  Menu? _menu;
  List<Dish> _menuDishes = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _menuViewModel = context.read<MenuViewModel>();
    _dishViewModel = context.read<DishViewModel>();
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final menu = await _menuViewModel.fetchMenuById(widget.menuId);
      if (menu == null) {
        setState(() {
          _error = 'Menú no encontrado';
          _isLoading = false;
        });
        return;
      }

      // Filtrar los platos del menú usando DishViewModel
      final menuDishIds = menu.dishes ?? [];
      final menuDishes = _dishViewModel.dishes
          .where((d) => menuDishIds.contains(d.id))
          .toList();

      setState(() {
        _menu = menu;
        _menuDishes = menuDishes;
      });
    } catch (e) {
      setState(() => _error = 'Error al cargar el menú: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget bodyContent;

    if (_error.isNotEmpty) {
      bodyContent = Center(child: Text(_error));
    } else if (_menu == null) {
      bodyContent = const Center(child: Text("Menú no encontrado"));
    } else {
      bodyContent = Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _menu!.name ?? '',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text("Descripción: ${_menu!.description ?? '-'}"),
            Text("Precio total: ${_menu!.price?.toStringAsFixed(2) ?? '-'} €"),
            Text("Disponible: ${_menu!.available == true ? "Sí" : "No"}"),
            const SizedBox(height: 16),
            const Text(
              "Platos incluidos:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ..._menuDishes.map((d) => Text("- ${d.name ?? ''}")),
          ],
        ),
      );
    }

    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_menu?.name ?? 'Detalle del Menú'),
          actions: [
            if (_menu != null && (_menu!.id?.isNotEmpty ?? false))
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Editar menú',
                onPressed: () {
                  context.go(AppRoutes.menuFormEdit(_menu!.id!));
                },
              ),
            if (_menu != null && (_menu!.id?.isNotEmpty ?? false))
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () async {
                  final confirm = await showDialogYesNo(
                    context,
                    title: 'Eliminar $_menu',
                    cuestion:
                        "¿Estás seguro de que quieres eliminar este menú?",
                  );
                  if (confirm == true && context.mounted) {
                    await _menuViewModel.deleteMenu(_menu!.id!);
                    if (context.mounted) context.go(AppRoutes.menus);
                  }
                },
              ),
            const HomeButton(),
          ],
        ),
        body: bodyContent,
      ),
    );
  }
}
