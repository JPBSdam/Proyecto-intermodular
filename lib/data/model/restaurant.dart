import 'package:cloud_firestore/cloud_firestore.dart';

class Restaurant {
  //ATTRIBUTES
  String? id;
  String? adminId; //aqui va el id del user propietario
  String? name;
  String? address;
  String? phoneNumber;
  String? description;
  String? email;
  int? capacity;
  String? urlImage;
  bool? open;
  Map<String, String>? schedule;

  //CONSTRUCTOR
  Restaurant({
    this.id,
    this.adminId,
    this.name,
    this.address,
    this.phoneNumber,
    this.description,
    this.email,
    this.capacity,
    this.urlImage,
    this.open,
    this.schedule,
  });

  //FROMFIRESTORE
  factory Restaurant.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final map = snapshot.data();
    final rawSchedule = map?['schedule'] as Map<String, dynamic>?;

    return Restaurant(
      id: snapshot.id,
      adminId: map?['adminId'] as String?,
      name: map?['name'] as String?,
      address: map?['address'] as String?,
      phoneNumber: map?['phoneNumber'] as String?,
      description: map?['description'] as String?,
      email: map?['email'] as String?,
      capacity: map?['capacity'] as int?,
      urlImage: map?['urlImage'] as String?,
      open: map?['open'] as bool?,
      schedule: rawSchedule?.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    );
  }

  //TOFIRESTORE
  Map<String, dynamic> toFirestore() {
    return {
      if (adminId != null) "adminId": adminId,
      if (name != null) "name": name,
      if (address != null) "address": address,
      if (phoneNumber != null) "phoneNumber": phoneNumber,
      if (description != null) "description": description,
      if (email != null) "email": email,
      if (capacity != null) "capacity": capacity,
      if (urlImage != null) "urlImage": urlImage,
      if (open != null) "open": open,
      if (schedule != null) "schedule": schedule,
    };
  }
}
