import 'dart:io';
import 'package:app_restaurante/core/widgets/app_card.dart';
import 'package:app_restaurante/core/widgets/app_inputs.dart';
import 'package:app_restaurante/core/widgets/image_selector_card.dart';
import 'package:app_restaurante/core/widgets/image_source_sheet.dart';
import 'package:app_restaurante/core/widgets/sabros_app_bar.dart';
import 'package:app_restaurante/core/widgets/snackbars.dart';
import 'package:app_restaurante/data/services/storage/image_picker_service.dart';
import 'package:app_restaurante/ui/viewmodels/firestore/dish_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:app_restaurante/data/model/dish.dart';
import 'package:app_restaurante/core/widgets/loading_overlay.dart';

class DishFormView extends StatefulWidget {
  final String? dishId;

  const DishFormView({super.key, this.dishId});

  @override
  State<DishFormView> createState() => _DishFormViewState();
}

class _DishFormViewState extends State<DishFormView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  String _selectedCategory = 'Entrante';
  final List<String> _categories = [
    'Entrante',
    'Principal',
    'Postre',
    'Bebida',
    'Otro',
  ];
  String? _imageUrl;
  File? _selectedImageFile;
  final ImagePickerService _imagePickerService = ImagePickerService();

  Dish? _dish;

  @override
  void initState() {
    super.initState();
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
    _imageUrl = dish.urlImage;
    _selectedCategory = _categories.contains(dish.category)
        ? dish.category!
        : 'Entrante';
    setState(() {});
  }

  Future<void> _apply(DishViewModel viewmodel) async {
    if (!_formKey.currentState!.validate()) return;

    final newDish = Dish(
      id: _dish?.id,
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      price: double.tryParse(_priceController.text),
      category: _selectedCategory,
      urlImage: _imageUrl,
      available: _dish?.available ?? true,
    );

    await viewmodel.saveDish(newDish, _selectedImageFile);

    if (mounted && viewmodel.errorMessage.isEmpty) {
      showSnackBar(
        context,
        isEditing ? 'Plato actualizado' : 'Plato creado',
        success: true,
      );
      context.pop();
    }
  }

  bool get isEditing => _dish != null;

  @override
  Widget build(BuildContext context) {
    final viewmodel = context.watch<DishViewModel>();
    final primaryColor = Theme.of(context).colorScheme.primary;

    return LoadingOverlay(
      isLoading: viewmodel.isLoading,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: SabrosAppBar(
          pageTitle: isEditing ? 'EDITAR PLATO' : 'NUEVO PLATO',
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => context.pop(),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ImageSelectorCard(
                  localImage: _selectedImageFile,
                  imageUrl: _imageUrl,
                  height: 160,
                  borderRadius: 20,
                  placeholderText: 'Añadir foto',
                  onTap: _pickImage,
                ),
                const SizedBox(height: 32),

                AppTextField(
                  controller: _nameController,
                  label: 'Nombre del plato',
                  hint: 'Ej: Salmón al Grill',
                  icon: Icons.restaurant_menu,
                  validator: (v) => v == null || v.isEmpty
                      ? 'El nombre es obligatorio'
                      : null,
                ),

                const SizedBox(height: 24),
                _buildDropdownLabel('CATEGORÍA'),
                _buildCustomDropdown(primaryColor),

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
                      ? 'Precio no válido'
                      : null,
                ),

                const SizedBox(height: 24),
                AppTextField(
                  controller: _descController,
                  label: 'Descripción',
                  hint: 'Describe los ingredientes...',
                  icon: Icons.description_outlined,
                  maxLines: 4,
                ),

                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () => _apply(viewmodel),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      isEditing ? 'GUARDAR CAMBIOS' : 'CREAR PLATO',
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

  Widget _buildDropdownLabel(String label) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildCustomDropdown(Color primaryColor) {
    final theme = Theme.of(context);
    return AppCard(
      padding: EdgeInsets.zero,
      borderRadius: 15,
      showBorder: false,
      child: DropdownButtonFormField<String>(
        key: ValueKey(_selectedCategory),
        initialValue: _selectedCategory,
        items: _categories
            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
            .toList(),
        onChanged: (v) => setState(() => _selectedCategory = v!),
        decoration: InputDecoration(
          prefixIcon: Icon(
            Icons.category_outlined,
            color: primaryColor,
            size: 22,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: theme.colorScheme.surface,
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final source = await ImageSourceSheet.show(context);

    if (source == null) return;

    try {
      final file = await _imagePickerService.pickImage(source: source);

      if (file == null) return;

      if (mounted) {
        setState(() {
          _selectedImageFile = file;
          _imageUrl = null;
        });
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, e.toString());
      }
    }
  }
}
