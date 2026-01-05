import 'package:json_annotation/json_annotation.dart';
part 'menu.g.dart';

@JsonSerializable()
class Menu {
  //ATRIBUTES
  int? id;
  String? name;
  String? description;
  List<int>? dishes;
  double? price;
  bool? available;
  //DateTime? createdAt; no creo que sea necesario guardar cuando se crea un menu?

  //CONSTRUCTOR
  Menu({this.id, this.name, this.description, this.dishes, this.price,
    this.available});

  //JSONSERIALIZABLE
  factory Menu.fromJson(Map<String, dynamic> json) => _$MenuFromJson(json);
  Map<String, dynamic> toJson() => _$MenuToJson(this);

  //TOSTRING
  @override
  String toString() {
    return 'Menu{id: $id, name: $name, description: $description, dishes: $dishes, price: $price, available: $available}';
  }
}