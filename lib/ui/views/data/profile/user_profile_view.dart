import 'package:app_restaurante/core/navigation/app_routes.dart';
import 'package:app_restaurante/core/widgets/home_button.dart';
import 'package:app_restaurante/core/widgets/loading_overlay.dart';
import 'package:app_restaurante/ui/viewmodels/firestore/user_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;

class UserProfileView extends StatefulWidget {
  const UserProfileView({super.key});

  @override
  State<UserProfileView> createState() => _UserProfileViewState();
}

class _UserProfileViewState extends State<UserProfileView> {
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final viewmodel = context.read<UserViewModel>();
      final user = firebase.FirebaseAuth.instance.currentUser;

      if (user == null) {
        setState(() {
          _error = 'Usuario no autenticado';
          _isLoading = false;
        });
        return;
      }

      try {
        viewmodel.watchUser(user.uid);
      } catch (e) {
        setState(() => _error = 'Error: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewmodel = context.watch<UserViewModel>();

    Widget bodyContent;

    if (_error.isNotEmpty) {
      bodyContent = Center(child: Text(_error));
    } else if (viewmodel.user == null) {
      bodyContent = const Center(child: Text("Usuario no encontrado"));
    } else {
      final user = viewmodel.user!;

      bodyContent = Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.name ?? '',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text("Email: ${user.email ?? '-'}"),
            Text("Teléfono: ${user.phoneNumber ?? '-'}"),
            Text("Rol: ${user.role ?? '-'}"),
          ],
        ),
      );
    }

    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Perfil'),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                final user = viewmodel.user;
                if (user != null && user.id != null) {
                  context.go(AppRoutes.profileEdit(user.id!));
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
