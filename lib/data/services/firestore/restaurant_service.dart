import 'package:app_restaurante/data/model/restaurant.dart';
import 'package:app_restaurante/data/repositories/restaurant_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RestaurantService {
  // Singleton repository
  final RestaurantRepository _repository = RestaurantRepository();

  // ─── Streams ─────────────────────────────

  Stream<List<Restaurant>> watchRestaurants() => _repository.watchAll();

  Stream<Restaurant?> watchRestaurantById(String id) =>
      _repository.watchById(id);

  Stream<Restaurant?> watchRestaurantByAdminId(String adminId) =>
      _repository.watchByAdminId(adminId);

  // ─── Métodos CRUD ────────────────────────

  Future<List<Restaurant>> getAllRestaurants() async =>
      _handleErrors(() => _repository.getAll());

  Future<Restaurant?> getRestaurantById(String id) async =>
      _handleErrors(() => _repository.getById(id));

  Future<Restaurant?> getRestaurantByAdminId(String adminId) async =>
      _handleErrors(() => _repository.getByAdminId(adminId));

  Future<void> createRestaurant(Restaurant restaurant) async =>
      _handleErrors(() => _repository.create(restaurant));

  Future<void> updateRestaurant(Restaurant restaurant) async =>
      _handleErrors(() => _repository.update(restaurant));

  Future<void> deleteRestaurant(String id) async =>
      _handleErrors(() => _repository.delete(id));

  // ─── Manejo de errores ────────────────────

  Future<T> _handleErrors<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseException catch (e) {
      throw _mapFirebaseException(e);
    } catch (e) {
      throw 'Error inesperado: $e';
    }
  }

  String _mapFirebaseException(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'No tienes permisos para realizar esta operación.';
      case 'not-found':
        return 'El documento no existe.';
      case 'already-exists':
        return 'El documento ya existe.';
      case 'resource-exhausted':
        return 'Se ha excedido el límite de recursos.';
      case 'unavailable':
        return 'El servicio no está disponible actualmente.';
      case 'cancelled':
        return 'La operación fue cancelada.';
      case 'invalid-argument':
        return 'Los datos proporcionados no son válidos.';
      case 'deadline-exceeded':
        return 'La operación tardó demasiado en completarse.';
      default:
        return 'Error de base de datos: ${e.message}';
    }
  }
}
