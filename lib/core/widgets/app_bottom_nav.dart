import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:app_restaurante/core/navigation/app_routes.dart';
import 'package:app_restaurante/ui/viewmodels/firestore/reservation_viewmodel.dart';
import 'package:app_restaurante/ui/viewmodels/home/home_viewmodel.dart';

/// Widget de navegación inferior unificado para SabrosApp.
/// Diferencia visualmente entre Admin (Gestión) y Usuario (Reserva).
class AppBottomNav extends StatelessWidget {
  /// Índice de la pestaña actualmente seleccionada.
  final int currentIndex;

  const AppBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Usamos ViewModels para conocer el estado
    final homeVM = context.watch<HomeViewModel>();
    final reservationVM = context.watch<ReservationViewModel>();

    final bool isGuest = homeVM.isGuest;
    final bool isAdmin = homeVM.userRole == 'ADMIN';

    // Aseguramos que si es Admin, el ViewModel esté escuchando
    if (isAdmin && !reservationVM.isWatching) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        reservationVM.watchAll();
      });
    }

    // Definición dinámica de las pestañas
    final List<_BottomNavItem> allItems = [
      _BottomNavItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        label: 'INICIO',
        route: AppRoutes.home,
      ),
      _BottomNavItem(
        icon: Icons.restaurant_menu_outlined,
        activeIcon: Icons.restaurant_menu,
        label: 'CARTA',
        route: AppRoutes.dishes,
      ),

      // Pestaña dinámica central
      if (!isGuest)
        isAdmin
            ? _BottomNavItem(
                icon: Icons.assignment_outlined,
                activeIcon: Icons.assignment,
                label: 'RESERVAS',
                route: AppRoutes.reservations,
                badgeCount: reservationVM.pendingCount,
              )
            : _BottomNavItem(
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
          letterSpacing: 0.5,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: allItems.map((item) {
          return BottomNavigationBarItem(
            icon: item.badgeCount != null && item.badgeCount! > 0
                ? Badge(
                    label: Text(item.badgeCount.toString()),
                    child: Icon(item.icon),
                  )
                : Icon(item.icon),
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
  final int? badgeCount;

  _BottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
    this.badgeCount,
  });
}
