import 'package:app_restaurante/data/model/menu.dart';
import 'package:app_restaurante/data/repositories/menu_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Servicio de gestión de menús que sirve como intermediario entre la aplicación
/// y el repositorio de datos (`MenuRepository`).
///
/// - Responsabilidades:
///   • Proporcionar operaciones CRUD sobre `Menu`
///   • Exponer un stream reactivo de menús (`watchMenus`)
///
/// - Arquitectura:
///   • Mantiene la lógica de negocio separada de la capa de acceso a datos
///   • Delega la persistencia y consultas al repositorio
///
/// - Manejo de errores:
///   • Centralizado mediante `_handleErrors`
///   • Traduce excepciones de Firebase a mensajes legibles para la UI
///
/// Facilita el desacoplamiento entre la UI y Firestore, promoviendo código
/// más mantenible y escalable.

class MenuService {
  // Singleton repository
  final MenuRepository _repository = MenuRepository();

  // ─── Streams ─────────────────────────────
  Stream<List<Menu>> watchMenus() => _repository.watchAll();

  // ─── Métodos CRUD ────────────────────────
  Future<List<Menu>> getAllMenus() async =>
      _handleErrors(() => _repository.getAll());

  Future<Menu?> getMenuById(String id) async =>
      _handleErrors(() => _repository.getById(id));

  Future<void> createMenu(Menu menu) async =>
      _handleErrors(() => _repository.create(menu));

  Future<void> updateMenu(Menu menu) async =>
      _handleErrors(() => _repository.update(menu));

  Future<void> deleteMenu(String id) async =>
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
