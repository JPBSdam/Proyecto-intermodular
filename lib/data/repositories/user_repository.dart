import 'package:app_restaurante/data/model/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserRepository {
  // ─── Singleton ─── USO: final UserRepository _repository = UserRepository();
  static final UserRepository _instance = UserRepository._internal();

  factory UserRepository() => _instance;

  UserRepository._internal();

  // ─── Firestore ─────────────────────────────────────────────────────────────
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users');

  // ─── STREAM ────────────────────────────────────────────────────────────────
  Stream<User?> watchById(String id) {
    return _collection.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return User.fromFirestore(doc, null);
    });
  }

  // ─── CREATE ────────────────────────────────────────────────────────────────
  Future<void> create(User user) async {
    await _collection.doc(user.id).set(user.toFirestore());
  }

  // ─── READ (one) ────────────────────────────────────────────────────────────
  Future<User?> getById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return User.fromFirestore(doc, null);
  }

  // ─── UPDATE ────────────────────────────────────────────────────────────────
  Future<void> update(User user) async {
    await _collection.doc(user.id).update(user.toFirestore());
  }
}
