import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:app_restaurante/data/model/reservation.dart';
import 'package:app_restaurante/data/services/firestore/reservation_service.dart';

/// ViewModel de reservas con gestión de flujo estable.
class ReservationViewModel extends ChangeNotifier {
  final ReservationService _service;
  ReservationViewModel(this._service);

  List<Reservation> _reservations = [];
  List<Reservation> get reservations => _reservations;

  int get pendingCount =>
      _reservations.where((r) => r.state == ReservationStatus.pending).length;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  StreamSubscription<List<Reservation>>? _sub;

  /// Almacena el alcance actual (scope) para evitar re-escuchas innecesarias.
  String? _currentScope;

  /// Indica si hay una escucha activa de datos.
  bool get isWatching => _currentScope != null;

  // ─── Listeners ──────────────────────────────────────────────────────────

  void watchAll() {
    if (_currentScope == 'all') return;
    _currentScope = 'all';
    // Solo activamos loading en el cambio de scope (carga inicial del modo admin)
    _listen(_service.watchAll(), showLoading: true);
  }

  void watchByUser(String userId) {
    if (_currentScope == userId) return;
    _currentScope = userId;
    // Solo activamos loading en el cambio de scope (carga inicial del modo cliente)
    _listen(_service.watchByUser(userId), showLoading: true);
  }

  void _listen(Stream<List<Reservation>> stream, {bool showLoading = false}) {
    if (showLoading) _setLoading(true);
    _errorMessage = '';
    _sub?.cancel();
    _sub = stream.listen(
      (list) {
        _reservations = list;
        _setLoading(false);
      },
      onError: (e) {
        _errorMessage = 'Error al cargar reservas: $e';
        _setLoading(false);
        _currentScope = null;
      },
    );
  }

  // ─── Acciones ────────────────────────────────────────────────────────────

  Future<void> confirmReservation(String id) =>
      _run(() => _service.updateStatuses([id], ReservationStatus.confirmed));

  Future<void> cancelReservation(String id) =>
      _run(() => _service.updateStatuses([id], ReservationStatus.cancelled));

  Future<void> completeReservation(String id) =>
      _run(() => _service.updateStatuses([id], ReservationStatus.completed));

  Future<void> completeMultipleReservations(List<String> ids) =>
      _run(() => _service.updateStatuses(ids, ReservationStatus.completed));

  Future<void> addReservation(Reservation r) =>
      _run(() => _service.createReservation(r));

  Future<void> updateReservation(Reservation r) =>
      _run(() => _service.updateReservation(r));

  Future<void> deleteReservation(String id) =>
      _run(() => _service.deleteReservation(id));

  // ─── Helpers ────────────────────────────────────────────────────────────

  Future<void> _run(Future<void> Function() action) async {
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
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
