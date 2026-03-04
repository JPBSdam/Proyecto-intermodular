import 'package:flutter/material.dart';

class HomeViewModel extends ChangeNotifier {
  // Estado
  bool _isLoading = false;
  List<String> _menus = [];
  String _errorMessage = '';

  // Getters
  bool get isLoading => _isLoading;
  List<String> get menus => _menus;
  String get errorMessage => _errorMessage;

  // Métodos
  Future<void> loadHomeData() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners(); // Notifica a la UI que hubo cambios

    try {
      // Código provisional de muestra para la interfaz
      // Simulamos una carga de datos (luego conectaremos con Firebase)
      await Future.delayed(const Duration(seconds: 2));

      _menus = ['Menú 1', 'Menú 2', 'Menú 3'];
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error al cargar datos: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Para reiniciar los datos de la vista
  void resetData() {
    _menus = [];
    _errorMessage = '';
    _isLoading = false;
    notifyListeners();
  }
}
