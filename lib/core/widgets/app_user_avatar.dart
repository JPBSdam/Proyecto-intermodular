import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:app_restaurante/core/navigation/app_routes.dart';
import 'package:app_restaurante/ui/viewmodels/firestore/user_viewmodel.dart';
import 'package:app_restaurante/data/services/auth/auth_service.dart';

/// Avatar de usuario unificado que se muestra en la AppBar.
///
/// Al pulsar sobre él, despliega un BottomSheet con información rápida del perfil
/// y acciones comunes (Editar, Cerrar Sesión).
class AppUserAvatar extends StatelessWidget {
  const AppUserAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    final userViewModel = context.watch<UserViewModel>();
    final authService = AuthService();
    final firebaseUser = authService.currentUser;
    final bool isGuest = firebaseUser?.isAnonymous ?? true;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Foto o icono de avatar
    Widget avatarChild;
    if (userViewModel.user?.urlImage != null &&
        userViewModel.user!.urlImage!.isNotEmpty) {
      avatarChild = ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.network(
          userViewModel.user!.urlImage!,
          fit: BoxFit.cover,
          width: 36,
          height: 36,
        ),
      );
    } else {
      avatarChild = Icon(
        Icons.account_circle_outlined,
        color: colorScheme.primary,
        size: 24,
      );
    }

    return GestureDetector(
      onTap: () =>
          _showProfileSheet(context, userViewModel, isGuest, authService),
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: colorScheme.primary.withAlpha(25),
            shape: BoxShape.circle,
          ),
          child: Center(child: avatarChild),
        ),
      ),
    );
  }

  void _showProfileSheet(
    BuildContext context,
    UserViewModel userVM,
    bool isGuest,
    AuthService auth,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool isAdmin = userVM.user?.role == 'admin';

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        if (isGuest) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.account_circle_outlined,
                  size: 64,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 12),
                Text(
                  'Accede a tu cuenta',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Inicia sesión para gestionar tus reservas.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push(AppRoutes.login);
                    },
                    child: const Text('Iniciar Sesión'),
                  ),
                ),
              ],
            ),
          );
        } else {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  backgroundImage: (userVM.user?.urlImage != null)
                      ? NetworkImage(userVM.user!.urlImage!)
                      : null,
                  child: (userVM.user?.urlImage == null)
                      ? Icon(
                          Icons.person,
                          size: 40,
                          color: colorScheme.onSurfaceVariant,
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      userVM.user?.name ?? 'Usuario',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isAdmin) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withAlpha(30),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: colorScheme.primary.withAlpha(60),
                          ),
                        ),
                        child: Text(
                          'ADMIN',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  userVM.user?.email ?? '',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Editar mi perfil'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push(AppRoutes.profile);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.logout, color: colorScheme.error),
                  title: Text(
                    'Cerrar Sesión',
                    style: TextStyle(
                      color: colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await auth.signOut();
                  },
                ),
              ],
            ),
          );
        }
      },
    );
  }
}
