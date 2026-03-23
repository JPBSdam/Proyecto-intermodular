import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:app_restaurante/data/model/dish.dart';
import 'package:app_restaurante/data/services/firestore/dish_service.dart';

class DishViewModel extends ChangeNotifier {
  final DishService _service;

  DishViewModel(this._service);

  List<Dish> _dishes = [];
  List<Dish> get dishes => _dishes;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  StreamSubscription<List<Dish>>? _dishesSub;
  bool _isWatching = false;
  bool get isWatchingDishes => _isWatching;

  // ─── Escuchar todos los platos ─────────────────────────
  void watchDishes() {
    if (_isWatching) return;
    _isWatching = true;
    _setLoading(true);
    _errorMessage = '';

    _dishesSub?.cancel();
    _dishesSub = _service.watchDishes().listen(
      (dishes) {
        _dishes = dishes;
        _setLoading(false);
      },
      onError: (e) {
        _errorMessage = 'Error al cargar los platos: $e';
        _setLoading(false);
      },
    );
  }

  // ─── CRUD ──────────────────────────────
  Future<void> addDish(Dish dish) async =>
      _execute(() => _service.createDish(dish));

  Future<void> updateDish(Dish dish) async =>
      _execute(() => _service.updateDish(dish));

  Future<void> deleteDish(String id) async =>
      _execute(() => _service.deleteDish(id));

  // ─── Obtener un plato ─────────────────────────
  Future<Dish?> fetchDishById(String id) async {
    try {
      _setLoading(true);
      return await _service.getDishById(id);
    } catch (e) {
      _errorMessage = 'Error al obtener el plato: $e';
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
    _dishesSub?.cancel();
    super.dispose();
  }
}
