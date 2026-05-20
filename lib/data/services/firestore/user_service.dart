import 'package:app_restaurante/data/repositories/user_repository.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:app_restaurante/data/model/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  // Singleton repository
  final UserRepository _repository = UserRepository();

  // ─── Streams ─────────────────────────────
  Stream<User?> watchUser(String uid) {
    return _repository.watchById(uid);
  }

  // ─── Métodos CRUD ────────────────────────
  Future<User?> getUserById(String id) async =>
      _handleErrors(() => _repository.getById(id));

  Future<void> updateUser(User user) async =>
      _handleErrors(() => _repository.update(user));

  // ─── Crear usuario si no existe ───────────────────
  Future<void> ensureUserExistsFromAuth(firebase.User firebaseUser) {
    return _handleErrors(() async {
      final existingUser = await _repository.getById(firebaseUser.uid);

      if (existingUser == null) {
        final newUser = User(
          id: firebaseUser.uid,
          email: firebaseUser.email,
          name: firebaseUser.displayName,
          googlePhotoUrl: firebaseUser.photoURL,
        );

        await _repository.create(newUser);
      } else if (firebaseUser.photoURL != null &&
          existingUser.googlePhotoUrl != firebaseUser.photoURL) {
        existingUser.googlePhotoUrl = firebaseUser.photoURL;
        await _repository.update(existingUser);
      }
    });
  }

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
