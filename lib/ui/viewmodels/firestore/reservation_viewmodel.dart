import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:app_restaurante/data/model/reservation.dart';
import 'package:app_restaurante/data/services/firestore/reservation_service.dart';
import 'package:app_restaurante/data/services/notifications/notification_service.dart';
import 'package:app_restaurante/data/services/notifications/fcm_service.dart';
import 'package:app_restaurante/data/services/notifications/email_service.dart';

/// ViewModel de reservas con gestión de flujo estable.
class ReservationViewModel extends ChangeNotifier {
  final ReservationService _service;
  ReservationViewModel(this._service);

  List<Reservation> _reservations = [];
  List<Reservation> get reservations => _reservations;

  int get pendingCount =>
      _reservations.where((r) => r.state == ReservationStatus.pending).length;

  /// Retorna todas las reservas PENDING ordenadas de más reciente a más antigua.
  /// Se usa en AdminNotificationsView para no recalcular en el build().
  /// Patrón arquitectura: ViewModels calculan lógica, vistas solo pintan.
  List<Reservation> get pendingReservations {
    final pending = _reservations
        .where((r) => r.state == ReservationStatus.pending)
        .toList();
    // Ordenamos por createdAt descendente (más recientes primero)
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

  /// Almacena el alcance actual (scope) para evitar re-escuchas innecesarias.
  String? _currentScope;

  /// Indica si hay una escucha activa de datos.
  bool get isWatching => _currentScope != null;

  // Mapa que guarda el último estado conocido de cada reserva por su ID.
  // Clave: ID de la reserva en Firestore | Valor: estado anterior (pending, confirmed…)
  // Lo usamos para detectar CAMBIOS de estado entre emisiones del stream.
  final Map<String, String> _previousStates = {};

  // Flag que indica si es la primera carga del stream (evita falsas alertas al inicio)
  bool _isFirstLoad = true;

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
    // Reiniciamos el flag de primera carga cada vez que cambia el scope
    _isFirstLoad = true;
    _sub?.cancel();
    _sub = stream.listen(
      (list) {
        if (!_isFirstLoad) {
          // Detectamos cambios de estado (confirmada/cancelada) para notificar al cliente
          _checkReservationStateChanges(list);
          // Detectamos reservas nuevas (para notificar al admin con badge y push)
          _checkForNewReservations(list);
        } else {
          // Primera carga: solo registramos los IDs existentes como base de referencia
          for (final r in list) {
            if (r.id != null) _knownReservationIds.add(r.id!);
          }
        }
        // Actualizamos el mapa de estados conocidos con los datos recién llegados
        _updatePreviousStates(list);
        // Marcamos que ya pasó la carga inicial
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

  /// Detecta reservas nuevas (IDs no conocidos) con estado pending y actualiza el badge.
  /// Solo relevante para el admin que tiene watchAll() activo.
  void _checkForNewReservations(List<Reservation> updatedList) {
    for (final reservation in updatedList) {
      final id = reservation.id;
      if (id == null) continue;

      // Si el ID no estaba en nuestro conjunto → es una reserva nueva
      if (!_knownReservationIds.contains(id)) {
        // Añadimos a conocidos para no procesarla de nuevo
        _knownReservationIds.add(id);

        // Solo contamos las nuevas pendientes (estado pending = acción requerida del admin)
        if (reservation.state == ReservationStatus.pending) {
          _newReservationIds.add(id);
        }
      }
    }
  }

  /// Marca todas las reservas nuevas como vistas.
  /// Se llama cuando el admin abre la vista de notificaciones/avisos.
  void markAllAsSeen() {
    // Vaciamos el conjunto de nuevas → badge vuelve a 0
    _newReservationIds.clear();
    notifyListeners();
  }

  /// Compara el estado actual de cada reserva con el que tenía antes.
  /// Si detecta un cambio relevante, lanza la notificación correspondiente.
  void _checkReservationStateChanges(List<Reservation> updatedList) {
    for (final reservation in updatedList) {
      final id = reservation.id;
      if (id == null) continue;

      // Estado anterior (null si es una reserva que no conocíamos todavía)
      final previousState = _previousStates[id];
      final currentState = reservation.state;

      // ── Caso 1: RESERVA CONFIRMADA ────────────────────────────────────
      // Condición: conocemos el estado anterior Y ha cambiado a "confirmed"
      if (previousState != null &&
          previousState != ReservationStatus.confirmed &&
          currentState == ReservationStatus.confirmed) {
        // Mostramos notificación inmediata de confirmación
        NotificationService.showReservationConfirmed(reservation);
        // Programamos el recordatorio para las 9:00 AM del día de la reserva
        NotificationService.scheduleReservationReminder(reservation);
      }

      // ── Caso 2: RESERVA CANCELADA ──────────────────────────────────────
      // Si se cancela, eliminamos el recordatorio que hubiera programado
      if (previousState != null &&
          previousState != ReservationStatus.cancelled &&
          currentState == ReservationStatus.cancelled) {
        // Cancelamos el recordatorio programado para no molestar al usuario
        NotificationService.cancelReservationReminder(id);
      }
    }
  }

  /// Actualiza el mapa interno de estados con la lista más reciente.
  void _updatePreviousStates(List<Reservation> list) {
    for (final reservation in list) {
      if (reservation.id != null && reservation.state != null) {
        // Guardamos el estado actual para poder compararlo en la próxima emisión
        _previousStates[reservation.id!] = reservation.state!;
      }
    }
  }

  // ─── Acciones ────────────────────────────────────────────────────────────

  /// Confirma una reserva y envía notificaciones al cliente.
  ///
  /// Flujo:
  /// 1. Actualiza estado en Firestore a 'confirmed'
  /// 2. Encola notificación push al cliente (vía Firestore)
  /// 3. Envía email de confirmación al cliente (vía EmailJS)
  /// 4. Programa recordatorio local para las 9:00 AM del día de la reserva
  Future<void> confirmReservation(String id) async {
    // 1. Actualizamos el estado en Firestore
    await _run(
      () => _service.updateStatuses([id], ReservationStatus.confirmed),
    );

    // 2. Buscamos la reserva en la lista local para obtener los datos del cliente
    final reservation = _reservations.firstWhere(
      (r) => r.id == id,
      orElse: () => Reservation(),
    );

    // 3. Si tenemos el userId del cliente, enviamos notificaciones
    if (reservation.userId != null) {
      final dateStr = reservation.reservationDate != null
          ? DateFormat(
              'dd/MM/yyyy \'a las\' HH:mm',
            ).format(reservation.reservationDate!)
          : 'la fecha acordada';

      // Push al cliente (vía cola Firestore)
      await FcmService.enqueueForUser(
        toUserId: reservation.userId!,
        title: '✅ Reserva Confirmada',
        body: 'Tu reserva para el $dateStr ha sido confirmada. ¡Te esperamos!',
        type: 'reservation_confirmed',
        reservationId: id,
      );

      // Email al cliente (vía EmailJS)
      try {
        await EmailService.sendReservationConfirmedToClient(reservation);
        debugPrint(
          '[ReservationVM] 📧 Email de confirmación enviado al cliente',
        );
      } catch (e) {
        debugPrint('[ReservationVM] ⚠️ Email falló (no crítico): $e');
      }

      // Programa el recordatorio local para las 9:00 AM del día de la reserva
      NotificationService.scheduleReservationReminder(reservation);
    }
  }

  Future<void> cancelReservation(String id) =>
      _run(() => _service.updateStatuses([id], ReservationStatus.cancelled));

  Future<void> completeReservation(String id) =>
      _run(() => _service.updateStatuses([id], ReservationStatus.completed));

  Future<void> completeMultipleReservations(List<String> ids) =>
      _run(() => _service.updateStatuses(ids, ReservationStatus.completed));

  /// Crea una nueva reserva en Firestore y notifica a los admins.
  ///
  /// Flujo completo (sincrónico, con LoadingOverlay activo):
  /// 1. Guarda la reserva en Firestore
  /// 2. Encola notificación push a todos los admins (vía Firestore queue)
  /// 3. Envía email a todos los admins (vía EmailJS)
  ///
  /// Mientras se ejecuta: `isLoading = true` → LoadingOverlay bloquea clicks múltiples
  /// Después: `isLoading = false` → usuario ve snackbar (éxito/error) y puede navegar
  ///
  /// Si alguna sección falla (FCM o email), continúa sin interrumpir.
  Future<void> addReservation(Reservation r) async {
    await _run(() async {
      // Paso 1: Crear reserva en Firestore
      await _service.createReservation(r);

      final dateStr = r.reservationDate != null
          ? DateFormat("dd/MM/yyyy 'a las' HH:mm").format(r.reservationDate!)
          : 'fecha por confirmar';
      final clientName = r.userName ?? r.userEmail ?? 'Un cliente';

      // Paso 2: Push a admins (cola Firestore) — independiente del email
      try {
        await FcmService.enqueueForAllAdmins(
          title: '🔔 Nueva Reserva Recibida',
          body:
              '$clientName solicita mesa para ${r.seats ?? '?'} personas el $dateStr',
          type: 'new_reservation',
        );
        debugPrint('[ReservationVM] ✅ Push FCM encolado');
      } catch (e) {
        // Si falla el push, seguimos igualmente con el email
        debugPrint('[ReservationVM] ⚠️ FCM falló (no crítico): $e');
      }

      // Paso 3: Email a admins via EmailJS — independiente del push
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
