import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:app_restaurante/data/model/restaurant.dart';
import 'package:app_restaurante/data/services/firestore/restaurant_service.dart';

class RestaurantViewModel extends ChangeNotifier {
  final RestaurantService _service;

  RestaurantViewModel(this._service);

  Restaurant? _restaurant;
  Restaurant? get restaurant => _restaurant;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  StreamSubscription<List<Restaurant>>? _sub;
  bool _isWatching = false;
  bool get isWatching => _isWatching;

  // ─── Escuchar restaurante (único) ──────────────────────
  void watchRestaurant() {
    if (_isWatching) return;
    _isWatching = true;
    _setLoading(true);
    _errorMessage = '';

    _sub?.cancel();
    _sub = _service.watchRestaurants().listen(
      (restaurants) {
        // 👇 Como solo hay 1, cogemos el primero
        _restaurant = restaurants.isNotEmpty ? restaurants.first : null;
        _setLoading(false);
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = 'Error al cargar el restaurante: $e';
        _setLoading(false);
      },
    );
  }

  // ─── CRUD ──────────────────────────────
  Future<void> createRestaurant(Restaurant r) async =>
      _execute(() => _service.createRestaurant(r));

  Future<void> updateRestaurant(Restaurant r) async =>
      _execute(() => _service.updateRestaurant(r));

  Future<void> deleteRestaurant(String id) async =>
      _execute(() => _service.deleteRestaurant(id));

  // ─── Obtener una vez ────────────────────
  Future<Restaurant?> fetchRestaurant() async {
    try {
      _setLoading(true);
      final list = await _service.getAllRestaurants();
      _restaurant = list.isNotEmpty ? list.first : null;
      return _restaurant;
    } catch (e) {
      _errorMessage = 'Error al obtener el restaurante: $e';
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Helpers internos ─────────────────
  Future<void> _execute(Future<void> Function() action) async {
    _setLoading(true);
    _errorMessage = '';
    try {
      await action();
    } catch (e) {
      _errorMessage = 'Error: $e';
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
    _sub?.cancel();
    super.dispose();
  }
}
