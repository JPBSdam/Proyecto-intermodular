import 'package:app_restaurante/data/model/dish.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DishRepository {
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('dishes');

  // CREATE
  Future<void> create(Dish dish) async {
      final doc = await _collection.add(dish.toFirestore());
      dish.id = doc.id;
  }

  // READ (all)
  Stream<List<Dish>> watchAll() {
    return _collection.snapshots().map((snapshot) =>
      snapshot.docs.map((doc) => Dish.fromFirestore(doc, null)).toList());
  }

  // READ (one)
  Future<Dish?> getById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return Dish.fromFirestore(doc, null);
  }

  // UPDATE
  Future<void> update(Dish dish) async {
    await _collection.doc(dish.id).update(dish.toFirestore());
  }

  // DELETE
  Future<void> delete(String id) async {
    await _collection.doc(id).delete();
  }

  // DELETE LIST
  Future<void> deleteBatch(List<String> ids) async {
  final batch = _collection.firestore.batch();
  for (var id in ids) {
    batch.delete(_collection.doc(id));
  }
  await batch.commit();
  }
}