import 'package:cloud_firestore/cloud_firestore.dart';

class Menu {
  //ATTRIBUTES
  int? id;
  String? name;
  String? description;
  List<int>? dishes;
  double? price;
  bool? available;
  //DateTime? createdAt; no creo que sea necesario guardar cuando se crea un menu?

  //CONSTRUCTOR
  Menu({
    this.id,
    this.name,
    this.description,
    this.dishes,
    this.price,
    this.available,
  });

  //FROMFIRESTORE
  factory Menu.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final map = snapshot.data();
    return Menu(
      id: int.tryParse(snapshot.id), // si quieres id numérico
      name: map?['name'] as String?,
      description: map?['description'] as String?,
      dishes: map?['dishes'] != null
          ? List<int>.from(map?['dishes'] ?? [])
          : null,
      price: (map?['price'] as num?)?.toDouble(),
      available: map?['available'] as bool?,
    );
  }

  //TOFIRESTORE
  Map<String, dynamic> toFirestore() {
    return {
      if (name != null) "name": name,
      if (description != null) "description": description,
      if (dishes != null) "dishes": dishes,
      if (price != null) "price": price,
      if (available != null) "available": available,
    };
  }

  //TOSTRING
  @override
  String toString() {
    return 'Menu{id: $id, name: $name, description: $description, dishes: $dishes, price: $price, available: $available}';
  }
}
