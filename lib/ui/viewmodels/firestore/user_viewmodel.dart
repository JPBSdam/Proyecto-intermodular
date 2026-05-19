import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:app_restaurante/data/model/user.dart';
import 'package:app_restaurante/data/services/firestore/user_service.dart';
import 'package:app_restaurante/data/services/storage/storage_service.dart';

class UserViewModel extends ChangeNotifier {
  final UserService _service = UserService();
  final StorageService _storageService = StorageService();

  User? _user;
  User? get user => _user;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _error = '';
  String get error => _error;

  StreamSubscription<User?>? _userSub;

  // ─── Escuchar cambios en tiempo real ───
  void watchUser(String uid) {
    _setLoading(true);
    _userSub?.cancel();
    _userSub = _service
        .watchUser(uid)
        .listen(
          (userData) {
            _user = userData;
            _setLoading(false);
          },
          onError: (e) {
            _error = 'Error al cargar el usuario: $e';
            _setLoading(false);
          },
        );
  }

  // ─── CRUD ──────────────────────────────
  Future<User?> fetchUserById(String id) async {
    try {
      _setLoading(true);
      return await _service.getUserById(id);
    } catch (e) {
      _error = 'Error al obtener usuario: $e';
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateUser(User user) async {
    _setLoading(true);
    _error = '';
    try {
      await _service.updateUser(user);
    } catch (e) {
      _error = 'Error al actualizar: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Guarda un usuario existente y opcionalmente sube/elimina su avatar.
  ///
  /// Nota: La creación de usuarios se gestiona en otro lugar (vinculada
  /// al flujo de Auth). Aquí solo gestionamos la subida del avatar y la
  /// actualización del documento del usuario.
  Future<void> saveUser(User user, File? imageFile) async {
    _setLoading(true);
    _error = '';
    try {
      // Subir avatar si se ha seleccionado uno. Usamos un path fijo para
      // el avatar que sobrescribe la imagen anterior, evitando el borrado.
      if (imageFile != null) {
        user.urlImage = await _storageService.uploadUserAvatar(
          imageFile,
          user.id!,
        );
      }

      // Actualizamos siempre el documento del usuario.
      await _service.updateUser(user);
    } catch (e) {
      _error = 'Error al guardar usuario: $e';
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _userSub?.cancel();
    super.dispose();
  }
}
