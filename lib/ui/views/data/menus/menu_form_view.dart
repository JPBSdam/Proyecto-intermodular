import 'package:app_restaurante/core/widgets/app_inputs.dart';
import 'package:app_restaurante/core/widgets/loading_overlay.dart';
import 'package:app_restaurante/data/model/dish.dart';
import 'package:app_restaurante/data/model/menu.dart';
import 'package:app_restaurante/ui/viewmodels/firestore/dish_viewmodel.dart';
import 'package:app_restaurante/ui/viewmodels/firestore/menu_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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
  late TextEditingController _descController;
  List<Dish> _selectedDishes = [];
  Menu? _menu;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _priceController = TextEditingController();
    _descController = TextEditingController();
  }

  Future<void> _loadMenu() async {
    final menuViewModel = context.read<MenuViewModel>();
    final dishViewModel = context.read<DishViewModel>();

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
        _descController.text = menu.description ?? '';
        _menu = menu;
      }
    }
    setState(() => _initialized = true);
  }

  @override
  Widget build(BuildContext context) {
    final menuViewModel = context.watch<MenuViewModel>();
    final primaryColor = Theme.of(context).colorScheme.primary;

    if (!_initialized && !menuViewModel.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadMenu());
    }

    return LoadingOverlay(
      isLoading: menuViewModel.isLoading,
      child: Scaffold(
        backgroundColor: const Color(0xFFFEF7F7),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.close, color: primaryColor),
            onPressed: () => context.pop(),
          ),
          title: Text(
            _menu == null ? 'Nuevo Menú' : 'Editar Menú',
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: _nameController,
                  label: 'Nombre del Menú',
                  hint: 'Ej: Menú del Día',
                  icon: Icons.restaurant_menu,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Ponle un nombre' : null,
                ),
                const SizedBox(height: 20),
                AppTextField(
                  controller: _priceController,
                  label: 'Precio (€)',
                  hint: '0.00',
                  icon: Icons.euro,
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || double.tryParse(v) == null
                      ? 'Precio inválido'
                      : null,
                ),
                const SizedBox(height: 20),
                AppTextField(
                  controller: _descController,
                  label: 'Descripción (Opcional)',
                  hint: '¿Qué incluye este menú?',
                  icon: Icons.description_outlined,
                  maxLines: 3,
                ),
                const SizedBox(height: 32),
                _buildDishSelector(primaryColor),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () => _apply(menuViewModel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 4,
                  ),
                  child: Text(
                    _menu == null ? 'CREAR MENÚ' : 'ACTUALIZAR MENÚ',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDishSelector(Color primaryColor) {
    final dishViewModel = context.watch<DishViewModel>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'SELECCIONA LOS PLATOS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
              letterSpacing: 1.1,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(5),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: dishViewModel.dishes.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: Colors.grey.shade100,
              indent: 20,
              endIndent: 20,
            ),
            itemBuilder: (context, index) {
              final dish = dishViewModel.dishes[index];
              final isSelected = _selectedDishes.any((d) => d.id == dish.id);

              return CheckboxListTile(
                title: Text(
                  dish.name ?? '',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  dish.category ?? '',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                ),
                value: isSelected,
                activeColor: primaryColor,
                checkboxShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
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
      ],
    );
  }

  Future<void> _apply(MenuViewModel viewModel) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDishes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona al menos un plato'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final newMenu = Menu(
      id: _menu?.id,
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      dishes: _selectedDishes.map((d) => d.id!).toList(),
      price: double.tryParse(_priceController.text),
      available: _menu?.available ?? true,
    );

    try {
      if (_menu == null) {
        await viewModel.addMenu(newMenu);
      } else {
        await viewModel.updateMenu(newMenu);
      }

      if (mounted) {
        if (viewModel.errorMessage.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _menu == null
                    ? '¡Menú creado con éxito!'
                    : '¡Menú actualizado correctamente!',
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          context.pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(viewModel.errorMessage),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descController.dispose();
    super.dispose();
  }
}
