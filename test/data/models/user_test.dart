import 'package:app_restaurante/data/model/user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('User Model Tests', () {
    test('Constructor crea un User con todos los campos', () {
      final user = User(
        id: 'user123',
        name: 'Ana García',
        email: 'ana.garcia@example.com',
        phoneNumber: '+34612345678',
        role: 'cliente',
        urlImage: 'https://example.com/avatar.jpg',
      );

      expect(user.id, 'user123');
      expect(user.name, 'Ana García');
      expect(user.email, 'ana.garcia@example.com');
      expect(user.phoneNumber, '+34612345678');
      expect(user.role, 'cliente');
      expect(user.urlImage, 'https://example.com/avatar.jpg');
    });

    test('toFirestore convierte correctamente a Map', () {
      final user = User(
        name: 'Carlos López',
        email: 'carlos@example.com',
        phoneNumber: '+34687654321',
        role: 'admin',
      );

      final map = user.toFirestore();

      expect(map['name'], 'Carlos López');
      expect(map['email'], 'carlos@example.com');
      expect(map['phoneNumber'], '+34687654321');
      expect(map['role'], 'admin');
      expect(map.containsKey('id'), false);
    });

    test('toFirestore omite campos nulos', () {
      final user = User(email: 'test@example.com');

      final map = user.toFirestore();

      expect(map.containsKey('email'), true);
      expect(map.containsKey('name'), false);
      expect(map.containsKey('phoneNumber'), false);
      expect(map.containsKey('role'), false);
      expect(map.containsKey('urlImage'), false);
    });

    test('Constructor acepta solo campos obligatorios', () {
      final user = User();

      expect(user.id, isNull);
      expect(user.name, isNull);
      expect(user.email, isNull);
    });

    test('toFirestore incluye isActive cuando está definido', () {
      final activeUser = User(email: 'a@b.com', isActive: true);
      final inactiveUser = User(email: 'a@b.com', isActive: false);

      expect(activeUser.toFirestore()['isActive'], isTrue);
      expect(inactiveUser.toFirestore()['isActive'], isFalse);
    });

    test('toFirestore omite isActive cuando es null', () {
      final user = User(email: 'a@b.com');

      expect(user.toFirestore().containsKey('isActive'), isFalse);
    });

    test('toFirestore incluye googlePhotoUrl cuando está definido', () {
      final user = User(googlePhotoUrl: 'https://photo.url/img.jpg');

      expect(user.toFirestore()['googlePhotoUrl'], 'https://photo.url/img.jpg');
    });

    test('toFirestore omite googlePhotoUrl cuando es null', () {
      final user = User(name: 'Test');

      expect(user.toFirestore().containsKey('googlePhotoUrl'), isFalse);
    });

    test('toFirestore omite deletedAt cuando es null', () {
      final user = User(email: 'a@b.com', isActive: true);

      expect(user.toFirestore().containsKey('deletedAt'), isFalse);
    });

    test('usuario activo tiene isActive true y sin deletedAt', () {
      final user = User(id: 'u1', isActive: true);

      expect(user.isActive, isTrue);
      expect(user.deletedAt, isNull);
    });

    test('usuario inactivo tiene isActive false', () {
      final deletedAt = DateTime(2026, 5, 20);
      final user = User(id: 'u1', isActive: false, deletedAt: deletedAt);

      expect(user.isActive, isFalse);
      expect(user.deletedAt, deletedAt);
    });
  });
}
