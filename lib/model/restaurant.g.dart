// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'restaurant.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Restaurant _$RestaurantFromJson(Map<String, dynamic> json) => Restaurant(
  (json['id'] as num?)?.toInt(),
  json['name'] as String?,
  json['address'] as String?,
  json['phoneNumber'] as String?,
  json['description'] as String?,
  json['email'] as String?,
  (json['capacity'] as num?)?.toInt(),
  json['urlImage'] as String?,
  json['open'] as bool?,
  (json['schedule'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, e as String),
  ),
);

Map<String, dynamic> _$RestaurantToJson(Restaurant instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'address': instance.address,
      'phoneNumber': instance.phoneNumber,
      'description': instance.description,
      'email': instance.email,
      'capacity': instance.capacity,
      'urlImage': instance.urlImage,
      'open': instance.open,
      'schedule': instance.schedule,
    };
