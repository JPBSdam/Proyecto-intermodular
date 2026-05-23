import 'package:app_restaurante/data/model/reservation.dart';
import 'package:app_restaurante/data/repositories/reservation_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Servicio de gestión de reservas.
/// Capa entre ViewModel y Repository con manejo centralizado de errores.

class ReservationService {
  final ReservationRepository _repo = ReservationRepository();

  // ─── Streams ─────────────────────────────────────────────────────────────
  Stream<List<Reservation>> watchAll() => _repo.watchAll();
  Stream<List<Reservation>> watchByUser(String userId) =>
      _repo.watchByUser(userId);

  // ─── CRUD ─────────────────────────────────────────────────────────────────
  Future<void> createReservation(Reservation r) =>
      _handle(() => _repo.create(r));
  Future<void> updateReservation(Reservation r) =>
      _handle(() => _repo.update(r));
  Future<void> deleteReservation(String id) => _handle(() => _repo.delete(id));
  Future<void> updateStatuses(List<String> ids, String status) =>
      _handle(() => _repo.updateStatuses(ids, status));
  Future<Reservation?> getById(String id) => _handle(() => _repo.getById(id));
  Future<List<Reservation>> getActiveByUser(String userId) =>
      _handle(() => _repo.getActiveByUser(userId));

  // ─── Manejo de errores ────────────────────────────────────────────────────
  Future<T> _handle<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseException catch (e) {
      throw _map(e);
    } catch (e) {
      throw 'Error inesperado: $e';
    }
  }

  String _map(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'No tienes permisos para realizar esta operación.';
      case 'not-found':
        return 'La reserva no existe.';
      case 'unavailable':
        return 'El servicio no está disponible actualmente.';
      default:
        return 'Error de base de datos: ${e.message}';
    }
  }
}
