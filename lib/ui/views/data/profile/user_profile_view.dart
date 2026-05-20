import 'package:app_restaurante/core/widgets/app_card.dart';
import 'package:app_restaurante/core/widgets/app_badge.dart';
import 'package:app_restaurante/core/navigation/app_routes.dart';
import 'package:app_restaurante/core/widgets/app_bottom_nav.dart';
import 'package:app_restaurante/core/widgets/loading_overlay.dart';
import 'package:app_restaurante/core/widgets/sabros_app_bar.dart';
import 'package:app_restaurante/data/model/user.dart' as model;
import 'package:app_restaurante/ui/viewmodels/firestore/user_viewmodel.dart';
import 'package:app_restaurante/ui/viewmodels/home/home_viewmodel.dart';
import 'package:app_restaurante/data/services/avatar/avatar_service.dart';
import 'package:app_restaurante/core/widgets/avatar_display.dart';
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
    _loadUser();
  }

  void _loadUser() {
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
    final user = viewmodel.user;
    final theme = Theme.of(context);

    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: SabrosAppBar(
          pageTitle: 'MI PERFIL',
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
        ),
        // AppBottomNav calcula el índice activo automáticamente por la ruta actual
        bottomNavigationBar: const AppBottomNav(),
        body: user == null
            ? Center(
                child: Text(
                  _error.isNotEmpty ? _error : "Usuario no encontrado",
                  style: theme.textTheme.bodyLarge,
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeader(context, user),
                    const SizedBox(height: 24),
                    _buildUserInfo(user),
                    const SizedBox(height: 32),
                    _buildActivitySection(context),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, model.User? user) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final firebaseUser = firebase.FirebaseAuth.instance.currentUser;
    final effectivePhotoUrl = AvatarService.resolveFromAuth(
      storageImage: user?.urlImage,
      googlePhotoUrl: user?.googlePhotoUrl,
      authUser: firebaseUser,
    );

    return SizedBox(
      height: 170,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 120,
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
            child: Stack(
              children: [
                Positioned(
                  top: 20,
                  right: 20,
                  child: GestureDetector(
                    onTap: () {
                      final uid =
                          firebase.FirebaseAuth.instance.currentUser?.uid;
                      if (uid != null) context.push(AppRoutes.profileEdit(uid));
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.onPrimary.withAlpha(51),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.settings,
                        color: colorScheme.onPrimary,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.surface, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: AvatarDisplay(
                imageUrl: effectivePhotoUrl,
                size: 110,
                backgroundColor: colorScheme.surfaceContainerHighest,
                iconColor: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo(model.User? user) {
    if (user == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final homeVM = context.watch<HomeViewModel>();
    final isAdmin = homeVM.userRole == 'ADMIN';

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              user.name ?? 'Usuario',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            if (isAdmin) ...[
              const SizedBox(width: 8),
              AppBadge.detail(label: 'ADMIN'),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          user.email ?? '',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodyMedium?.color?.withAlpha(180),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.phone_outlined,
              size: 16,
              color: colorScheme.primary.withAlpha(150),
            ),
            const SizedBox(width: 6),
            Text(
              user.phoneNumber ?? 'Sin teléfono',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActivitySection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final homeVM = context.watch<HomeViewModel>();
    final isRealAdmin = homeVM.actualRole == 'ADMIN';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MI CUENTA',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          if (isRealAdmin) ...[
            _buildActivityCard(
              icon: Icons.store_outlined,
              title: 'Gestionar mi restaurante',
              onTap: () => context.push(AppRoutes.restaurantForm),
            ),
            const SizedBox(height: 12),
            _buildActivityCard(
              icon: homeVM.previewMode
                  ? Icons.visibility
                  : Icons.visibility_off,
              title: homeVM.previewMode
                  ? 'Desactivar vista cliente'
                  : 'Activar vista cliente',
              subtitle: homeVM.previewMode
                  ? 'Viendo como cliente'
                  : 'Viendo como administrador',
              onTap: () => homeVM.togglePreviewMode(),
              trailing: Switch(
                value: homeVM.previewMode,
                onChanged: (_) => homeVM.togglePreviewMode(),
                activeThumbColor: colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 12),
          ],
          _buildActivityCard(
            icon: Icons.calendar_today_outlined,
            title: 'Mis reservas',
            // Corregido: la ruta '/reservations/my' no existía,
            // usamos AppRoutes.reservations que sí está registrada en el router
            onTap: () => context.go(AppRoutes.reservations),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      borderRadius: 18,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: colorScheme.primary, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          trailing ??
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant.withAlpha(150),
                size: 20,
              ),
        ],
      ),
    );
  }
}
