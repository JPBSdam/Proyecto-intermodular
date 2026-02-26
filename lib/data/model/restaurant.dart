class Restaurant {
  //ATTRIBUTES
  int? id;
  int? adminId; //aqui va el id del user propietario
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

  //TOSTRING
  @override
  String toString() {
    return 'Restaurant{id: $id, name: $name, address: $address, phoneNumber: $phoneNumber, description: $description, email: $email, capacity: $capacity, urlImage: $urlImage, open: $open, schedule: $schedule}';
  }
}
