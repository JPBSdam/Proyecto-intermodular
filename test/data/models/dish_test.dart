import 'package:app_restaurante/data/model/dish.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
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

    test(
      'fromFirestore obtiene id desde snapshot.id (sin id en payload)',
      () async {
        // Arrange
        final firestore = FakeFirebaseFirestore();
        final docRef = firestore.collection('dishes').doc('1');

        await docRef.set({
          // El id NO se guarda en el payload; Firestore lo da en snapshot.id
          'name': 'Paella',
          'description': 'Paella valenciana',
          'category': 'Principales',
          'urlImage': 'https://example.com/paella.jpg',
          'price': 15.50,
          'available': true,
        });

        final snapshot = await docRef.get();

        // Act
        final dish = Dish.fromFirestore(snapshot, null);

        // Assert
        expect(dish.id, '1');
        expect(dish.name, 'Paella');
        expect(dish.description, 'Paella valenciana');
        expect(dish.category, 'Principales');
        expect(dish.urlImage, 'https://example.com/paella.jpg');
        expect(dish.price, 15.50);
        expect(dish.available, true);
      },
    );

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
  });
}
