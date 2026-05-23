import 'package:app_restaurante/data/repositories/user_repository.dart';
import 'package:app_restaurante/data/services/auth/auth_service.dart';
import 'package:flutter/material.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthService _authService;
  final UserRepository _userRepository;

  LoginViewModel({AuthService? authService, UserRepository? userRepository})
    : _authService = authService ?? AuthService(),
      _userRepository = userRepository ?? UserRepository();

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ==================== LOGIN CON EMAIL/PASSWORD ====================
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final credential = await _authService.signInWithEmail(
        email: email.trim(),
        password: password,
      );
      await _checkUserActive(credential?.user?.uid);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // ==================== LOGIN CON GOOGLE ====================
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.signInWithGoogle();
      if (result == null) {
        _setLoading(false);
        return false;
      }
      await _checkUserActive(result.user?.uid);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // ==================== COMPROBACIÓN CUENTA ACTIVA ====================

  Future<void> _checkUserActive(String? uid) async {
    if (uid == null) return;
    try {
      final user = await _userRepository.getById(uid);
      if (user != null && user.isActive == false) {
        await _authService.signOut();
        throw 'Esta cuenta no existe o ha sido eliminada. '
            'Regístrate de nuevo para crear una cuenta.';
      }
    } catch (e) {
      if (e is String) rethrow;
      await _authService.signOut();
      rethrow;
    }
  }

  // ==================== LOGIN ANÓNIMO ====================
  Future<bool> signInAnonymously() async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.signInAnonymously();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // ==================== RECUPERACIÓN DE CONTRASEÑA ====================
  Future<bool> resetPassword({required String email}) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.resetPassword(email: email.trim());
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // ==================== VERIFICACIÓN DE CORREO ====================
  Future<bool> resendEmailVerification() async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.sendEmailVerification();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> checkEmailVerification() async {
    try {
      await _authService.reloadUser();
      return _authService.isEmailVerified;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  bool get isEmailVerified => _authService.isEmailVerified;
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
