import 'package:app_restaurante/data/model/dish.dart';
import 'package:app_restaurante/data/repositories/dish_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DishService {
  // Singleton repository
  final DishRepository _repository = DishRepository();

  // ─── Streams ─────────────────────────────
  Stream<List<Dish>> watchDishes() => _repository.watchAll();

  // ─── Métodos CRUD ────────────────────────
  Future<List<Dish>> getAllDishes() async =>
      _handleErrors(() => _repository.getAll());

  Future<Dish?> getDishById(String id) async =>
      _handleErrors(() => _repository.getById(id));

  Future<void> createDish(Dish dish) async =>
      _handleErrors(() => _repository.create(dish));

  Future<void> updateDish(Dish dish) async =>
      _handleErrors(() => _repository.update(dish));

  Future<void> deleteDish(String id) async =>
      _handleErrors(() => _repository.delete(id));

  // ─── Manejo de errores ─── Esto es como un decorador para los metodos que recibe
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
