import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:app_restaurante/core/navigation/app_routes.dart';
import 'package:app_restaurante/core/widgets/app_badge.dart';
import 'package:app_restaurante/core/widgets/app_logo_title.dart';
import 'package:app_restaurante/ui/viewmodels/firestore/reservation_viewmodel.dart';
import 'package:app_restaurante/ui/viewmodels/home/home_viewmodel.dart';
import 'package:provider/provider.dart';

/// Drawer lateral unificado con estética Premium.
///
/// Gestiona el acceso a todas las secciones de la app, incluyendo la administración.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final homeVM = context.watch<HomeViewModel>();
    final reservationVM = context.watch<ReservationViewModel>();
    final bool isAnonymous = homeVM.isGuest;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Datos de visualización centralizados
    final String name = homeVM.displayName;
    final String email = homeVM.isGuest
        ? 'Accede para gestionar reservas'
        : homeVM.email;
    final String? photoUrl = homeVM.photoUrl;
    final bool isAdmin = homeVM.userRole == 'ADMIN';

    String currentPath = GoRouterState.of(context).uri.path;
    if (currentPath == '/') currentPath = AppRoutes.home;

    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          _buildPremiumHeader(context, name, email, photoUrl, isAdmin),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                _buildDrawerItem(
                  context: context,
                  icon: Icons.home_outlined,
                  label: 'Inicio',
                  route: AppRoutes.home,
                  currentPath: currentPath,
                ),
                if (!isAnonymous)
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.person_outline,
                    label: 'Mi perfil',
                    route: AppRoutes.profile,
                    currentPath: currentPath,
                  ),
                _buildSectionTitle(context, 'EXPLORAR'),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.restaurant_menu_outlined,
                  label: 'Platos',
                  route: AppRoutes.dishes,
                  currentPath: currentPath,
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.menu_book_outlined,
                  label: 'Menús',
                  route: AppRoutes.menus,
                  currentPath: currentPath,
                ),

                // Sección de Reservas (Solo para usuarios autenticados)
                if (!isAnonymous) ...[
                  _buildSectionTitle(context, 'RESERVAS'),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.calendar_today_outlined,
                    label: 'Reservar mesa',
                    route: AppRoutes.reservationFormCreate(),
                    currentPath: currentPath,
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.history_outlined,
                    label: 'Mis reservas',
                    route: AppRoutes.reservations,
                    currentPath: currentPath,
                  ),
                ],

                // Sección de Administración (Solo visible para admins)
                if (isAdmin) ...[
                  _buildSectionTitle(context, 'ADMINISTRACIÓN'),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.storefront_outlined,
                    label: 'Mi Restaurante',
                    route: AppRoutes.restaurantForm,
                    currentPath: currentPath,
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.assignment_outlined,
                    label: 'Gestión Reservas',
                    route: AppRoutes.reservations,
                    currentPath: currentPath,
                    trailing: reservationVM.pendingCount > 0
                        ? _buildBadge(
                            context,
                            reservationVM.pendingCount.toString(),
                          )
                        : null,
                  ),
                ],
              ],
            ),
          ),
          Divider(indent: 20, endIndent: 20, color: colorScheme.outlineVariant),
          _buildLogoutTile(context, isAnonymous, homeVM),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPremiumHeader(
    BuildContext context,
    String name,
    String email,
    String? photo,
    bool isAdmin,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        bottom: 24,
        left: 24,
        right: 24,
      ),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        image: const DecorationImage(
          image: NetworkImage(
            'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?q=80&w=2070&auto=format&fit=crop',
          ),
          fit: BoxFit.cover,
          opacity: 0.15,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.primary, colorScheme.primary.withAlpha(200)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppLogoTitle(
            color: colorScheme.onPrimary,
            fontSize: 22,
            iconSize: 24,
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: colorScheme.onPrimary,
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  backgroundImage: (photo != null && photo.isNotEmpty)
                      ? NetworkImage(photo)
                      : null,
                  child: (photo == null || photo.isEmpty)
                      ? Text(
                          (name.isNotEmpty ? name[0] : 'U').toUpperCase(),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isAdmin) ...[
                          const SizedBox(width: 8),
                          const AppBadge(label: 'ADMIN', borderRadius: 4),
                        ],
                      ],
                    ),
                    Text(
                      email,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onPrimary.withAlpha(180),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String route,
    required String currentPath,
    bool isAction = false,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool isSelected =
        currentPath == route ||
        (route != AppRoutes.home && currentPath.startsWith(route));

    return ListTile(
      dense: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Icon(
        icon,
        color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
        size: 22,
      ),
      title: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? colorScheme.primary : colorScheme.onSurface,
        ),
      ),
      trailing: trailing,
      selected: isSelected,
      selectedTileColor: colorScheme.primaryContainer.withAlpha(100),
      onTap: () {
        Navigator.pop(context);
        if (isSelected && currentPath == route) return;
        try {
          isAction ? context.push(route) : context.go(route);
        } catch (_) {}
      },
    );
  }

  Widget _buildBadge(BuildContext context, String count) {
    return AppBadge(
      label: count,
      backgroundColor: Theme.of(context).colorScheme.secondary,
      textColor: Theme.of(context).colorScheme.onSecondary,
      borderRadius: 10,
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 20, bottom: 8),
      child: Text(
        title,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildLogoutTile(
    BuildContext context,
    bool isAnonymous,
    HomeViewModel homeVM,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isAnonymous ? colorScheme.primary : colorScheme.error;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      leading: Icon(isAnonymous ? Icons.login : Icons.logout, color: color),
      title: Text(
        isAnonymous ? 'Iniciar Sesión' : 'Cerrar sesión',
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
      onTap: () async {
        Navigator.pop(context);
        if (isAnonymous) {
          context.push(AppRoutes.login);
        } else {
          await homeVM.signOut();
        }
      },
    );
  }
}
