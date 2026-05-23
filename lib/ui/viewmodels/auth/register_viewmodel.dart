import 'package:app_restaurante/data/services/auth/auth_service.dart';
import 'package:flutter/material.dart';

class RegisterViewModel extends ChangeNotifier {
  final AuthService _authService;

  RegisterViewModel({AuthService? authService})
    : _authService = authService ?? AuthService();

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
      try {
        await _authService.sendEmailVerification();
      } catch (e) {
        _setError('Error al enviar el correo de verificación: $e');
      }

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
