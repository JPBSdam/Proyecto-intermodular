import 'package:app_restaurante/data/model/reservation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Reservation Model Tests', () {
    test('Constructor crea una Reservation con todos los campos', () {
      // Arrange
      final date = DateTime(2026, 3, 15, 20, 30);

      // Act
      final reservation = Reservation(
        id: 'res123',
        userId: 'user456',
        seats: 4,
        reservationDate: date,
        state: 'confirmada',
        comments: 'Mesa junto a la ventana',
      );

      // Assert
      expect(reservation.id, 'res123');
      expect(reservation.userId, 'user456');
      expect(reservation.seats, 4);
      expect(reservation.reservationDate, date);
      expect(reservation.state, 'confirmada');
      expect(reservation.comments, 'Mesa junto a la ventana');
    });

    test('toFirestore convierte correctamente a Map con Timestamp', () {
      // Arrange
      final date = DateTime(2026, 3, 15, 20, 30);
      final reservation = Reservation(
        userId: 'user123',
        seats: 2,
        reservationDate: date,
        state: 'pendiente',
        comments: 'Sin alérgenos',
      );

      // Act
      final map = reservation.toFirestore();

      // Assert
      expect(map['userId'], 'user123');
      expect(map['seats'], 2);
      expect(map['reservationDate'], isA<Timestamp>());
      expect(map['state'], 'pendiente');
      expect(map['comments'], 'Sin alérgenos');
    });

    test('toFirestore omite campos nulos', () {
      // Arrange
      final reservation = Reservation(userId: 'user123', seats: 2);

      // Act
      final map = reservation.toFirestore();

      // Assert
      expect(map.containsKey('userId'), true);
      expect(map.containsKey('seats'), true);
      expect(map.containsKey('reservationDate'), false);
      expect(map.containsKey('state'), false);
      expect(map.containsKey('comments'), false);
    });

    test('Conversion de fecha a Timestamp es correcta', () {
      // Arrange
      final originalDate = DateTime(2026, 12, 25, 21, 0);
      final reservation = Reservation(
        userId: 'user1',
        seats: 6,
        reservationDate: originalDate,
      );

      // Act
      final map = reservation.toFirestore();
      final timestamp = map['reservationDate'] as Timestamp;
      final convertedDate = timestamp.toDate();

      // Assert
      expect(convertedDate.year, originalDate.year);
      expect(convertedDate.month, originalDate.month);
      expect(convertedDate.day, originalDate.day);
      expect(convertedDate.hour, originalDate.hour);
      expect(convertedDate.minute, originalDate.minute);
    });
  });
}
