import 'package:app_restaurante/data/services/auth/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// ViewModel para la pantalla de Home
/// Gestiona el estado y la lógica de negocio de la UI
/// Integra lógica de autenticación y carga de menús
class HomeViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  // Estado de carga de menús
  bool _isLoading = false;
  List<String> _menus = [];
  String _errorMessage = '';

  // Getters - Menús
  bool get isLoading => _isLoading;
  List<String> get menus => _menus;
  String get errorMessage => _errorMessage;

  // Getters - Información del usuario
  User? get currentUser => _authService.currentUser;
  bool get isAnonymous => _authService.isAnonymous();
  String get displayName =>
      currentUser?.email ?? currentUser?.displayName ?? 'Invitado';

  // ==================== CARGA DE DATOS ====================
  Future<void> loadHomeData() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      // Código provisional de muestra para la interfaz
      // Simulamos una carga de datos (luego conectaremos con Firebase)
      await Future.delayed(const Duration(seconds: 2));

      _menus = ['Menú del Día', 'Menú Vegetariano', 'Menú Especial'];
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error al cargar datos: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

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

  // ==================== RESET ====================
  void resetData() {
    _menus = [];
    _errorMessage = '';
    _isLoading = false;
    notifyListeners();
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
