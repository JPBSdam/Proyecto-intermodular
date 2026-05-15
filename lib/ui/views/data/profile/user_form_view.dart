import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_restaurante/core/widgets/app_inputs.dart';
import 'package:app_restaurante/core/widgets/sabros_app_bar.dart';
import 'package:app_restaurante/core/widgets/loading_overlay.dart';
import 'package:app_restaurante/core/widgets/snackbars.dart';
import 'package:app_restaurante/data/model/user.dart';
import 'package:app_restaurante/ui/viewmodels/firestore/user_viewmodel.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:app_restaurante/ui/viewmodels/home/home_viewmodel.dart';

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
  File? _selectedImageFile;
  final ImagePicker _imagePicker = ImagePicker();

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
            _nameController.text = user.name ?? '';
            _phoneController.text = user.phoneNumber ?? '';
          });
        }
      } catch (e) {
        if (mounted) showSnackBar(context, 'Error: $e');
      }
    });
  }

  void _showPickImageOptions() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // Opciones: tomar foto o elegir de galería
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Actualizar foto',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(),
              ListTile(
                leading: Icon(Icons.photo_camera, color: colorScheme.primary),
                title: const Text('Hacer foto'),
                onTap: () {
                  Navigator.pop(context);
                  Future.microtask(() => _pickImage(ImageSource.camera));
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: colorScheme.primary),
                title: const Text('Elegir de la galería'),
                onTap: () {
                  Navigator.pop(context);
                  Future.microtask(() => _pickImage(ImageSource.gallery));
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final permissionGranted = await _requestMediaPermission(source);
    if (!permissionGranted) {
      if (mounted)
        showSnackBar(
          context,
          'Permiso necesario para acceder a la cámara/galería.',
        );
      return;
    }

    final picked = await _imagePicker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1200,
    );
    if (picked == null) return;

    setState(() {
      _selectedImageFile = File(picked.path);
    });
  }

  Future<bool> _requestMediaPermission(ImageSource source) async {
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      return status.isGranted;
    }

    if (Platform.isIOS) {
      final status = await Permission.photos.request();
      return status.isGranted;
    }

    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (status.isGranted) return true;
      final photos = await Permission.photos.request();
      return photos.isGranted;
    }

    return true;
  }

  Future<void> _apply(UserViewModel viewmodel) async {
    if (!_formKey.currentState!.validate()) return;

    final updatedUser = User(
      id: _user?.id,
      name: _nameController.text,
      email: _user?.email,
      phoneNumber: _phoneController.text,
      role: _user?.role,
      urlImage: _user?.urlImage,
    );

    try {
      await viewmodel.saveUser(updatedUser, _selectedImageFile);
      if (mounted && viewmodel.error.isEmpty) {
        context.pop();
        showSnackBar(
          context,
          'Perfil actualizado correctamente',
          success: true,
        );
      }
    } catch (e) {
      if (mounted) showSnackBar(context, 'Error al guardar el perfil: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewmodel = context.watch<UserViewModel>();
    final theme = Theme.of(context);

    return LoadingOverlay(
      isLoading: viewmodel.isLoading,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: SabrosAppBar(
          pageTitle: 'EDITAR PERFIL',
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => context.pop(),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(context),
              const SizedBox(height: 70),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: _buildForm(viewmodel),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Lógica de fallback: si no hay imagen en Firestore, usamos la de Firebase Auth (Google)
    final firebaseUser = firebase.FirebaseAuth.instance.currentUser;
    final effectivePhotoUrl = (_selectedImageFile != null)
        ? null
        : (_user?.urlImage != null && _user!.urlImage!.isNotEmpty)
        ? _user!.urlImage
        : firebaseUser?.photoURL;

    return SizedBox(
      height: 190,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withAlpha(200),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.surface, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(20),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    backgroundImage: _selectedImageFile != null
                        ? FileImage(_selectedImageFile!) as ImageProvider
                        : (effectivePhotoUrl != null &&
                              effectivePhotoUrl.isNotEmpty)
                        ? NetworkImage(effectivePhotoUrl)
                        : null,
                    child:
                        (_selectedImageFile == null &&
                            (effectivePhotoUrl == null ||
                                effectivePhotoUrl.isEmpty))
                        ? Icon(
                            Icons.person,
                            size: 70,
                            color: colorScheme.onSurfaceVariant,
                          )
                        : null,
                  ),
                ),
                Positioned(
                  bottom: 5,
                  right: 5,
                  child: GestureDetector(
                    onTap: _showPickImageOptions,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.secondary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.surface,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(40),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        color: colorScheme.onSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(UserViewModel viewmodel) {
    final colorScheme = Theme.of(context).colorScheme;
    final homeVM = context.watch<HomeViewModel>();

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            controller: _nameController,
            label: 'NOMBRE COMPLETO',
            hint: 'Tu nombre aquí...',
            icon: Icons.person_outline,
            validator: (v) =>
                v == null || v.isEmpty ? 'El nombre es obligatorio' : null,
          ),
          const SizedBox(height: 24),
          AppTextField(
            controller: _phoneController,
            label: 'TELÉFONO',
            hint: 'Ej: 600 000 000',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 40),
          Center(
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                onPressed: () => _apply(viewmodel),
                child: const Text(
                  'GUARDAR CAMBIOS',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          if (homeVM.actualRole == 'ADMIN') ...[
            const SizedBox(height: 48),
            const Divider(),
            const SizedBox(height: 24),
            Text(
              'OPCIONES DE ADMINISTRADOR',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary.withAlpha(150),
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Modo Vista Cliente'),
              subtitle: const Text('Oculta las funciones de administrador'),
              value: homeVM.previewMode,
              onChanged: (_) => homeVM.togglePreviewMode(),
              secondary: Icon(
                homeVM.previewMode ? Icons.visibility : Icons.visibility_off,
                color: colorScheme.primary,
              ),
              contentPadding: EdgeInsets.zero,
            ),
          ],
          const SizedBox(height: 40),
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
