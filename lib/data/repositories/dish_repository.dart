import 'package:app_restaurante/data/model/dish.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DishRepository {
  // ─── Singleton ─── USO: final DishRepository _repository = DishRepository();
  static final DishRepository _instance = DishRepository._internal();

  factory DishRepository() => _instance;

  DishRepository._internal();

  // ─── Firestore ─────────────────────────────────────────────────────────────
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('dishes');

  // ─── CREATE ────────────────────────────────────────────────────────────────
  Future<void> create(Dish dish) async {
    final doc = await _collection.add(dish.toFirestore());
    dish.id = doc.id;
  }

  // ─── READ (all) ────────────────────────────────────────────────────────────
  Stream<List<Dish>> watchAll() {
    return _collection.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => Dish.fromFirestore(doc, null)).toList(),
    );
  }

  Future<List<Dish>> getAll() async {
    final snapshot = await _collection.get();
    return snapshot.docs.map((doc) => Dish.fromFirestore(doc, null)).toList();
  }

  // ─── READ (one) ────────────────────────────────────────────────────────────
  Future<Dish?> getById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return Dish.fromFirestore(doc, null);
  }

  // ─── UPDATE ────────────────────────────────────────────────────────────────
  Future<void> update(Dish dish) async {
    await _collection.doc(dish.id).update(dish.toFirestore());
  }

  // ─── DELETE ────────────────────────────────────────────────────────────────
  Future<void> delete(String id) async {
    await _collection.doc(id).delete();
  }
}
