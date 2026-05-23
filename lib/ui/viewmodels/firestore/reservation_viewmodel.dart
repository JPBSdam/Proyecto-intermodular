import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:app_restaurante/data/model/reservation.dart';
import 'package:app_restaurante/data/services/firestore/reservation_service.dart';
import 'package:app_restaurante/data/services/notifications/notification_service.dart';
import 'package:app_restaurante/data/services/notifications/fcm_service.dart';
import 'package:app_restaurante/data/services/notifications/email_service.dart';

// ViewModel que gestiona en tiempo real las reservas.

class ReservationViewModel extends ChangeNotifier {
  final ReservationService _service;
  ReservationViewModel(this._service);

  List<Reservation> _reservations = [];
  List<Reservation> get reservations => _reservations;

  int get pendingCount =>
      _reservations.where((r) => r.state == ReservationStatus.pending).length;

  // Devuelve todas las reservas PENDING ordenadas de más reciente a más antigua.
  List<Reservation> get pendingReservations {
    final pending = _reservations
        .where((r) => r.state == ReservationStatus.pending)
        .toList();
    pending.sort((a, b) {
      final aDate = a.createdAt ?? DateTime(2000);
      final bDate = b.createdAt ?? DateTime(2000);
      return bDate.compareTo(aDate);
    });
    return pending;
  }

  // Conjunto de IDs de reservas "nuevas" que el admin aún no ha visto.
  // Se llena cuando llega una reserva nueva con estado pending mientras la app está abierta.
  // Se vacía cuando el admin abre la vista de notificaciones (markAllAsSeen).
  final Set<String> _newReservationIds = {};
  final Set<String> _knownReservationIds = {};

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  StreamSubscription<List<Reservation>>? _sub;

  String? _currentScope;

  bool get isWatching => _currentScope != null;

  final Map<String, String> _previousStates = {};
  bool _isFirstLoad = true;

  // ───────────────────── Listeners ───────────────────────────────────────────

  void watchAll() {
    if (_currentScope == 'all') return;
    _currentScope = 'all';
    _listen(_service.watchAll(), showLoading: true);
  }

  void watchByUser(String userId) {
    if (_currentScope == userId) return;
    _currentScope = userId;
    _listen(_service.watchByUser(userId), showLoading: true);
  }

  void _listen(Stream<List<Reservation>> stream, {bool showLoading = false}) {
    if (showLoading) _setLoading(true);
    _errorMessage = '';
    _isFirstLoad = true;
    _sub?.cancel();
    _sub = stream.listen(
      (list) {
        if (!_isFirstLoad) {
          _checkReservationStateChanges(list);
          _checkForNewReservations(list);
        } else {
          for (final r in list) {
            if (r.id != null) _knownReservationIds.add(r.id!);
          }
        }
        _updatePreviousStates(list);
        _isFirstLoad = false;

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

  // Detecta reservas nuevas con estado PENDING.

  void _checkForNewReservations(List<Reservation> updatedList) {
    for (final reservation in updatedList) {
      final id = reservation.id;
      if (id == null) continue;
      if (!_knownReservationIds.contains(id)) {
        _knownReservationIds.add(id);
        if (reservation.state == ReservationStatus.pending) {
          _newReservationIds.add(id);
        }
      }
    }
  }

  // Marca todas las reservas nuevas como vistas.
  void markAllAsSeen() {
    _newReservationIds.clear();
    notifyListeners();
  }

  // Compara el estado actual de cada reserva con el que tenía antes.

  void _checkReservationStateChanges(List<Reservation> updatedList) {
    for (final reservation in updatedList) {
      final id = reservation.id;
      if (id == null) continue;

      final previousState = _previousStates[id];
      final currentState = reservation.state;

      if (previousState != null &&
          previousState != ReservationStatus.confirmed &&
          currentState == ReservationStatus.confirmed) {
        NotificationService.showReservationConfirmed(reservation);
        NotificationService.scheduleReservationReminder(reservation);
      }

      if (previousState != null &&
          previousState != ReservationStatus.cancelled &&
          currentState == ReservationStatus.cancelled) {
        NotificationService.cancelReservationReminder(id);
      }
    }
  }

  void _updatePreviousStates(List<Reservation> list) {
    for (final reservation in list) {
      if (reservation.id != null && reservation.state != null) {
        _previousStates[reservation.id!] = reservation.state!;
      }
    }
  }

  // ───────────────────── Acciones ────────────────────────────────────────────

  // Confirma una reserva y envía notificaciones al cliente.
  Future<void> confirmReservation(String id) async {
    await _run(
      () => _service.updateStatuses([id], ReservationStatus.confirmed),
    );
    final reservation = _reservations.firstWhere(
      (r) => r.id == id,
      orElse: () => Reservation(),
    );
    if (reservation.userId != null) {
      final dateStr = reservation.reservationDate != null
          ? DateFormat(
              'dd/MM/yyyy \'a las\' HH:mm',
            ).format(reservation.reservationDate!)
          : 'la fecha acordada';
      await FcmService.enqueueForUser(
        toUserId: reservation.userId!,
        title: '✅ Reserva Confirmada',
        body: 'Tu reserva para el $dateStr ha sido confirmada. ¡Te esperamos!',
        type: 'reservation_confirmed',
        reservationId: id,
      );
      try {
        await EmailService.sendReservationConfirmedToClient(reservation);
        debugPrint(
          '[ReservationVM] 📧 Email de confirmación enviado al cliente',
        );
      } catch (e) {
        debugPrint('[ReservationVM] ⚠️ Email falló (no crítico): $e');
      }
      NotificationService.scheduleReservationReminder(reservation);
    }
  }

  Future<void> cancelReservation(String id) =>
      _run(() => _service.updateStatuses([id], ReservationStatus.cancelled));

  Future<void> completeReservation(String id) =>
      _run(() => _service.updateStatuses([id], ReservationStatus.completed));

  Future<void> completeMultipleReservations(List<String> ids) =>
      _run(() => _service.updateStatuses(ids, ReservationStatus.completed));

  // Crea una nueva reserva en Firestore y notifica a los admins.
  Future<void> addReservation(Reservation r) async {
    await _run(() async {
      await _service.createReservation(r);

      final dateStr = r.reservationDate != null
          ? DateFormat("dd/MM/yyyy 'a las' HH:mm").format(r.reservationDate!)
          : 'fecha por confirmar';
      final clientName = r.userName ?? r.userEmail ?? 'Un cliente';
      try {
        await FcmService.enqueueForAllAdmins(
          title: '🔔 Nueva Reserva Recibida',
          body:
              '$clientName solicita mesa para ${r.seats ?? '?'} personas el $dateStr',
          type: 'new_reservation',
        );
        debugPrint('[ReservationVM] ✅ Push FCM encolado');
      } catch (e) {
        debugPrint('[ReservationVM] ⚠️ FCM falló (no crítico): $e');
      }
      try {
        debugPrint('[ReservationVM] 📧 Llamando a EmailService...');
        await EmailService.sendNewReservationToAdmins(r);
        debugPrint('[ReservationVM] ✅ EmailService completado');
      } catch (e) {
        debugPrint('[ReservationVM] ⚠️ EmailService falló: $e');
      }
    });
  }

  Future<void> updateReservation(Reservation r) =>
      _run(() => _service.updateReservation(r));

  Future<void> deleteReservation(String id) =>
      _run(() => _service.deleteReservation(id));

  // ───────────────────── Helpers ─────────────────────────────────────────────

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
