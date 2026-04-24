import 'package:cloud_firestore/cloud_firestore.dart';

/// Estados posibles de una reserva.
/// - pending:   el cliente ha solicitado la reserva (pendiente de confirmación admin)
/// - confirmed: el admin ha confirmado la reserva
/// - cancelled: la reserva ha sido cancelada (por cliente o admin)
/// - completed: los clientes ya han asistido (marcado por admin)

class ReservationStatus {
  static const String pending = 'pending';
  static const String confirmed = 'confirmed';
  static const String cancelled = 'cancelled';
  static const String completed = 'completed';
}

class Reservation {
  //ATTRIBUTES
  String? id;
  String? userId; // uid de Firebase del cliente
  String? userName; // nombre visible para el admin
  String? userEmail; // email visible para el admin
  String? userPhone; // teléfono de contacto
  int? seats;
  DateTime? reservationDate; // fecha y hora unificadas
  String? state; // ReservationStatus.*
  String? comments; // peticiones especiales
  bool? hasBaby; // necesitan espacio para carricoche
  int? babyCount; // número de bebés (solo si hasBaby == true)
  DateTime? createdAt;

  //CONSTRUCTOR
  Reservation({
    this.id,
    this.userId,
    this.userName,
    this.userEmail,
    this.userPhone,
    this.seats,
    this.reservationDate,
    this.state,
    this.comments,
    this.hasBaby,
    this.babyCount,
    this.createdAt,
  });

  //FROMFIRESTORE
  factory Reservation.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final map = snapshot.data();
    return Reservation(
      id: snapshot.id,
      userId: map?['userId'] as String?,
      userName: map?['userName'] as String?,
      userEmail: map?['userEmail'] as String?,
      userPhone: map?['userPhone'] as String?,
      seats: map?['seats'] as int?,
      reservationDate: (map?['reservationDate'] as Timestamp?)?.toDate(),
      state: map?['state'] as String?,
      comments: map?['comments'] as String?,
      hasBaby: map?['hasBaby'] as bool?,
      babyCount: map?['babyCount'] as int?,
      createdAt: (map?['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  //TOFIRESTORE
  Map<String, dynamic> toFirestore() {
    return {
      if (userId != null) "userId": userId,
      if (userName != null) "userName": userName,
      if (userEmail != null) "userEmail": userEmail,
      if (userPhone != null) "userPhone": userPhone,
      if (seats != null) "seats": seats,
      if (reservationDate != null)
        "reservationDate": Timestamp.fromDate(reservationDate!),
      if (state != null) "state": state,
      if (comments != null) "comments": comments,
      if (hasBaby != null) "hasBaby": hasBaby,
      if (babyCount != null) "babyCount": babyCount,
      if (createdAt != null) "createdAt": Timestamp.fromDate(createdAt!),
    };
  }
}
