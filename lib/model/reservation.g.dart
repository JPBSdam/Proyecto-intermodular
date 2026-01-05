// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reservation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Reservation _$ReservationFromJson(Map<String, dynamic> json) => Reservation(
  id: (json['id'] as num?)?.toInt(),
  userId: (json['userId'] as num?)?.toInt(),
  seats: (json['seats'] as num?)?.toInt(),
  reservationDate: json['reservationDate'] == null
      ? null
      : DateTime.parse(json['reservationDate'] as String),
  state: json['state'] as String?,
  comments: json['comments'] as String?,
);

Map<String, dynamic> _$ReservationToJson(Reservation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'seats': instance.seats,
      'reservationDate': instance.reservationDate?.toIso8601String(),
      'state': instance.state,
      'comments': instance.comments,
    };
