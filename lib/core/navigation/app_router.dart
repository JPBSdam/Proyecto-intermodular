import 'dart:async';
import 'package:app_restaurante/data/services/firestore/menu_service.dart';
import 'package:app_restaurante/data/services/firestore/restaurant_service.dart';
import 'package:app_restaurante/data/services/firestore/user_service.dart';
import 'package:app_restaurante/ui/viewmodels/firestore/menu_viewmodel.dart';
import 'package:app_restaurante/ui/viewmodels/firestore/restaurant_viewmodel.dart';
import 'package:app_restaurante/ui/views/data/menus/menu_details_view.dart';
import 'package:app_restaurante/ui/views/data/menus/menu_form_view.dart';
import 'package:app_restaurante/ui/views/data/menus/menu_list_view.dart';
import 'package:app_restaurante/ui/views/data/restaurant/restaurant_form_view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

// Core
import 'package:app_restaurante/core/widgets/home_button.dart';
import 'package:app_restaurante/core/navigation/app_routes.dart';

// Views
import 'package:app_restaurante/ui/views/auth/login_view.dart';
import 'package:app_restaurante/ui/views/auth/register_view.dart';
import 'package:app_restaurante/ui/views/home/home_view.dart';
import 'package:app_restaurante/ui/views/data/dishes/dish_list_view.dart';
import 'package:app_restaurante/ui/views/data/dishes/dish_details_view.dart';
import 'package:app_restaurante/ui/views/data/dishes/dish_form_view.dart';

// ViewModels
import 'package:app_restaurante/ui/viewmodels/home/home_viewmodel.dart';
import 'package:app_restaurante/ui/viewmodels/auth/login_viewmodel.dart';
import 'package:app_restaurante/ui/viewmodels/auth/register_viewmodel.dart';
import 'package:app_restaurante/ui/viewmodels/firestore/dish_viewmodel.dart';

// Services
import 'package:app_restaurante/data/services/firestore/dish_service.dart';

import '../../ui/viewmodels/firestore/user_viewmodel.dart';
import '../../ui/views/data/profile/user_form_view.dart';
import '../../ui/views/data/profile/user_profile_view.dart';

/// Router global de la aplicación.
///
/// - Controla la autenticación:
///  • No logeado → redirige a /login
///  • Logeado → evita acceso a /login y /register
///
/// - Reacciona a cambios de sesión con FirebaseAuth (login/logout)
///
/// - Cada ruta crea su propio ViewModel con Provider
///  (se construye al entrar y se destruye al salir)
///
/// - Define todas las rutas y navegación de la app

// Hace que GoRouter reaccione a cambios en stream: FirebaseAuth.instance.authStateChanges()
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
final UserService userService = UserService();
bool userInitialized = false;
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.home,

  refreshListenable: GoRouterRefreshStream(
    FirebaseAuth.instance
        .authStateChanges(), // recarga cuando se producen cambios de user
  ),

  redirect: (context, state) async {
    // cuando recarga, redirige siguiendo la lógica de aquí dentro
    final user = FirebaseAuth.instance.currentUser;

    final isLogin = state.uri.toString() == AppRoutes.login;
    final isRegister = state.uri.toString() == AppRoutes.register;

    // 🔒 No autenticado → login
    if (user == null && !isLogin && !isRegister) {
      return AppRoutes.login;
    }

    // 🔥 Crear usuario en Firestore SOLO UNA VEZ
    if (user != null && !userInitialized) {
      userInitialized = true;
      await userService.ensureUserExistsFromAuth(user);
    }

    // 🔁 Evitar volver a login/register si ya está autenticado
    if (user != null && (isLogin || isRegister)) {
      return AppRoutes.home;
    }

    // El resto (invitados, anónimos, etc.) puede acceder a cualquier ruta libremente
    return null;
  },

  //pantalla que muestra errores de rutas
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(
      title: const Text('Ruta no encontrada'),
      actions: const [HomeButton()],
    ),
    body: Center(child: Text('No se encontró la ruta: ${state.uri}')),
  ),

  routes: [
    // ────── HOME ──────
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => HomeViewModel()),
          ChangeNotifierProvider(
            create: (_) =>
                RestaurantViewModel(RestaurantService())..watchRestaurant(),
          ),
        ],
        child: const HomeView(title: 'Restaurante'),
      ),
    ),

    // ────── AUTH ──────
    GoRoute(
      //USO: context.go(AppRoutes.login)
      path: AppRoutes.login,
      builder: (context, state) => ChangeNotifierProvider(
        create: (_) => LoginViewModel(),
        child: LoginView(),
      ),
    ),
    GoRoute(
      //USO: context.go(AppRoutes.register)
      path: AppRoutes.register,
      builder: (context, state) => ChangeNotifierProvider(
        create: (_) => RegisterViewModel(),
        child: RegisterView(),
      ),
    ),

    // ────── USER PROFILE ──────
    GoRoute(
      //USO: context.go(AppRoutes.profile)
      path: AppRoutes.profile,
      builder: (context, state) => ChangeNotifierProvider(
        create: (_) => UserViewModel(),
        child: const UserProfileView(),
      ),
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
      //USO: context.go(AppRoutes.dishes)
      path: AppRoutes.dishes,
      builder: (context, state) => ChangeNotifierProvider(
        create: (_) => DishViewModel(DishService())..watchDishes(),
        child: const DishesListView(),
      ),
    ),

    GoRoute(
      //USO: context.go(AppRoutes.dishFormCreate())
      path: '/dishes/form',
      builder: (context, state) => ChangeNotifierProvider(
        create: (_) => DishViewModel(DishService()),
        child: const DishFormView(),
      ),
    ),

    GoRoute(
      //USO: context.go(AppRoutes.dishFormEdit('platoID'))
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
      //USO: context.go(AppRoutes.dishDetail('platoID'))
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
      //USO: context.go(AppRoutes.menus)
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
      //USO: context.go(AppRoutes.menuFormCreate())
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
      //USO: context.go(AppRoutes.menuFormEdit('menuID'))
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
      //USO: context.go(AppRoutes.menuDetail('menuID'))
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
  ],
);
