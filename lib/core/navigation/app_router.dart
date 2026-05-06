import 'dart:async';
import 'package:app_restaurante/data/services/firestore/menu_service.dart';
import 'package:app_restaurante/data/services/firestore/reservation_service.dart';
import 'package:app_restaurante/data/services/firestore/restaurant_service.dart';
import 'package:app_restaurante/ui/viewmodels/firestore/menu_viewmodel.dart';
import 'package:app_restaurante/ui/viewmodels/firestore/reservation_viewmodel.dart';
import 'package:app_restaurante/ui/viewmodels/firestore/restaurant_viewmodel.dart';
import 'package:app_restaurante/ui/views/data/menus/menu_details_view.dart';
import 'package:app_restaurante/ui/views/data/menus/menu_form_view.dart';
import 'package:app_restaurante/ui/views/data/menus/menu_list_view.dart';
import 'package:app_restaurante/ui/views/data/reservations/reservation_detail_view.dart';
import 'package:app_restaurante/ui/views/data/reservations/reservation_form_view.dart';
import 'package:app_restaurante/ui/views/data/reservations/reservation_list_view.dart';
import 'package:app_restaurante/ui/views/data/restaurant/restaurant_form_view.dart';
// Vista de avisos/notificaciones para administradores (reservas pendientes)
import 'package:app_restaurante/ui/views/data/notifications/admin_notifications_view.dart';
import 'package:app_restaurante/ui/views/error/not_found_view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

// Core
import 'package:app_restaurante/core/navigation/app_routes.dart';

// Views
import 'package:app_restaurante/ui/views/auth/login_view.dart';
import 'package:app_restaurante/ui/views/auth/register_view.dart';
import 'package:app_restaurante/ui/views/home/home_view.dart';
import 'package:app_restaurante/ui/views/data/dishes/dish_list_view.dart';
import 'package:app_restaurante/ui/views/data/dishes/dish_details_view.dart';
import 'package:app_restaurante/ui/views/data/dishes/dish_form_view.dart';

// ViewModels
import 'package:app_restaurante/ui/viewmodels/auth/login_viewmodel.dart';
import 'package:app_restaurante/ui/viewmodels/auth/register_viewmodel.dart';
import 'package:app_restaurante/ui/viewmodels/firestore/dish_viewmodel.dart';

// Services
import 'package:app_restaurante/data/services/firestore/dish_service.dart';

import '../../ui/viewmodels/firestore/user_viewmodel.dart';
import '../../ui/views/data/profile/user_form_view.dart';
import '../../ui/views/data/profile/user_profile_view.dart';

// Helper para reaccionar a cambios de auth en GoRouter
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }
  late final StreamSubscription _subscription;
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

// ─── INSTANCIAS GLOBALES ───
// Movidas a Providers para mejor gestión de ciclo de vida

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  refreshListenable: GoRouterRefreshStream(
    FirebaseAuth.instance.authStateChanges(),
  ),

  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;
    final location = state.matchedLocation;

    final isAuthRoute =
        location == AppRoutes.login || location == AppRoutes.register;
    final isProtectedRoute =
        location.startsWith('/profile') || location.startsWith('/reservations');

    // 1. Si no hay usuario y trata de ir a zona protegida -> Login
    if (user == null && isProtectedRoute) {
      return AppRoutes.login;
    }

    // 2. Si ya tiene sesión REAL (no anónimo) y trata de ir a Login/Register -> Home
    if (user != null && !user.isAnonymous && isAuthRoute) {
      return AppRoutes.home;
    }

    return null;
  },

  routes: [
    // ────── HOME ──────
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomeView(title: 'SabrosApp'),
    ),

    // ────── AUTH ──────
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => ChangeNotifierProvider(
        create: (_) => LoginViewModel(),
        child: const LoginView(),
      ),
    ),
    GoRoute(
      path: AppRoutes.register,
      builder: (context, state) => ChangeNotifierProvider(
        create: (_) => RegisterViewModel(),
        child: const RegisterView(),
      ),
    ),

    // ────── USER PROFILE ──────
    GoRoute(
      path: AppRoutes.profile,
      builder: (context, state) => const UserProfileView(),
    ),
    GoRoute(
      path: '/profile/form/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return ChangeNotifierProvider(
          create: (_) => UserViewModel(),
          child: UserFormView(userId: id),
        );
      },
    ),

    // ────── RESTAURANT ──────
    GoRoute(
      path: AppRoutes.restaurantForm,
      builder: (context, state) => ChangeNotifierProvider(
        create: (_) =>
            RestaurantViewModel(RestaurantService())..watchRestaurant(),
        child: const RestaurantFormView(),
      ),
    ),

    // ────── DISHES ──────
    GoRoute(
      path: AppRoutes.dishes,
      builder: (context, state) => ChangeNotifierProvider(
        create: (_) => DishViewModel(DishService())..watchDishes(),
        child: const DishesListView(),
      ),
    ),
    GoRoute(
      path: '/dishes/form',
      builder: (context, state) => ChangeNotifierProvider(
        create: (_) => DishViewModel(DishService()),
        child: const DishFormView(),
      ),
    ),
    GoRoute(
      path: '/dishes/form/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return ChangeNotifierProvider(
          create: (_) => DishViewModel(DishService()),
          child: DishFormView(dishId: id),
        );
      },
    ),
    GoRoute(
      path: '/dishes/detail/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return ChangeNotifierProvider(
          create: (_) => DishViewModel(DishService()),
          child: DishDetailView(dishId: id),
        );
      },
    ),

    // ────── MENUS ──────
    GoRoute(
      path: AppRoutes.menus,
      builder: (context, state) => MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) =>
                MenuViewModel(MenuService(), DishService())..watchMenus(),
          ),
          ChangeNotifierProvider(
            create: (_) => DishViewModel(DishService())..watchDishes(),
          ),
        ],
        child: const MenuListView(),
      ),
    ),
    GoRoute(
      path: '/menus/form',
      builder: (context, state) => MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => MenuViewModel(MenuService(), DishService()),
          ),
          ChangeNotifierProvider(
            create: (_) => DishViewModel(DishService())..watchDishes(),
          ),
        ],
        child: const MenuFormView(),
      ),
    ),
    GoRoute(
      path: '/menus/form/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) => MenuViewModel(MenuService(), DishService()),
            ),
            ChangeNotifierProvider(
              create: (_) => DishViewModel(DishService())..watchDishes(),
            ),
          ],
          child: MenuFormView(menuId: id),
        );
      },
    ),
    GoRoute(
      path: '/menus/detail/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) => MenuViewModel(MenuService(), DishService()),
            ),
            ChangeNotifierProvider(
              create: (_) => DishViewModel(DishService())..watchDishes(),
            ),
          ],
          child: MenuDetailView(menuId: id),
        );
      },
    ),

    // ────── RESERVATIONS ──────
    GoRoute(
      path: AppRoutes.reservations,
      builder: (context, state) {
        final userId = FirebaseAuth.instance.currentUser?.uid;
        return ChangeNotifierProvider(
          create: (_) => ReservationViewModel(ReservationService()),
          child: ReservationListView(userId: userId),
        );
      },
    ),
    GoRoute(
      path: '/reservations/form',
      builder: (context, state) => ChangeNotifierProvider(
        create: (_) => ReservationViewModel(ReservationService()),
        child: const ReservationFormView(),
      ),
    ),
    GoRoute(
      path: '/reservations/form/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return ChangeNotifierProvider(
          create: (_) => ReservationViewModel(ReservationService()),
          child: ReservationFormView(reservationId: id),
        );
      },
    ),
    GoRoute(
      path: '/reservations/detail/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return ChangeNotifierProvider(
          create: (_) => ReservationViewModel(ReservationService()),
          child: ReservationDetailView(reservationId: id),
        );
      },
    ),

    // ────── ADMIN NOTIFICATIONS ──────
    // Ruta exclusiva para administradores: muestra las reservas pendientes
    // con acciones rápidas de confirmar/cancelar y el badge en la barra inferior
    GoRoute(
      path: AppRoutes.adminNotifications,
      builder: (context, state) => const AdminNotificationsView(),
    ),
  ],
);
