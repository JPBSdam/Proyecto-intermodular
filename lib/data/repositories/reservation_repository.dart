import 'package:app_restaurante/data/model/reservation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Repositorio de acceso a datos para reservas en Firestore.
/// Colección: 'reservations'
///
/// NOTA ROLES: watchAll() es para admin, watchByUser() para customer.

class ReservationRepository {
  static final ReservationRepository _instance =
      ReservationRepository._internal();
  factory ReservationRepository() => _instance;
  ReservationRepository._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('reservations');

  // ─── CREATE ─────────────────────────────────────────────────────────────────
  Future<void> create(Reservation r) async {
    final doc = await _col.add(r.toFirestore());
    r.id = doc.id;
  }

  // ─── READ todas (admin) ──────────────────────────────────────────────────────
  Stream<List<Reservation>> watchAll() => _col
      .orderBy('reservationDate', descending: true)
      .snapshots()
      .map(
        (s) => s.docs.map((d) => Reservation.fromFirestore(d, null)).toList(),
      );

  // ─── READ por usuario (customer) ─────────────────────────────────────────────
  Stream<List<Reservation>> watchByUser(String userId) => _col
      .where('userId', isEqualTo: userId)
      .snapshots() // Quitamos orderBy temporalmente para evitar error de índice
      .map((s) {
        final list = s.docs
            .map((d) => Reservation.fromFirestore(d, null))
            .toList();
        // Ordenamos en memoria para no depender del índice de Firestore
        list.sort(
          (a, b) => (b.reservationDate ?? DateTime(0)).compareTo(
            a.reservationDate ?? DateTime(0),
          ),
        );
        return list;
      });

  Future<Reservation?> getById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return Reservation.fromFirestore(doc, null);
  }

  // ─── UPDATE ──────────────────────────────────────────────────────────────────
  Future<void> update(Reservation r) async =>
      _col.doc(r.id).update(r.toFirestore());

  Future<void> updateStatuses(List<String> ids, String status) async {
    if (ids.isEmpty) return;

    // Si solo hay uno, hacemos un update simple (más eficiente)
    if (ids.length == 1) {
      await _col.doc(ids.first).update({'state': status});
      return;
    }

    // Si hay varios, usamos Batch para atomicidad
    final batch = _firestore.batch();
    for (final id in ids) {
      batch.update(_col.doc(id), {'state': status});
    }
    await batch.commit();
  }

  // ─── DELETE ──────────────────────────────────────────────────────────────────
  Future<void> delete(String id) async => _col.doc(id).delete();
}
