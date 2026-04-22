import 'package:app_restaurante/data/model/restaurant.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RestaurantRepository {
  // ─── Singleton ───
  static final RestaurantRepository _instance =
      RestaurantRepository._internal();

  factory RestaurantRepository() => _instance;

  RestaurantRepository._internal();

  // ─── Firestore ─────────────────────────────────────────
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('restaurants');

  // ─── CREATE ────────────────────────────────────────────
  Future<void> create(Restaurant restaurant) async {
    final doc = await _collection.add(restaurant.toFirestore());
    restaurant.id = doc.id;
  }

  // ─── READ (all) ────────────────────────────────────────
  Stream<List<Restaurant>> watchAll() {
    return _collection.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => Restaurant.fromFirestore(doc, null))
          .toList(),
    );
  }

  Future<List<Restaurant>> getAll() async {
    final snapshot = await _collection.get();
    return snapshot.docs
        .map((doc) => Restaurant.fromFirestore(doc, null))
        .toList();
  }

  // ─── READ (one) ────────────────────────────────────────
  Future<Restaurant?> getById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return Restaurant.fromFirestore(doc, null);
  }

  Stream<Restaurant?> watchById(String id) {
    return _collection
        .doc(id)
        .snapshots()
        .map((doc) => doc.exists ? Restaurant.fromFirestore(doc, null) : null);
  }

  Future<Restaurant?> getByAdminId(String adminId) async {
    final snapshot = await _collection
        .where('adminId', isEqualTo: adminId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return Restaurant.fromFirestore(snapshot.docs.first, null);
  }

  Stream<Restaurant?> watchByAdminId(String adminId) {
    return _collection
        .where('adminId', isEqualTo: adminId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return Restaurant.fromFirestore(snapshot.docs.first, null);
        });
  }

  // ─── UPDATE ────────────────────────────────────────────
  Future<void> update(Restaurant restaurant) async {
    if (restaurant.id == null) {
      throw Exception('ID requerido para actualizar');
    }
    await _collection.doc(restaurant.id).update(restaurant.toFirestore());
  }

  // ─── DELETE ────────────────────────────────────────────
  Future<void> delete(String id) async {
    await _collection.doc(id).delete();
  }
}
