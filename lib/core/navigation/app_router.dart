import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:app_restaurante/ui/views/home_screen.dart';
import 'package:app_restaurante/ui/viewmodels/home_viewmodel.dart';
import 'app_routes.dart';

final router = GoRouter(
  initialLocation: AppRoutes.home,
  debugLogDiagnostics: true,
  routes: [
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => ChangeNotifierProvider(
        create: (_) => HomeViewModel(),
        child: const HomeScreen(),
      ),
    ),
  ],
);
