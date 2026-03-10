import 'package:app_restaurante/data/model/dish.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Dish Model Tests', () {
    test('Constructor crea un Dish con todos los campos', () {
      // Arrange & Act
      final dish = Dish(
        id: '1',
        name: 'Paella',
        description: 'Paella valenciana tradicional',
        category: 'Platos principales',
        urlImage: 'https://example.com/paella.jpg',
        price: 15.50,
        available: true,
      );

      // Assert
      expect(dish.id, '1');
      expect(dish.name, 'Paella');
      expect(dish.description, 'Paella valenciana tradicional');
      expect(dish.category, 'Platos principales');
      expect(dish.urlImage, 'https://example.com/paella.jpg');
      expect(dish.price, 15.50);
      expect(dish.available, true);
    });

    test('toFirestore convierte correctamente a Map', () {
      // Arrange
      final dish = Dish(
        name: 'Paella',
        description: 'Paella valenciana',
        category: 'Principales',
        urlImage: 'https://example.com/paella.jpg',
        price: 15.50,
        available: true,
      );

      // Act
      final map = dish.toFirestore();

      // Assert
      expect(map['name'], 'Paella');
      expect(map['description'], 'Paella valenciana');
      expect(map['category'], 'Principales');
      expect(map['urlImage'], 'https://example.com/paella.jpg');
      expect(map['price'], 15.50);
      expect(map['available'], true);
      expect(map.containsKey('id'), false); // id no debe estar en toFirestore
    });

    test('toFirestore omite campos nulos', () {
      // Arrange
      final dish = Dish(name: 'Paella');

      // Act
      final map = dish.toFirestore();

      // Assert
      expect(map.containsKey('name'), true);
      expect(map.containsKey('description'), false);
      expect(map.containsKey('category'), false);
      expect(map.containsKey('price'), false);
    });

    test('toString devuelve representación correcta', () {
      // Arrange
      final dish = Dish(id: '1', name: 'Paella', price: 15.50);

      // Act
      final result = dish.toString();

      // Assert
      expect(result, contains('Dish{'));
      expect(result, contains('id: 1'));
      expect(result, contains('name: Paella'));
      expect(result, contains('price: 15.5'));
    });
  });
}
