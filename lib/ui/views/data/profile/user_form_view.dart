import 'package:app_restaurante/core/widgets/home_button.dart';
import 'package:app_restaurante/core/widgets/loading_overlay.dart';
import 'package:app_restaurante/core/widgets/snackbars.dart';
import 'package:app_restaurante/data/model/user.dart';
import 'package:app_restaurante/ui/viewmodels/firestore/user_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UserFormView extends StatefulWidget {
  final String userId;

  const UserFormView({super.key, required this.userId});

  @override
  State<UserFormView> createState() => _UserFormViewState();
}

class _UserFormViewState extends State<UserFormView> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  User? _user;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController();
    _phoneController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final viewmodel = context.read<UserViewModel>();

      try {
        final user = await viewmodel.fetchUserById(widget.userId);

        if (user != null && mounted) {
          setState(() {
            _user = user;
            _fillForm(user);
          });
        }
      } catch (e) {
        if (mounted) showSnackBar(context, 'Error: $e');
      }
    });
  }

  void _fillForm(User user) {
    _nameController.text = user.name ?? '';
    _phoneController.text = user.phoneNumber ?? '';
  }

  Future<void> _apply(UserViewModel vm) async {
    if (!_formKey.currentState!.validate()) return;

    final updatedUser = User(
      id: _user?.id,
      name: _nameController.text,
      email: _user?.email,
      phoneNumber: _phoneController.text,
      role: _user?.role,
      urlImage: _user?.urlImage,
    );

    await vm.updateUser(updatedUser);

    if (mounted && vm.error.isEmpty) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<UserViewModel>();

    return LoadingOverlay(
      isLoading: vm.isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Editar perfil'),
          actions: const [HomeButton()],
        ),
        body: Padding(padding: const EdgeInsets.all(16), child: _buildForm(vm)),
      ),
    );
  }

  Widget _buildForm(UserViewModel vm) {
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
            controller: _phoneController,
            decoration: const InputDecoration(labelText: 'Teléfono'),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _apply(vm),
                  child: const Text('Actualizar'),
                ),
              ),
            ],
          ),
          if (vm.error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(vm.error, style: const TextStyle(color: Colors.red)),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
