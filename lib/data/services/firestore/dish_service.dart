import 'package:app_restaurante/data/model/dish.dart';
import 'package:app_restaurante/data/repositories/dish_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DishService {
  final DishRepository _repository;

  DishService(this._repository);

  Stream<List<Dish>> watchDishes() {
    return _repository.watchAll();
  }

  Future<Dish?> getDishById(String id) async {
    try {
      return await _repository.getById(id);
    } on FirebaseException catch (e) {
      throw _handleFirestoreException(e);
    } catch (e) {
      throw 'Error al obtener el plato: $e';
    }
  }

  Future<void> createDish(Dish dish) async {
    try {
      await _repository.create(dish);
    } on FirebaseException catch (e) {
      throw _handleFirestoreException(e);
    } catch (e) {
      throw 'Error al crear el plato: $e';
    }
  }

  Future<void> updateDish(Dish dish) async {
    try {
      await _repository.update(dish);
    } on FirebaseException catch (e) {
      throw _handleFirestoreException(e);
    } catch (e) {
      throw 'Error al actualizar el plato: $e';
    }
  }

  Future<void> deleteDish(String id) async {
    try {
      await _repository.delete(id);
    } on FirebaseException catch (e) {
      throw _handleFirestoreException(e);
    } catch (e) {
      throw 'Error al eliminar el plato: $e';
    }
  }

  Future<void> clearDishesBatch() async {
  try {
    final dishes = await _repository.watchAll().first;
    final ids = dishes.where((d) => d.id != null).map((d) => d.id!).toList();
    await _repository.deleteBatch(ids);
  } on FirebaseException catch (e) {
    throw _handleFirestoreException(e);
  } catch (e) {
    throw 'Error al limpiar platos con batch: $e';
  }
}

  String _handleFirestoreException(FirebaseException e) {
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