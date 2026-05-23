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
  bool? isActive;
  bool? notificationsEnabled;
  DateTime? deletedAt;

  //CONSTRUCTOR
  User({
    this.id,
    this.name,
    this.email,
    this.phoneNumber,
    this.role,
    this.urlImage,
    this.googlePhotoUrl,
    this.isActive,
    this.notificationsEnabled,
    this.deletedAt,
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
      isActive: map?['isActive'] as bool?,
      notificationsEnabled: map?['notificationsEnabled'] as bool? ?? true,
      deletedAt: (map?['deletedAt'] as Timestamp?)?.toDate(),
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
      if (isActive != null) "isActive": isActive,
      if (notificationsEnabled != null)
        "notificationsEnabled": notificationsEnabled,
      if (deletedAt != null) "deletedAt": deletedAt,
    };
  }
}
