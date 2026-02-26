// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'restaurant.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Restaurant _$RestaurantFromJson(Map<String, dynamic> json) => Restaurant(
  id: (json['id'] as num?)?.toInt(),
  name: json['name'] as String?,
  address: json['address'] as String?,
  phoneNumber: json['phone_number'] as String?,
  description: json['description'] as String?,
  email: json['email'] as String?,
  capacity: (json['capacity'] as num?)?.toInt(),
  urlImage: json['url_image'] as String?,
  open: json['open'] as bool?,
  schedule: (json['schedule'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, e as String),
  ),
)..adminId = (json['admin_id'] as num?)?.toInt();

Map<String, dynamic> _$RestaurantToJson(Restaurant instance) =>
    <String, dynamic>{
      'id': instance.id,
      'admin_id': instance.adminId,
      'name': instance.name,
      'address': instance.address,
      'phone_number': instance.phoneNumber,
      'description': instance.description,
      'email': instance.email,
      'capacity': instance.capacity,
      'url_image': instance.urlImage,
      'open': instance.open,
      'schedule': instance.schedule,
    };
