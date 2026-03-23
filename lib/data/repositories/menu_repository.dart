import 'package:app_restaurante/data/model/menu.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MenuRepository {
  // ─── Singleton ─── USO: final MenuRepository _repository = MenuRepository();
  static final MenuRepository _instance = MenuRepository._internal();

  factory MenuRepository() => _instance;

  MenuRepository._internal();

  // ─── Firestore ─────────────────────────────────────────────────────────────
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('menus');

  // ─── CREATE ────────────────────────────────────────────────────────────────
  Future<void> create(Menu menu) async {
    final doc = await _collection.add(menu.toFirestore());
    menu.id = doc.id;
  }

  // ─── READ (all) ────────────────────────────────────────────────────────────
  Stream<List<Menu>> watchAll() {
    return _collection.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => Menu.fromFirestore(doc, null)).toList(),
    );
  }

  Future<List<Menu>> getAll() async {
    final snapshot = await _collection.get();
    return snapshot.docs.map((doc) => Menu.fromFirestore(doc, null)).toList();
  }

  // ─── READ (one) ────────────────────────────────────────────────────────────
  Future<Menu?> getById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return Menu.fromFirestore(doc, null);
  }

  // ─── UPDATE ────────────────────────────────────────────────────────────────
  Future<void> update(Menu menu) async {
    await _collection.doc(menu.id).update(menu.toFirestore());
  }

  // ─── DELETE ────────────────────────────────────────────────────────────────
  Future<void> delete(String id) async {
    await _collection.doc(id).delete();
  }
}
