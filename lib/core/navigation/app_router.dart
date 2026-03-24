import 'dart:async';
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

// Hace que GoRouter reaccione a cambios en FirebaseAuth
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

  refreshListenable: GoRouterRefreshStream(
    FirebaseAuth.instance
        .authStateChanges(), // recarga cuando se producen cambios de user
  ),

  redirect: (context, state) {
    //cuando recarga, redirige siguiendo la lógica de aquí dentro
    final user = FirebaseAuth.instance.currentUser;

    final isLogin = state.uri.toString() == AppRoutes.login;
    final isRegister = state.uri.toString() == AppRoutes.register;

    if (user == null && !isLogin && !isRegister) {
      return AppRoutes.login;
    }

    if (user != null && (isLogin || isRegister)) {
      return AppRoutes.home;
    }

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
      routes: [
        GoRoute(
          path: 'form', //USO context.go(AppRoutes.dishFormCreate())
          builder: (context, state) => ChangeNotifierProvider(
            create: (_) => DishViewModel(DishService()),
            child: const DishFormView(),
          ),
        ),
        GoRoute(
          path:
              'form/:id', //USO context.go(AppRoutes.dishFormEdit('id del plato a editar'))
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return ChangeNotifierProvider(
              create: (_) => DishViewModel(DishService()),
              child: DishFormView(dishId: id),
            );
          },
        ),
        GoRoute(
          path:
              'detail/:id', //USO context.go(AppRoutes.dishDetail('id del plato'))
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return ChangeNotifierProvider(
              create: (_) => DishViewModel(DishService()),
              child: DishDetailView(dishId: id),
            );
          },
        ),
      ],
    ),
  ],
);
