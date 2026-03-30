import 'package:app_restaurante/data/services/auth/auth_service.dart';
import 'package:flutter/material.dart';

/// ViewModel que gestiona el estado y la lógica de negocio de la pantalla de Registro.
///
/// - Se encarga del registro de usuarios mediante email y contraseña.
/// - Mantiene el estado de carga (`isLoading`) y posibles errores (`errorMessage`) para la UI.
/// - Interactúa con `AuthService` y notifica cambios a la interfaz mediante `ChangeNotifier`.
/// - Centraliza la lógica de manejo de errores de la UI durante el registro.

class RegisterViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ==================== REGISTRO CON EMAIL/PASSWORD ====================
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.signUpWithEmail(
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
