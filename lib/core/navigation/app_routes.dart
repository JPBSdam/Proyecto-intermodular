// Definición centralizada de rutas de la aplicación.
//
// - Contiene todas las rutas como constantes (paths base)
// - Genera rutas dinámicas con parámetros (ej: id)
// - Se usa para navegar con `context.go(...)`
//
// Permite mantener consistencia y evitar errores al construir URLs.

class AppRoutes {
  // ────── CORE ──────
  static const String home = '/home';

  // ────── AUTH ──────
  static const String login = '/login';
  static const String register = '/register';

  // ────── USER PROFILE ──────
  static const String profile = '/profile';
  static String profileEdit(String id) => '/profile/form/$id';

  // ────── RESTAURANT ──────
  static const restaurantForm = '/restaurant/form';

  // ────── DISHES ──────
  static const String dishes = '/dishes';
  static String dishDetail(String id) => '$dishes/detail/$id';
  static String dishFormCreate() => '$dishes/form';
  static String dishFormEdit(String id) => '$dishes/form/$id';

  // ────── MENUS ──────
  static const String menus = '/menus';
  static String menuDetail(String id) => '$menus/detail/$id';
  static String menuFormCreate() => '$menus/form';
  static String menuFormEdit(String id) => '$menus/form/$id';
}
