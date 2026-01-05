import 'package:json_annotation/json_annotation.dart';
part 'reservation.g.dart';

@JsonSerializable()
class Reservation {
  //ATTRIBUTES
  int? id;
  int? userId;
  int? seats;
  DateTime? reservationDate; //creo que sera mas facil unificar fecha y hora, si no se cambia
  String? state;
  String? comments;

  //CONSTRUCTOR
  Reservation({this.id, this.userId, this.seats, this.reservationDate,
      this.state, this.comments}); //DateTime? createdAt;

  //JSONSERIALIZABLE
  factory Reservation.fromJson(Map<String, dynamic> json) => _$ReservationFromJson(json);
  Map<String, dynamic> toJson() => _$ReservationToJson(this);

  //TOSTRING
  @override
  String toString() {
    return 'Reservation{id: $id, userId: $userId, seats: $seats, reservationDate: $reservationDate, state: $state, comments: $comments}';
  }
}