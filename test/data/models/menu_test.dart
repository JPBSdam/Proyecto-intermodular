import 'package:app_restaurante/data/model/menu.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Menu Model Tests', () {
    test('Constructor crea un Menu con todos los campos', () {
      // Arrange & Act
      final menu = Menu(
        id: '1',
        name: 'Menú del Día',
        description: 'Menú completo con entrante, principal y postre',
        dishes: ['dish1', 'dish2', 'dish3'],
        price: 12.99,
        available: true,
      );

      // Assert
      expect(menu.id, '1');
      expect(menu.name, 'Menú del Día');
      expect(menu.description, contains('Menú completo'));
      expect(menu.dishes, hasLength(3));
      expect(menu.dishes, contains('dish1'));
      expect(menu.price, 12.99);
      expect(menu.available, true);
    });

    test('toFirestore convierte correctamente a Map', () {
      // Arrange
      final menu = Menu(
        name: 'Menú Vegetariano',
        description: 'Opciones vegetarianas',
        dishes: ['ensalada', 'pasta'],
        price: 10.50,
        available: true,
      );

      // Act
      final map = menu.toFirestore();

      // Assert
      expect(map['name'], 'Menú Vegetariano');
      expect(map['description'], 'Opciones vegetarianas');
      expect(map['dishes'], isA<List<String>>());
      expect(map['dishes'], hasLength(2));
      expect(map['price'], 10.50);
      expect(map['available'], true);
    });

    test('toFirestore omite campos nulos', () {
      // Arrange
      final menu = Menu(name: 'Menú Básico');

      // Act
      final map = menu.toFirestore();

      // Assert
      expect(map.containsKey('name'), true);
      expect(map.containsKey('description'), false);
      expect(map.containsKey('dishes'), false);
      expect(map.containsKey('price'), false);
    });

    test('Constructor acepta lista vacía de platos', () {
      // Arrange & Act
      final menu = Menu(name: 'Menú Sin Platos', dishes: []);

      // Assert
      expect(menu.dishes, isEmpty);
    });

    test('toString devuelve representación correcta', () {
      // Arrange
      final menu = Menu(id: '1', name: 'Menú del Día', price: 12.99);

      // Act
      final result = menu.toString();

      // Assert
      expect(result, contains('Menu{'));
      expect(result, contains('id: 1'));
      expect(result, contains('name: Menú del Día'));
      expect(result, contains('price: 12.99'));
    });
  });
}
