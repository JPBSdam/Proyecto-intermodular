import 'dart:async';

import 'package:app_restaurante/data/model/dish.dart';
import 'package:app_restaurante/data/model/menu.dart';
import 'package:app_restaurante/data/services/firestore/dish_service.dart';
import 'package:app_restaurante/data/services/firestore/menu_service.dart';
import 'package:flutter/foundation.dart';

class MenuViewModel extends ChangeNotifier {
  final MenuService _menuService;
  final DishService _dishService;

  MenuViewModel(this._menuService, this._dishService);

  List<Menu> _menus = [];
  List<Menu> get menus => _menus;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  StreamSubscription<List<Menu>>? _menusSub;
  bool _isWatchingMenus = false;
  bool get isWatchingMenus => _isWatchingMenus;

  // ─── Escuchar menús ─────────────────────────────
  void watchMenus() {
    if (_isWatchingMenus) return;
    _isWatchingMenus = true;
    _setLoading(true);
    _errorMessage = '';

    _menusSub?.cancel();
    _menusSub = _menuService.watchMenus().listen(
      (menus) {
        _menus = menus;
        _setLoading(false);
      },
      onError: (e) {
        _errorMessage = 'Error al cargar menús: $e';
        _setLoading(false);
      },
    );
  }

  // ─── Obtener un menú ─────────────────────────────
  Future<Menu?> fetchMenuById(String id) async {
    try {
      _setLoading(true);
      return await _menuService.getMenuById(id);
    } catch (e) {
      _errorMessage = 'Error al cargar el menú: $e';
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Obtener platos de un menú ─────────
  Future<List<Dish>> loadMenuDishes(Menu menu) async {
    try {
      _setLoading(true);
      return await Future.wait(
        menu.dishes?.map((id) => _dishService.getDishById(id)) ?? [],
      ).then((list) => list.whereType<Dish>().toList());
    } catch (e) {
      _errorMessage = 'Error al cargar platos del menú: $e';
      return [];
    } finally {
      _setLoading(false);
    }
  }

  // ─── CRUD ──────────────────────────────
  Future<void> addMenu(Menu menu) async =>
      _execute(() => _menuService.createMenu(menu));

  Future<void> updateMenu(Menu menu) async =>
      _execute(() => _menuService.updateMenu(menu));

  Future<void> deleteMenu(String id) async =>
      _execute(() => _menuService.deleteMenu(id));

  // ─── Helpers ───────────────────────────
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
    _menusSub?.cancel();
    super.dispose();
  }
}
