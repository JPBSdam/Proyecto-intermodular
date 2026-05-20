import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  //ATTRIBUTES
  String? id;
  String? name;
  String? email;
  String? phoneNumber;
  String? role;
  String? urlImage;
  String? googlePhotoUrl;
  //DateTime? createdAt; no se si sera necesario teniendo en cuenta los requisitos

  //CONSTRUCTOR
  User({
    this.id,
    this.name,
    this.email,
    this.phoneNumber,
    this.role,
    this.urlImage,
    this.googlePhotoUrl,
  });

  //FROMFIRESTORE
  factory User.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final map = snapshot.data();
    return User(
      id: snapshot.id,
      name: map?['name'] as String?,
      email: map?['email'] as String?,
      phoneNumber: map?['phoneNumber'] as String?,
      role: map?['role'] as String?,
      urlImage: map?['urlImage'] as String?,
      googlePhotoUrl: map?['googlePhotoUrl'] as String?,
    );
  }

  //TOFIRESTORE

  Map<String, dynamic> toFirestore() {
    return {
      if (name != null) "name": name,
      if (email != null) "email": email,
      if (phoneNumber != null) "phoneNumber": phoneNumber,
      if (role != null) "role": role,
      if (urlImage != null) "urlImage": urlImage,
      if (googlePhotoUrl != null) "googlePhotoUrl": googlePhotoUrl,
    };
  }
}
