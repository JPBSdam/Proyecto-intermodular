import 'package:app_restaurante/data/services/auth/auth_service.dart';
import 'package:flutter/material.dart';

/// ViewModel que gestiona el estado y la lógica de negocio de la pantalla de Login.
///
/// - Se encarga de la autenticación mediante email/password, Google o modo anónimo.
/// - Mantiene el estado de carga (`isLoading`) y posibles errores (`errorMessage`) para la UI.
/// - Interactúa con `AuthService` y notifica cambios a la interfaz mediante `ChangeNotifier`.
/// - Centraliza la lógica de validación y manejo de errores de la UI.

class LoginViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

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
      await _authService.signInWithEmail(
        email: email.trim(),
        password: password,
      );
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
      _setLoading(false);
      return result != null;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
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

  // ==================== HELPERS INTERNOS ====================
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
