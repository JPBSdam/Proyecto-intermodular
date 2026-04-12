import 'package:app_restaurante/core/widgets/home_button.dart';
import 'package:flutter/material.dart';
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
  late TextEditingController _imageController;

  bool _open = false;

  @override
  void initState() {
    super.initState();

    final vm = context.read<RestaurantViewModel>();
    final r = vm.restaurant;

    _nameController = TextEditingController(text: r?.name ?? '');
    _addressController = TextEditingController(text: r?.address ?? '');
    _phoneController = TextEditingController(text: r?.phoneNumber ?? '');
    _emailController = TextEditingController(text: r?.email ?? '');
    _descriptionController = TextEditingController(text: r?.description ?? '');
    _capacityController = TextEditingController(
      text: r?.capacity?.toString() ?? '',
    );
    _imageController = TextEditingController(text: r?.urlImage ?? '');
    _open = r?.open ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RestaurantViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text("Restaurante"), actions: [HomeButton()]),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    _buildField(_nameController, "Nombre"),
                    _buildField(_addressController, "Dirección"),
                    _buildField(_phoneController, "Teléfono"),
                    _buildField(_emailController, "Email"),
                    _buildField(_descriptionController, "Descripción"),
                    _buildField(
                      _capacityController,
                      "Capacidad",
                      type: TextInputType.number,
                    ),
                    _buildField(_imageController, "URL Imagen"),

                    const SizedBox(height: 12),

                    SwitchListTile(
                      title: const Text("Abierto"),
                      value: _open,
                      onChanged: (val) {
                        setState(() => _open = val);
                      },
                    ),

                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: () => _save(vm),
                      child: Text(
                        vm.restaurant == null
                            ? "Crear restaurante"
                            : "Actualizar restaurante",
                      ),
                    ),

                    if (vm.errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          vm.errorMessage,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label, {
    TextInputType type = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(labelText: label),
        validator: (value) =>
            value == null || value.isEmpty ? "Campo obligatorio" : null,
      ),
    );
  }

  Future<void> _save(RestaurantViewModel vm) async {
    if (!_formKey.currentState!.validate()) return;

    final restaurant = Restaurant(
      id: vm.restaurant?.id,
      name: _nameController.text,
      address: _addressController.text,
      phoneNumber: _phoneController.text,
      email: _emailController.text,
      description: _descriptionController.text,
      capacity: int.tryParse(_capacityController.text),
      urlImage: _imageController.text,
      open: _open,
    );

    if (vm.restaurant == null) {
      await vm.createRestaurant(restaurant);
    } else {
      await vm.updateRestaurant(restaurant);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _descriptionController.dispose();
    _capacityController.dispose();
    _imageController.dispose();
    super.dispose();
  }
}
