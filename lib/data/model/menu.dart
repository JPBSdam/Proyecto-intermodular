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

  //TOSTRING
  @override
  String toString() {
    return 'Menu{id: $id, name: $name, description: $description, dishes: $dishes, price: $price, available: $available}';
  }
}
