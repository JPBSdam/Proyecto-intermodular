import 'package:app_restaurante/data/services/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:app_restaurante/core/navigation/app_routes.dart';

/// Widget de navegación inferior unificado para SabrosApp.
///
/// Controla la navegación entre las secciones principales.
class AppBottomNav extends StatelessWidget {
  /// Índice de la pestaña actualmente seleccionada.
  final int currentIndex;

  const AppBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authService = AuthService();
    final bool isGuest = authService.currentUser?.isAnonymous ?? true;

    // Definición de las pestañas disponibles
    final List<_BottomNavItem> allItems = [
      _BottomNavItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        label: 'INICIO',
        route: AppRoutes.home,
      ),
      _BottomNavItem(
        icon: Icons.menu_book_outlined,
        activeIcon: Icons.menu_book,
        label: 'CARTA',
        route: AppRoutes.dishes,
      ),
      if (!isGuest)
        _BottomNavItem(
          icon: Icons.calendar_today_outlined,
          activeIcon: Icons.calendar_today,
          label: 'RESERVA',
          route: AppRoutes.reservationFormCreate(),
        ),
      _BottomNavItem(
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: 'PERFIL',
        route: AppRoutes.profile,
      ),
    ];

    // Ajustar el currentIndex si es necesario (por ejemplo, si se oculta una pestaña)
    // En este caso, asumimos que el currentIndex pasado es relativo a la lista filtrada.

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          if (index == currentIndex) return;
          context.go(allItems[index].route);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurface.withAlpha(120),
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: allItems.map((item) {
          return BottomNavigationBarItem(
            icon: Icon(item.icon),
            activeIcon: Icon(item.activeIcon),
            label: item.label,
          );
        }).toList(),
      ),
    );
  }
}

class _BottomNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;

  _BottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });
}
