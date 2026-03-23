import 'dart:async';
import 'package:app_restaurante/core/widgets/home_button.dart';
import 'package:app_restaurante/ui/viewmodels/auth/login_viewmodel.dart';
import 'package:app_restaurante/ui/viewmodels/auth/register_viewmodel.dart';
import 'package:app_restaurante/ui/viewmodels/home/home_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'app_routes.dart';

// Views
import '../../ui/views/auth/login_view.dart';
import '../../ui/views/auth/register_view.dart';
import '../../ui/views/home/home_view.dart';

import '../../ui/views/data/dish_list_view.dart';
import '../../ui/views/data/dish_details_view.dart';
import '../../ui/views/data/dish_form_view.dart';

//import '../../ui/views/data/menu_list_view.dart';
//import '../../ui/views/data/menu_details_view.dart';
//import '../../ui/views/data/menu_form_view.dart';

// ViewModels
import '../../ui/viewmodels/firestore/dish_viewmodel.dart';
//import '../../ui/viewmodels/firestore/menu_viewmodel.dart';

// Services
import '../../data/services/firestore/dish_service.dart';
import '../../data/services/firestore/menu_service.dart';

/// 🔁 Hace que GoRouter reaccione a cambios en FirebaseAuth
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

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.home,

  //gorouter escucha cambios de estado de usuario
  refreshListenable: GoRouterRefreshStream(
    FirebaseAuth.instance.authStateChanges(),
  ),

  //redirige en función del estado, lo que antes hacía authwrapper
  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;

    final isLogin = state.uri.toString() == AppRoutes.login;
    final isRegister = state.uri.toString() == AppRoutes.register;

    // No autenticado → login
    if (user == null && !isLogin && !isRegister) {
      return AppRoutes.login;
    }

    // Autenticado → home si está en login/register
    if (user != null && (isLogin || isRegister)) {
      return AppRoutes.home;
    }

    return null;
  },

  //Esto es una página que se muestra si hay algun error de rutas
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(
      title: const Text('Ruta no encontrada'),
      actions: [HomeButton()],
    ),
    body: Center(child: Text('No se encontró la ruta: ${state.uri}')),
  ),

  //y aqui van las rutas de la app
  routes: [
    // ────── HOME ──────
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => ChangeNotifierProvider(
        create: (_) => HomeViewModel(),
        child: const HomeView(title: 'Restaurante'),
      ),
    ),

    // ────── AUTH ──────
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => ChangeNotifierProvider(
        create: (_) => LoginViewModel(),
        child: LoginView(),
      ),
    ),
    GoRoute(
      path: AppRoutes.register,
      builder: (context, state) => ChangeNotifierProvider(
        create: (_) => RegisterViewModel(),
        child: RegisterView(),
      ),
    ),

    // ────── DISHES ──────
    GoRoute(
      path: AppRoutes.dishes,
      builder: (context, state) => ChangeNotifierProvider(
        create: (_) => DishViewModel(DishService())..watchDishes(),
        child: const DishesListView(),
      ),
      /* routes: [
        GoRoute(
          path: 'form',
          builder: (context, state) => const DishFormView(),
        ),
        GoRoute(
          path: 'form/:id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return DishFormView(dishId: id);
          },
        ),
        GoRoute(
          path: 'detail/:id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return DishDetailView(dishId: id);
          },
        ),
      ], */
    ),

    // ────── MENUS ──────
    /*GoRoute(
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
        child: const MenusListView(),
      ),
      routes: [
        GoRoute(
          path: 'form',
          builder: (context, state) => const MenuFormView(),
        ),
        GoRoute(
          path: 'form/:id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return MenuFormView(menuId: id);
          },
        ),
        GoRoute(
          path: 'detail/:id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return MenuDetailView(menuId: id);
          },
        ),
      ],
    ),*/
  ],
);
