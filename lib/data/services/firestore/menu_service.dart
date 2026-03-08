import 'package:app_restaurante/data/model/menu.dart';
import 'package:app_restaurante/data/repositories/menu_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MenuService {
  final MenuRepository _repository;

  MenuService(this._repository);

  Stream<List<Menu>> watchMenus() {
    return _repository.watchAll();
  }

  Future<Menu?> getMenuById(String id) async {
    try {
      return await _repository.getById(id);
    } on FirebaseException catch (e) {
      throw _handleFirestoreException(e);
    } catch (e) {
      throw 'Error al obtener el menú: $e';
    }
  }

  Future<void> createMenu(Menu menu) async {
    try {
      await _repository.create(menu);
    } on FirebaseException catch (e) {
      throw _handleFirestoreException(e);
    } catch (e) {
      throw 'Error al crear el menú: $e';
    }
  }

  Future<void> updateMenu(Menu menu) async {
    try {
      await _repository.update(menu);
    } on FirebaseException catch (e) {
      throw _handleFirestoreException(e);
    } catch (e) {
      throw 'Error al actualizar el menú: $e';
    }
  }

  Future<void> deleteMenu(String id) async {
    try {
      await _repository.delete(id);
    } on FirebaseException catch (e) {
      throw _handleFirestoreException(e);
    } catch (e) {
      throw 'Error al eliminar el menú: $e';
    }
  }

  Future<void> clearMenusBatch() async {
  try {
    final menus = await _repository.watchAll().first;
    final ids = menus.where((m) => m.id != null).map((m) => m.id!).toList();
    await _repository.deleteBatch(ids);
  } on FirebaseException catch (e) {
    throw _handleFirestoreException(e);
  } catch (e) {
    throw 'Error al limpiar menús con batch: $e';
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