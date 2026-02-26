class User {
  //ATTRIBUTES
  int? id;
  String? name;
  String? email;
  String? phoneNumber;
  String? role;
  String? urlImage;
  //DateTime? createdAt; no se si sera necesario teniendo en cuenta los requisitos

  //CONSTRUCTOR
  User({
    this.id,
    this.name,
    this.email,
    this.phoneNumber,
    this.role,
    this.urlImage,
  });

  //TOSTRING
  @override
  String toString() {
    return 'User{id: $id, name: $name, email: $email, phoneNumber: $phoneNumber, role: $role, urlImage: $urlImage}';
  }
}
