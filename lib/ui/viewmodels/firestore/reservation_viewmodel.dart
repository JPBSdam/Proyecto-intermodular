import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:app_restaurante/data/model/reservation.dart';
import 'package:app_restaurante/data/services/firestore/reservation_service.dart';

/// ViewModel de reservas.
/// - watchAll()      → admin (todas las reservas)
/// - watchByUser()   → customer (solo las suyas)
/// - confirmReservation / cancelReservation → cambios de estado
///
/// NOTA ROLES: la UI decide qué método de escucha usar según user.role

class ReservationViewModel extends ChangeNotifier {
  final ReservationService _service;
  ReservationViewModel(this._service);

  List<Reservation> _reservations = [];
  List<Reservation> get reservations => _reservations;

  /// Retorna el número de reservas con estado 'pending'.
  int get pendingCount =>
      _reservations.where((r) => r.state == ReservationStatus.pending).length;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  StreamSubscription<List<Reservation>>? _sub;
  bool _isWatching = false;
  bool get isWatching => _isWatching;

  // ─── Escuchar TODAS (admin) ──────────────────────────────────────────────
  void watchAll() {
    if (_isWatching) return;
    _listen(_service.watchAll());
  }

  // ─── Escuchar por usuario (customer) ────────────────────────────────────
  void watchByUser(String userId) {
    if (_isWatching) return;
    _listen(_service.watchByUser(userId));
  }

  void _listen(Stream<List<Reservation>> stream) {
    _isWatching = true;
    _setLoading(true);
    _errorMessage = '';
    _sub?.cancel();
    _sub = stream.listen(
      (list) {
        _reservations = list;
        _setLoading(false);
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = 'Error al cargar reservas: $e';
        _setLoading(false);
      },
    );
  }

  // ─── CRUD ────────────────────────────────────────────────────────────────
  Future<void> addReservation(Reservation r) =>
      _run(() => _service.createReservation(r));
  Future<void> updateReservation(Reservation r) =>
      _run(() => _service.updateReservation(r));
  Future<void> deleteReservation(String id) =>
      _run(() => _service.deleteReservation(id));
  Future<void> confirmReservation(String id) =>
      _run(() => _service.updateStatus(id, ReservationStatus.confirmed));
  Future<void> cancelReservation(String id) =>
      _run(() => _service.updateStatus(id, ReservationStatus.cancelled));

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

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
