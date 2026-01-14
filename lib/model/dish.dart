import 'package:json_annotation/json_annotation.dart';
part 'dish.g.dart';

@JsonSerializable(
  fieldRename: FieldRename.snake,
  disallowUnrecognizedKeys: false,
)
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

  //JSONSERIALIZABLE
  factory Dish.fromJson(Map<String, dynamic> json) => _$DishFromJson(json);
  Map<String, dynamic> toJson() => _$DishToJson(this);

  //TOSTRING
  @override
  String toString() {
    return 'Dish{id: $id, name: $name, description: $description, category: $category, urlImage: $urlImage, price: $price, available: $available}';
  }
}
