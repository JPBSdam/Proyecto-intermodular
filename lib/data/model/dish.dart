class Dish {
  //ATTRIBUTES
  int? id;
  String? name;
  String? description;
  String? category;
  String? urlImage;
  double? price;
  bool? available;
  //DateTime? createdAt; no creo que sea necesario guardar cuando se crea un plato?

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

  //TOSTRING
  @override
  String toString() {
    return 'Dish{id: $id, name: $name, description: $description, category: $category, urlImage: $urlImage, price: $price, available: $available}';
  }
}
