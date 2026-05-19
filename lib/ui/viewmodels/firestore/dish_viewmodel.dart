import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:app_restaurante/data/model/dish.dart';
import 'package:app_restaurante/data/services/firestore/dish_service.dart';
import 'package:app_restaurante/data/services/notifications/notification_service.dart';
import 'package:app_restaurante/data/services/storage/storage_service.dart';

/// ViewModel que gestiona la lógica de negocio y estado de los platos (Dish)
/// Se encarga de:
///  - Escuchar cambios en tiempo real de los platos desde Firestore
///  - Realizar operaciones CRUD (crear, actualizar, eliminar)
///  - Mantener estado de carga y mensajes de error
///  - Notificar a los clientes cuando se añade un plato nuevo a la carta
///  - Exponer datos y estado a la UI mediante getters y ChangeNotifier

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

  // Conjunto de IDs de platos que ya conocemos (cargados en la sesión actual).
  // Usamos un Set para búsquedas O(1) y evitar duplicados.
  final Set<String> _knownDishIds = {};

  // Flag para ignorar la primera emisión del stream (evita notificar todos los
  // platos existentes como "nuevos" al abrir la app por primera vez)
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
        // Solo buscamos platos nuevos después de la primera carga
        // En la primera carga simplemente registramos los platos ya existentes
        if (!_isDishFirstLoad) {
          _checkForNewDishes(dishes);
        }

        // Actualizamos el conjunto de IDs conocidos con la lista más reciente
        _knownDishIds.clear();
        for (final dish in dishes) {
          if (dish.id != null) _knownDishIds.add(dish.id!);
        }

        // Marcamos que ya superamos la carga inicial
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

  /// Compara la lista nueva con los IDs conocidos y lanza notificación
  /// por cada plato cuyo ID no existía en la carga anterior.
  void _checkForNewDishes(List<Dish> updatedDishes) {
    for (final dish in updatedDishes) {
      // Si el ID del plato no está en el conjunto que conocemos → es nuevo
      if (dish.id != null && !_knownDishIds.contains(dish.id)) {
        // Disparamos la notificación de "nuevo plato en carta"
        NotificationService.showNewDish(dish);
      }
    }
  }

  // ─── CRUD ──────────────────────────────
  Future<void> addDish(Dish dish) async =>
      _execute(() => _service.createDish(dish));

  Future<void> updateDish(Dish dish) async =>
      _execute(() => _service.updateDish(dish));

  Future<void> saveDish(Dish dish, File? imageFile) async {
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
