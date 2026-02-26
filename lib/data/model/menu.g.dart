// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'menu.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Menu _$MenuFromJson(Map<String, dynamic> json) => Menu(
  id: (json['id'] as num?)?.toInt(),
  name: json['name'] as String?,
  description: json['description'] as String?,
  dishes: (json['dishes'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList(),
  price: (json['price'] as num?)?.toDouble(),
  available: json['available'] as bool?,
);

Map<String, dynamic> _$MenuToJson(Menu instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'dishes': instance.dishes,
  'price': instance.price,
  'available': instance.available,
};
