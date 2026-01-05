import 'package:json_annotation/json_annotation.dart';
part 'user.g.dart';

@JsonSerializable()
class User {
  //ATTRIBUTES
  int? id;
  String? name;
  String? email;
  String? phoneNumber;
  String? role;
  String? urlImage;
  //DateTime? createdAt;

  //CONSTRUCTOR
  User({this.id, this.name, this.email, this.phoneNumber, this.role,
      this.urlImage});

  //JSONSERIALIZABLE
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  //TOSTRING
  @override
  String toString() {
    return 'User{id: $id, name: $name, email: $email, phoneNumber: $phoneNumber, role: $role, urlImage: $urlImage}';
  }
}