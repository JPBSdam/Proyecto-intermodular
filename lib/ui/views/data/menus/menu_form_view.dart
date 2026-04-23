import 'package:app_restaurante/core/widgets/app_card.dart';
import 'package:app_restaurante/core/widgets/app_inputs.dart';
import 'package:app_restaurante/core/widgets/loading_overlay.dart';
import 'package:app_restaurante/core/widgets/sabros_app_bar.dart';
import 'package:app_restaurante/core/widgets/snackbars.dart';
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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: SabrosAppBar(
          pageTitle: _menu == null ? 'Nuevo Menú' : 'Editar Menú',
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.pop(),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
                const SizedBox(height: 24),
                AppTextField(
                  controller: _priceController,
                  label: 'Precio (€)',
                  hint: '0.00',
                  icon: Icons.euro,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (v) => v == null || double.tryParse(v) == null
                      ? 'Precio inválido'
                      : null,
                ),
                const SizedBox(height: 24),
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
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () => _apply(menuViewModel),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      _menu == null ? 'CREAR MENÚ' : 'ACTUALIZAR MENÚ',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDishSelector(Color primaryColor) {
    final dishViewModel = context.watch<DishViewModel>();
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'SELECCIONA LOS PLATOS',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 1.1,
            ),
          ),
        ),
        AppCard(
          padding: EdgeInsets.zero,
          borderRadius: 20,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: dishViewModel.dishes.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: theme.colorScheme.outlineVariant.withAlpha(50),
              indent: 20,
              endIndent: 20,
            ),
            itemBuilder: (context, index) {
              final dish = dishViewModel.dishes[index];
              final isSelected = _selectedDishes.any((d) => d.id == dish.id);

              return CheckboxListTile(
                title: Text(
                  dish.name ?? '',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  dish.category ?? '',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
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
      showSnackBar(context, 'Selecciona al menos un plato');
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

    await (_menu == null
        ? viewModel.addMenu(newMenu)
        : viewModel.updateMenu(newMenu));

    if (mounted) {
      if (viewModel.errorMessage.isEmpty) {
        showSnackBar(
          context,
          _menu == null ? '¡Menú creado con éxito!' : '¡Menú actualizado!',
          success: true,
        );
        context.pop();
      } else {
        showSnackBar(context, viewModel.errorMessage);
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
