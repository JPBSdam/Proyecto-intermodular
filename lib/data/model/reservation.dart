import 'package:cloud_firestore/cloud_firestore.dart';

class Reservation {
  //ATTRIBUTES
  String? id;
  String? userId;
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

  //FROMFIRESTORE
  factory Reservation.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final map = snapshot.data();
    Timestamp? ts = map?['reservationDate'] as Timestamp?;
    return Reservation(
      id: snapshot.id,
      userId: map?['userId'] as String?,
      seats: map?['seats'] as int?,
      reservationDate: ts?.toDate(),
      state: map?['state'] as String?,
      comments: map?['comments'] as String?,
    );
  }

  //TOFIRESTORE
  Map<String, dynamic> toFirestore() {
    return {
      if (userId != null) "userId": userId,
      if (seats != null) "seats": seats,
      if (reservationDate != null)
        "reservationDate": Timestamp.fromDate(reservationDate!),
      if (state != null) "state": state,
      if (comments != null) "comments": comments,
    };
  }
}
