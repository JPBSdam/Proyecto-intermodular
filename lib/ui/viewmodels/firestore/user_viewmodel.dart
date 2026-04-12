import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:app_restaurante/data/model/user.dart';
import 'package:app_restaurante/data/services/firestore/user_service.dart';

class UserViewModel extends ChangeNotifier {
  final UserService _service = UserService();

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
