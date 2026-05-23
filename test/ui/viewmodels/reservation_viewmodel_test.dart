import 'dart:async';

import 'package:app_restaurante/data/model/reservation.dart';
import 'package:app_restaurante/data/services/firestore/reservation_service.dart';
import 'package:app_restaurante/ui/viewmodels/firestore/reservation_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'reservation_viewmodel_test.mocks.dart';

@GenerateMocks([ReservationService])
void main() {
  group('ReservationViewModel', () {
    late MockReservationService mockService;
    late ReservationViewModel reservationVM;
    late StreamController<List<Reservation>> streamController;

    final pending = Reservation(
      id: '1',
      userId: 'u1',
      state: ReservationStatus.pending,
      seats: 2,
    );
    final confirmed = Reservation(
      id: '2',
      userId: 'u1',
      state: ReservationStatus.confirmed,
      seats: 4,
    );
    final cancelled = Reservation(
      id: '3',
      userId: 'u2',
      state: ReservationStatus.cancelled,
      seats: 2,
    );

    setUp(() {
      mockService = MockReservationService();
      streamController = StreamController<List<Reservation>>.broadcast();
      when(mockService.watchAll()).thenAnswer((_) => streamController.stream);
      when(
        mockService.watchByUser(any),
      ).thenAnswer((_) => streamController.stream);
      reservationVM = ReservationViewModel(mockService);
    });

    tearDown(() {
      streamController.close();
      reservationVM.dispose();
    });

    // ─── Estado inicial

    group('estado inicial', () {
      test(
        'reservations está vacío',
        () => expect(reservationVM.reservations, isEmpty),
      );
      test(
        'isLoading es false',
        () => expect(reservationVM.isLoading, isFalse),
      );
      test(
        'errorMessage está vacío',
        () => expect(reservationVM.errorMessage, ''),
      );
      test(
        'isWatching es false',
        () => expect(reservationVM.isWatching, isFalse),
      );
      test('pendingCount es 0', () => expect(reservationVM.pendingCount, 0));
    });

    // ─── Escucha de reservas (todas)

    group('watchAll', () {
      test('recibe la lista de reservas', () async {
        // Act
        reservationVM.watchAll();
        streamController.add([pending, confirmed, cancelled]);
        await Future.microtask(() {});
        expect(reservationVM.reservations, hasLength(3));
        expect(reservationVM.isLoading, isFalse);
      });

      test('no re-suscribe si ya está escuchando con scope "all"', () {
        reservationVM.watchAll();
        reservationVM.watchAll();
        verify(mockService.watchAll()).called(1);
      });

      test('isWatching es true tras iniciar escucha', () {
        reservationVM.watchAll();
        expect(reservationVM.isWatching, isTrue);
      });
    });

    // ─── Escucha de reservas por usuario

    group('watchByUser', () {
      test('recibe solo las reservas del usuario', () async {
        reservationVM.watchByUser('u1');
        streamController.add([pending, confirmed]);
        await Future.microtask(() {});
        expect(reservationVM.reservations, hasLength(2));
      });

      test('no re-suscribe si el userId no cambia', () {
        reservationVM.watchByUser('u1');
        reservationVM.watchByUser('u1');
        verify(mockService.watchByUser('u1')).called(1);
      });

      test('re-suscribe cuando cambia el userId', () {
        reservationVM.watchByUser('u1');
        reservationVM.watchByUser('u2');
        verify(mockService.watchByUser('u1')).called(1);
        verify(mockService.watchByUser('u2')).called(1);
      });
    });

    // ─── Conteo de reservas pendientes

    group('pendingCount', () {
      test('cuenta solo las reservas en estado pending', () async {
        // Arrange
        reservationVM.watchAll();
        streamController.add([pending, confirmed, cancelled]);
        await Future.microtask(() {});
        expect(reservationVM.pendingCount, 1);
      });

      test('es 0 cuando no hay reservas pendientes', () async {
        reservationVM.watchAll();
        streamController.add([confirmed, cancelled]);
        await Future.microtask(() {});
        expect(reservationVM.pendingCount, 0);
      });
    });

    // ─── Confirmar reserva

    group('confirmReservation', () {
      test('llama al servicio con estado confirmed', () async {
        when(mockService.updateStatuses(any, any)).thenAnswer((_) async {});
        await reservationVM.confirmReservation('1');
        verify(
          mockService.updateStatuses(['1'], ReservationStatus.confirmed),
        ).called(1);
      });

      test('setea errorMessage si falla', () async {
        when(
          mockService.updateStatuses(any, any),
        ).thenThrow('No tienes permisos para realizar esta operación.');
        await reservationVM.confirmReservation('1');
        expect(reservationVM.errorMessage, isNotEmpty);
      });
    });

    // ─── Cancelar Reserva
    group('cancelReservation', () {
      test('llama al servicio con estado cancelled', () async {
        when(mockService.updateStatuses(any, any)).thenAnswer((_) async {});
        await reservationVM.cancelReservation('1');
        verify(
          mockService.updateStatuses(['1'], ReservationStatus.cancelled),
        ).called(1);
      });
    });

    // ─── Completar reserva

    group('completeReservation', () {
      test('llama al servicio con estado completed', () async {
        when(mockService.updateStatuses(any, any)).thenAnswer((_) async {});
        await reservationVM.completeReservation('1');
        verify(
          mockService.updateStatuses(['1'], ReservationStatus.completed),
        ).called(1);
      });
    });

    // ─── Completar muchas reservas

    group('completeMultipleReservations', () {
      test('completa varias reservas a la vez', () async {
        when(mockService.updateStatuses(any, any)).thenAnswer((_) async {});
        await reservationVM.completeMultipleReservations(['1', '2', '3']);
        verify(
          mockService.updateStatuses([
            '1',
            '2',
            '3',
          ], ReservationStatus.completed),
        ).called(1);
      });
    });

    // ─── Crear reserva

    group('addReservation', () {
      test('llama al servicio con la reserva correcta', () async {
        when(mockService.createReservation(any)).thenAnswer((_) async {});
        await reservationVM.addReservation(pending);
        verify(mockService.createReservation(pending)).called(1);
      });

      test('setea errorMessage si falla', () async {
        when(mockService.createReservation(any)).thenThrow('Error inesperado');
        await reservationVM.addReservation(pending);
        expect(reservationVM.errorMessage, isNotEmpty);
      });
    });

    // ─── Eliminar reserva

    group('deleteReservation', () {
      test('llama al servicio con el id correcto', () async {
        when(mockService.deleteReservation(any)).thenAnswer((_) async {});
        await reservationVM.deleteReservation('1');
        verify(mockService.deleteReservation('1')).called(1);
      });
    });
  });
}
