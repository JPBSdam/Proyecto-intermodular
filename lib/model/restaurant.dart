import 'package:json_annotation/json_annotation.dart';
part 'restaurant.g.dart';

@JsonSerializable()
class Restaurant {
  //ATTRIBUTES
  int? id;
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
  Restaurant(this.id, this.name, this.address, this.phoneNumber,
      this.description, this.email, this.capacity, this.urlImage, this.open,
      this.schedule);

  //JSONSERIALIZABLE
  factory Restaurant.fromJson(Map<String, dynamic> json) => _$RestaurantFromJson(json);
  Map<String, dynamic> toJson() => _$RestaurantToJson(this);

  //TOSTRING
  @override
  String toString() {
    return 'Restaurant{id: $id, name: $name, address: $address, phoneNumber: $phoneNumber, description: $description, email: $email, capacity: $capacity, urlImage: $urlImage, open: $open, schedule: $schedule}';
  }
}