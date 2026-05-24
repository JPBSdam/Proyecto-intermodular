import 'dart:typed_data';
import 'package:app_restaurante/core/navigation/app_routes.dart';
import 'package:app_restaurante/core/widgets/app_bottom_nav.dart';
import 'package:app_restaurante/core/widgets/app_inputs.dart';
import 'package:app_restaurante/core/widgets/image_selector_card.dart';
import 'package:app_restaurante/core/widgets/image_source_sheet.dart';
import 'package:app_restaurante/core/widgets/loading_overlay.dart';
import 'package:app_restaurante/core/widgets/snackbars.dart';
import 'package:app_restaurante/data/services/storage/image_picker_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:app_restaurante/data/model/restaurant.dart';
import 'package:app_restaurante/ui/viewmodels/firestore/restaurant_viewmodel.dart';

class RestaurantFormView extends StatefulWidget {
  const RestaurantFormView({super.key});

  @override
  State<RestaurantFormView> createState() => _RestaurantFormViewState();
}

class _RestaurantFormViewState extends State<RestaurantFormView> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _descriptionController;
  late TextEditingController _capacityController;
  bool _open = false;
  bool _initialized = false;
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  String? _imageUrl;
  final ImagePickerService _imagePickerService = ImagePickerService();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _addressController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _descriptionController = TextEditingController();
    _capacityController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RestaurantViewModel>();

    if (!_initialized && vm.restaurant != null) {
      _fillForm(vm.restaurant!);
      _initialized = true;
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LoadingOverlay(
      isLoading: vm.isLoading,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          elevation: 0,
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
          title: Text(
            'MI RESTAURANTE',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ImageSelectorCard(
                  localImageBytes: _selectedImageBytes,
                  imageUrl: _imageUrl,
                  onTap: _showPickImageOptions,
                  placeholderText: 'Foto del Local',
                ),
                const SizedBox(height: 32),

                _buildSectionTitle("DATOS GENERALES"),
                AppTextField(
                  controller: _nameController,
                  label: "Nombre comercial",
                  hint: "Ej: SabrosApp Centro",
                  icon: Icons.business_outlined,
                  validator: (v) => v == null || v.isEmpty
                      ? 'El nombre es obligatorio'
                      : null,
                ),
                const SizedBox(height: 24),
                AppTextField(
                  controller: _descriptionController,
                  label: "Descripción breve",
                  hint: "Cuéntanos sobre el restaurante...",
                  icon: Icons.description_outlined,
                  maxLines: 3,
                ),

                const SizedBox(height: 32),
                _buildSectionTitle("LOCALIZACIÓN Y CONTACTO"),
                AppTextField(
                  controller: _addressController,
                  label: "Dirección completa",
                  hint: "Calle Falsa 123, Ciudad",
                  icon: Icons.location_on_outlined,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _phoneController,
                        label: "Teléfono",
                        hint: "600 000 000",
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AppTextField(
                        controller: _capacityController,
                        label: "Aforo máx.",
                        hint: "50",
                        icon: Icons.people_outline,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                AppTextField(
                  controller: _emailController,
                  label: "Email de contacto",
                  hint: "contacto@restaurante.com",
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      (v != null && v.isNotEmpty && !v.contains("@"))
                      ? "Email inválido"
                      : null,
                ),

                const SizedBox(height: 32),
                _buildSectionTitle("ESTADO DEL LOCAL"),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(5),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SwitchListTile(
                    title: Text(
                      _open ? "ABIERTO AL PÚBLICO" : "CERRADO TEMPORALMENTE",
                      style: TextStyle(
                        color: _open ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    secondary: Icon(
                      _open ? Icons.check_circle_outline : Icons.highlight_off,
                      color: _open ? Colors.green : Colors.red,
                    ),
                    value: _open,
                    activeThumbColor: Colors.green,
                    onChanged: (val) => setState(() => _open = val),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () => _save(vm),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      vm.restaurant == null
                          ? "CREAR RESTAURANTE"
                          : "GUARDAR CAMBIOS",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
        bottomNavigationBar: const AppBottomNav(),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary.withAlpha(180),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Future<void> _onPickImage(ImageSource source) async {
    try {
      final xfile = await _imagePickerService.pickImage(source: source);

      if (!mounted || xfile == null) return;

      final bytes = await xfile.readAsBytes();

      setState(() {
        _selectedImage = xfile;
        _selectedImageBytes = bytes;
        _imageUrl = null;
      });
    } catch (e) {
      if (mounted) {
        showSnackBar(context, e.toString());
      }
    }
  }

  void _showPickImageOptions() async {
    final source = await ImageSourceSheet.show(context);

    if (source == null) return;

    await _onPickImage(source);
  }

  void _fillForm(Restaurant r) {
    _nameController.text = r.name ?? '';
    _addressController.text = r.address ?? '';
    _phoneController.text = r.phoneNumber ?? '';
    _emailController.text = r.email ?? '';
    _descriptionController.text = r.description ?? '';
    _capacityController.text = r.capacity?.toString() ?? '';
    _imageUrl = r.urlImage;
    _open = r.open ?? false;
  }

  Future<void> _save(RestaurantViewModel vm) async {
    if (!_formKey.currentState!.validate()) return;

    final current = vm.restaurant;
    final restaurant = Restaurant(
      id: current?.id,
      name: _nameController.text.isEmpty ? current?.name : _nameController.text,
      address: _addressController.text.isEmpty
          ? current?.address
          : _addressController.text,
      phoneNumber: _phoneController.text.isEmpty
          ? current?.phoneNumber
          : _phoneController.text,
      email: _emailController.text.isEmpty
          ? current?.email
          : _emailController.text,
      description: _descriptionController.text.isEmpty
          ? current?.description
          : _descriptionController.text,
      capacity: _capacityController.text.isEmpty
          ? current?.capacity
          : int.tryParse(_capacityController.text),
      urlImage: _imageUrl,
      open: _open,
    );

    try {
      await vm.saveRestaurant(restaurant, _selectedImage);

      if (!mounted) return;

      if (vm.errorMessage.isEmpty) {
        showSnackBar(
          context,
          'Información actualizada correctamente',
          success: true,
        );
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.home);
        }
      } else {
        showSnackBar(context, vm.errorMessage);
      }
    } catch (e) {
      if (mounted) showSnackBar(context, 'Error inesperado: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _descriptionController.dispose();
    _capacityController.dispose();
    super.dispose();
  }
}
