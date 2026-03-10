import 'package:app_restaurante/data/model/user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('User Model Tests', () {
    test('Constructor crea un User con todos los campos', () {
      // Arrange & Act
      final user = User(
        id: 'user123',
        name: 'Ana García',
        email: 'ana.garcia@example.com',
        phoneNumber: '+34612345678',
        role: 'cliente',
        urlImage: 'https://example.com/avatar.jpg',
      );

      // Assert
      expect(user.id, 'user123');
      expect(user.name, 'Ana García');
      expect(user.email, 'ana.garcia@example.com');
      expect(user.phoneNumber, '+34612345678');
      expect(user.role, 'cliente');
      expect(user.urlImage, 'https://example.com/avatar.jpg');
    });

    test('toFirestore convierte correctamente a Map', () {
      // Arrange
      final user = User(
        name: 'Carlos López',
        email: 'carlos@example.com',
        phoneNumber: '+34687654321',
        role: 'admin',
      );

      // Act
      final map = user.toFirestore();

      // Assert
      expect(map['name'], 'Carlos López');
      expect(map['email'], 'carlos@example.com');
      expect(map['phoneNumber'], '+34687654321');
      expect(map['role'], 'admin');
      expect(map.containsKey('id'), false);
    });

    test('toFirestore omite campos nulos', () {
      // Arrange
      final user = User(email: 'test@example.com');

      // Act
      final map = user.toFirestore();

      // Assert
      expect(map.containsKey('email'), true);
      expect(map.containsKey('name'), false);
      expect(map.containsKey('phoneNumber'), false);
      expect(map.containsKey('role'), false);
      expect(map.containsKey('urlImage'), false);
    });

    test('Constructor acepta solo campos obligatorios', () {
      // Arrange & Act
      final user = User();

      // Assert
      expect(user.id, isNull);
      expect(user.name, isNull);
      expect(user.email, isNull);
    });
  });
}
