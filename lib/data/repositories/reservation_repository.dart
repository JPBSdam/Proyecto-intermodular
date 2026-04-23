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
      .orderBy('reservationDate')
      .snapshots()
      .map(
        (s) => s.docs.map((d) => Reservation.fromFirestore(d, null)).toList(),
      );

  // ─── READ por usuario (customer) ─────────────────────────────────────────────
  Stream<List<Reservation>> watchByUser(String userId) => _col
      .where('userId', isEqualTo: userId)
      .orderBy('reservationDate')
      .snapshots()
      .map(
        (s) => s.docs.map((d) => Reservation.fromFirestore(d, null)).toList(),
      );

  Future<Reservation?> getById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return Reservation.fromFirestore(doc, null);
  }

  // ─── UPDATE ──────────────────────────────────────────────────────────────────
  Future<void> update(Reservation r) async =>
      _col.doc(r.id).update(r.toFirestore());

  Future<void> updateStatus(String id, String status) async =>
      _col.doc(id).update({'state': status});

  // ─── DELETE ──────────────────────────────────────────────────────────────────
  Future<void> delete(String id) async => _col.doc(id).delete();
}
