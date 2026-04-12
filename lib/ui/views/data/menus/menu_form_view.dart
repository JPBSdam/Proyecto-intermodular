import 'package:app_restaurante/core/widgets/home_button.dart';
import 'package:app_restaurante/core/widgets/loading_overlay.dart';
import 'package:app_restaurante/data/model/dish.dart';
import 'package:app_restaurante/data/model/menu.dart';
import 'package:app_restaurante/ui/viewmodels/firestore/dish_viewmodel.dart';
import 'package:app_restaurante/ui/viewmodels/firestore/menu_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Pantalla de formulario de Menú.
/// - Permite crear un nuevo menú o editar uno existente.
/// - Lista todos los platos disponibles usando `DishViewModel`
///   para poder seleccionar los que formarán parte del menú.
/// - Muestra un formulario con campos de nombre, precio y selección de platos.
/// - Al guardar o actualizar, llama a los métodos CRUD de `MenuViewModel`.
/// - Utiliza `LoadingOverlay` para indicar carga mientras se realiza alguna operación.

class MenuFormView extends StatefulWidget {
  final String? menuId;

  const MenuFormView({super.key, this.menuId});

  @override
  State<MenuFormView> createState() => _MenuFormViewState();
}

class _MenuFormViewState extends State<MenuFormView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  List<Dish> _selectedDishes = [];
  Menu? _menu;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _priceController = TextEditingController();
  }

  Future<void> _loadMenu() async {
    final menuViewModel = context.read<MenuViewModel>();
    final dishViewModel = context.watch<DishViewModel>();

    // Escuchar platos si no lo está haciendo ya
    if (!dishViewModel.isWatchingDishes) dishViewModel.watchDishes();

    if (widget.menuId != null) {
      final menu = await menuViewModel.fetchMenuById(widget.menuId!);
      if (menu != null) {
        final menuDishIds = menu.dishes ?? [];
        _selectedDishes = dishViewModel.dishes
            .where((d) => menuDishIds.contains(d.id))
            .toList();
        _nameController.text = menu.name ?? '';
        _priceController.text = menu.price?.toStringAsFixed(2) ?? '';
        _menu = menu;
      }
    } else {
      _nameController.text = '';
      _priceController.text = '';
      _selectedDishes = [];
      _menu = null;
    }

    setState(() {
      _initialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final menuViewModel = context.watch<MenuViewModel>();
    if (!_initialized && !menuViewModel.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadMenu());
    }

    return LoadingOverlay(
      isLoading: menuViewModel.isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_menu == null ? 'Añadir Menú' : 'Editar Menú'),
          actions: const [HomeButton()],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: _buildForm(menuViewModel),
        ),
      ),
    );
  }

  Widget _buildForm(MenuViewModel viewModel) {
    final dishViewModel = context.watch<DishViewModel>();

    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Nombre'),
            validator: (v) => v == null || v.isEmpty ? 'Obligatorio' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _priceController,
            decoration: const InputDecoration(labelText: 'Precio'),
            keyboardType: TextInputType.number,
            validator: (v) => v == null || double.tryParse(v) == null
                ? 'Introduce un número válido'
                : null,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: dishViewModel.dishes.length,
              itemBuilder: (context, index) {
                final dish = dishViewModel.dishes[index];
                final selected = _selectedDishes.any((d) => d.id == dish.id);

                return CheckboxListTile(
                  title: Text(dish.name ?? ''),
                  value: selected,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selectedDishes.add(dish);
                      } else {
                        _selectedDishes.removeWhere((d) => d.id == dish.id);
                      }
                    });
                  },
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: () => _apply(viewModel),
            child: Text(_menu == null ? 'Guardar' : 'Actualizar'),
          ),
          if (viewModel.errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                viewModel.errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _apply(MenuViewModel viewModel) async {
    if (!_formKey.currentState!.validate()) return;

    final newMenu = Menu(
      id: _menu?.id,
      name: _nameController.text,
      dishes: _selectedDishes.map((d) => d.id!).toList(),
      price: double.tryParse(_priceController.text),
    );

    if (_menu == null) {
      await viewModel.addMenu(newMenu);
    } else {
      await viewModel.updateMenu(newMenu);
    }

    if (mounted) context.pop();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }
}
