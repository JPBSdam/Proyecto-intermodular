class Reservation {
  //ATTRIBUTES
  int? id;
  int? userId;
  int? seats;
  DateTime?
  reservationDate; //creo que sera mas facil unificar fecha y hora, si hace falta, se cambia
  String? state;
  String? comments;

  //CONSTRUCTOR
  Reservation({
    this.id,
    this.userId,
    this.seats,
    this.reservationDate,
    this.state,
    this.comments,
  }); //DateTime? createdAt;

  //TOSTRING
  @override
  String toString() {
    return 'Reservation{id: $id, userId: $userId, seats: $seats, reservationDate: $reservationDate, state: $state, comments: $comments}';
  }
}
