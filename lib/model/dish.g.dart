// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dish.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Dish _$DishFromJson(Map<String, dynamic> json) => Dish(
  id: (json['id'] as num?)?.toInt(),
  name: json['name'] as String?,
  description: json['description'] as String?,
  category: json['category'] as String?,
  urlImage: json['urlImage'] as String?,
  price: (json['price'] as num?)?.toDouble(),
  available: json['available'] as bool?,
);

Map<String, dynamic> _$DishToJson(Dish instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'category': instance.category,
  'urlImage': instance.urlImage,
  'price': instance.price,
  'available': instance.available,
};
