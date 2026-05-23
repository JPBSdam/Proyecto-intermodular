// Definición centralizada de rutas de la aplicación.

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

  // ────── RESERVATIONS ──────
  static const String reservations = '/reservations';
  static String reservationDetail(String id) => '$reservations/detail/$id';
  static String reservationFormCreate() => '$reservations/form';
  static String reservationFormEdit(String id) => '$reservations/form/$id';

  // ────── ADMIN NOTIFICATIONS ──────
  // Vista exclusiva para administradores con las reservas pendientes de gestionar
  static const String adminNotifications = '/notifications';
}
