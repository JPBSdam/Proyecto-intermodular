import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:app_restaurante/data/model/dish.dart';
import 'package:app_restaurante/data/services/firestore/dish_service.dart';
import 'package:app_restaurante/data/services/notifications/notification_service.dart';
import 'package:app_restaurante/data/services/storage/storage_service.dart';

class DishViewModel extends ChangeNotifier {
  final DishService _service;
  final StorageService? _storageService;

  DishViewModel(this._service, [this._storageService]);

  List<Dish> _dishes = [];
  List<Dish> get dishes => _dishes;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  StreamSubscription<List<Dish>>? _dishesSub;
  bool _isWatching = false;
  bool get isWatchingDishes => _isWatching;
  final Set<String> _knownDishIds = {};
  bool _isDishFirstLoad = true;

  // ─── Escuchar todos los platos ─────────────────────────
  void watchDishes() {
    if (_isWatching) return;
    _isWatching = true;
    _setLoading(true);
    _errorMessage = '';

    _dishesSub?.cancel();
    _dishesSub = _service.watchDishes().listen(
      (dishes) {
        if (!_isDishFirstLoad) {
          _checkForNewDishes(dishes);
        }
        _knownDishIds.clear();
        for (final dish in dishes) {
          if (dish.id != null) _knownDishIds.add(dish.id!);
        }
        _isDishFirstLoad = false;

        _dishes = dishes;
        _setLoading(false);
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = 'Error al cargar los platos: $e';
        _setLoading(false);
      },
    );
  }

  void _checkForNewDishes(List<Dish> updatedDishes) {
    for (final dish in updatedDishes) {
      if (dish.id != null && !_knownDishIds.contains(dish.id)) {
        NotificationService.showNewDish(dish);
      }
    }
  }

  // ───────────────────── CRUD ──────────────────────────────
  Future<void> saveDish(Dish dish, XFile? imageFile) async {
    await _execute(() async {
      final bool isNew = dish.id == null;

      if (isNew) {
        await _service.createDish(dish);
      }

      if (imageFile != null) {
        final storageService = _storageService ?? StorageService();
        if (dish.urlImage != null && dish.urlImage!.isNotEmpty) {
          await storageService.deleteDishImage(dish.urlImage!);
        }

        try {
          dish.urlImage = await storageService.uploadDishImage(
            imageFile,
            dish.id!,
          );
        } catch (e) {
          if (isNew && dish.id != null) {
            await _service.deleteDish(dish.id!);
          }
          rethrow;
        }
      }

      if (!isNew || imageFile != null) {
        await _service.updateDish(dish);
      }
    });
  }

  Future<void> deleteDish(String id) async =>
      _execute(() => _service.deleteDish(id));

  // ───────────────────── Obtener un plato ─────────────────────────
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

  // ───────────────────── Helpers internos ─────────────────
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
