import 'package:app_restaurante/data/services/auth/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// ViewModel de la pantalla Home
/// Gestiona el estado y la lógica de la UI relacionada con el usuario:
///  - Proporciona información del usuario actual (nombre, anonimato)
///  - Controla la operación de cierre de sesión
///  - Mantiene estado de carga y mensajes de error
///  - Integra AuthService para operaciones de autenticación

class HomeViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  // Estado de carga de menús
  bool _isLoading = false;
  String _errorMessage = '';

  // Getters - Menús
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  // Getters - Información del usuario
  User? get currentUser => _authService.currentUser;
  bool get isAnonymous => _authService.isAnonymous();
  String get displayName =>
      currentUser?.email ?? currentUser?.displayName ?? 'Invitado';

  // ==================== CERRAR SESIÓN ====================
  Future<bool> signOut() async {
    _setLoading(true);

    try {
      await _authService.signOut();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Error al cerrar sesión: $e');
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
}
