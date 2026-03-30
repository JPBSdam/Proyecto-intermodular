import 'package:app_restaurante/core/widgets/home_button.dart';
import 'package:app_restaurante/core/widgets/snackbars.dart';
import 'package:app_restaurante/ui/viewmodels/firestore/dish_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:app_restaurante/data/model/dish.dart';
import 'package:app_restaurante/core/widgets/loading_overlay.dart';

/// Pantalla de formulario para crear o editar un plato.
/// - Si `dishId` es nulo, se crea un nuevo plato.
/// - Si `dishId` no es nulo, carga el plato existente y permite editarlo.
/// - Gestiona nombre, descripción, precio y categoría del plato.
/// - Usa DishViewModel para interactuar con Firestore y manejar estado, errores y carga.

class DishFormView extends StatefulWidget {
  final String? dishId;

  const DishFormView({super.key, this.dishId});

  @override
  State<DishFormView> createState() => _DishFormViewState();
}

class _DishFormViewState extends State<DishFormView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _priceController;

  String _selectedCategory = 'Entrante';
  final List<String> _categories = ['Entrante', 'Principal', 'Postre', 'Otro'];

  Dish? _dish;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descController = TextEditingController();
    _priceController = TextEditingController();

    if (widget.dishId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final viewmodel = context.read<DishViewModel>();
        try {
          final fetchedDish = await viewmodel.fetchDishById(widget.dishId!);
          if (fetchedDish != null && mounted) {
            setState(() {
              _dish = fetchedDish;
              _fillForm(_dish!);
            });
          }
        } catch (e) {
          if (mounted) showSnackBar(context, 'Error al cargar el plato: $e');
        }
      });
    }
  }

  void _fillForm(Dish dish) {
    _nameController.text = dish.name ?? '';
    _descController.text = dish.description ?? '';
    _priceController.text = dish.price?.toString() ?? '';
    _selectedCategory = _categories.contains(dish.category)
        ? dish.category!
        : 'Entrante';
    setState(() {}); // actualizar dropdown
  }

  Future<void> _apply(DishViewModel viewmodel) async {
    if (!_formKey.currentState!.validate()) return;

    final newDish = Dish(
      id: _dish?.id,
      name: _nameController.text,
      description: _descController.text,
      price: double.tryParse(_priceController.text),
      category: _selectedCategory,
    );

    if (_dish == null) {
      await viewmodel.addDish(newDish);
    } else {
      await viewmodel.updateDish(newDish);
    }

    if (mounted && viewmodel.errorMessage.isEmpty) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final viewmodel = context.watch<DishViewModel>();
    final isEditing = _dish != null;

    return LoadingOverlay(
      isLoading: viewmodel.isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? 'Editar Plato' : 'Añadir Plato'),
          actions: const [HomeButton()],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: _buildForm(viewmodel, isEditing),
        ),
      ),
    );
  }

  Widget _buildForm(DishViewModel viewmodel, bool isEditing) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Nombre'),
            validator: (v) => v == null || v.isEmpty ? 'Obligatorio' : null,
          ),
          TextFormField(
            controller: _descController,
            decoration: const InputDecoration(labelText: 'Descripción'),
          ),
          TextFormField(
            controller: _priceController,
            decoration: const InputDecoration(labelText: 'Precio'),
            keyboardType: TextInputType.number,
            validator: (v) => v == null || double.tryParse(v) == null
                ? 'Introduce un número válido'
                : null,
          ),
          DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
            items: _categories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _selectedCategory = v!),
            decoration: const InputDecoration(labelText: 'Categoría'),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _apply(viewmodel),
                  child: Text(isEditing ? 'Actualizar' : 'Guardar'),
                ),
              ),
            ],
          ),
          if (viewmodel.errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                viewmodel.errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    super.dispose();
  }
}
