import 'package:cloud_firestore/cloud_firestore.dart';

class Dish {
  //ATTRIBUTES
  String? id;
  String? name;
  String? description;
  String? category;
  String? urlImage;
  double? price;
  bool? available;

  //CONSTRUCTOR
  Dish({
    this.id,
    this.name,
    this.description,
    this.category,
    this.urlImage,
    this.price,
    this.available,
  });

  //FROMFIRESTORE
  factory Dish.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final map = snapshot.data();
    return Dish(
      id: snapshot.id,
      name: map?['name'] as String?,
      description: map?['description'] as String?,
      category: map?['category'] as String?,
      urlImage: map?['urlImage'] as String?,
      price: (map?['price'] as num?)?.toDouble(),
      available: map?['available'] as bool?,
    );
  }

  //TOFIRESTORE
  Map<String, dynamic> toFirestore() {
    return {
      if (name != null) "name": name,
      if (description != null) "description": description,
      if (category != null) "category": category,
      if (urlImage != null) "urlImage": urlImage,
      if (price != null) "price": price,
      if (available != null) "available": available,
    };
  }
}
