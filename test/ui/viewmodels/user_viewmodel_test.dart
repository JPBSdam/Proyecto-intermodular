import 'dart:async';

import 'package:app_restaurante/data/model/reservation.dart';
import 'package:app_restaurante/data/model/user.dart';
import 'package:app_restaurante/data/services/auth/auth_service.dart';
import 'package:app_restaurante/data/services/firestore/reservation_service.dart';
import 'package:app_restaurante/data/services/firestore/user_service.dart';
import 'package:app_restaurante/data/services/storage/storage_service.dart';
import 'package:app_restaurante/ui/viewmodels/firestore/user_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'user_viewmodel_test.mocks.dart';

@GenerateMocks([UserService, ReservationService, StorageService, AuthService])
void main() {
  group('UserViewModel', () {
    late MockUserService mockService;
    late MockReservationService mockReservationService;
    late MockStorageService mockStorageService;
    late MockAuthService mockAuthService;
    late UserViewModel vm;

    final testUser = User(
      id: 'u1',
      name: 'Ana',
      email: 'ana@test.com',
      isActive: true,
    );

    setUp(() {
      mockService = MockUserService();
      mockReservationService = MockReservationService();
      mockStorageService = MockStorageService();
      mockAuthService = MockAuthService();
      vm = UserViewModel(
        service: mockService,
        reservationService: mockReservationService,
        storageService: mockStorageService,
        authService: mockAuthService,
      );
    });

    tearDown(() => vm.dispose());

    // ─── Estado inicial ───────────────────────────────────────────────────────

    group('estado inicial', () {
      test('isLoading es false', () => expect(vm.isLoading, isFalse));
      test('error es cadena vacía', () => expect(vm.error, isEmpty));
      test('user es null', () => expect(vm.user, isNull));
    });

    // ─── Fetch de usuario

    group('fetchUserById', () {
      test('retorna el usuario y no setea error en éxito', () async {
        when(mockService.getUserById('u1')).thenAnswer((_) async => testUser);

        final result = await vm.fetchUserById('u1');

        expect(result, isNotNull);
        expect(result!.name, 'Ana');
        expect(vm.error, isEmpty);
      });

      test('retorna null y setea error cuando falla', () async {
        when(mockService.getUserById(any)).thenThrow('No encontrado');

        final result = await vm.fetchUserById('inexistente');

        expect(result, isNull);
        expect(vm.error, contains('Error al obtener usuario'));
      });

      test('isLoading es false al terminar', () async {
        when(mockService.getUserById(any)).thenAnswer((_) async => testUser);

        await vm.fetchUserById('u1');

        expect(vm.isLoading, isFalse);
      });
    });

    // ─── Actualización de usuario

    group('updateUser', () {
      test('llama al servicio y no setea error en éxito', () async {
        when(mockService.updateUser(any)).thenAnswer((_) async {});

        await vm.updateUser(testUser);

        verify(mockService.updateUser(testUser)).called(1);
        expect(vm.error, isEmpty);
      });

      test('setea error cuando falla', () async {
        when(mockService.updateUser(any)).thenThrow('Error de red');

        await vm.updateUser(testUser);

        expect(vm.error, contains('Error al actualizar'));
      });
    });

    // ─── Guardado (con o sin imagen)

    group('saveUser', () {
      test('sin imagen solo actualiza el documento', () async {
        when(mockService.updateUser(any)).thenAnswer((_) async {});

        await vm.saveUser(testUser, null);

        verify(mockService.updateUser(testUser)).called(1);
        verifyNever(mockStorageService.uploadUserAvatar(any, any));
        expect(vm.error, isEmpty);
      });

      test('setea error y relanza si falla', () async {
        when(mockService.updateUser(any)).thenThrow('Error Firestore');

        expect(() => vm.saveUser(testUser, null), throwsA(anything));
      });
    });

    // ─── Stream de usuario

    group('watchUser', () {
      test('actualiza user cuando llegan datos del stream', () async {
        final controller = StreamController<User?>();
        when(mockService.watchUser('u1')).thenAnswer((_) => controller.stream);

        vm.watchUser('u1');
        controller.add(testUser);
        await Future.microtask(() {});

        expect(vm.user?.name, 'Ana');
        await controller.close();
      });

      test('setea error cuando el stream falla', () async {
        final controller = StreamController<User?>();
        when(mockService.watchUser('u1')).thenAnswer((_) => controller.stream);

        vm.watchUser('u1');
        controller.addError('Error de conexión');
        await Future.microtask(() {});

        expect(vm.error, contains('Error al cargar el usuario'));
        await controller.close();
      });
    });

    // ─── Eliminación de cuenta

    group('cancelación de reservas al borrar cuenta', () {
      test('cancela reservas activas antes de anonimizar', () async {
        final pending = Reservation(
          id: 'r1',
          userId: 'u1',
          state: ReservationStatus.pending,
        );
        final confirmed = Reservation(
          id: 'r2',
          userId: 'u1',
          state: ReservationStatus.confirmed,
        );

        when(
          mockReservationService.getActiveByUser('u1'),
        ).thenAnswer((_) async => [pending, confirmed]);
        when(
          mockReservationService.updateStatuses(any, any),
        ).thenAnswer((_) async {});
        when(mockService.anonymize('u1')).thenAnswer((_) async {});
        when(mockAuthService.deleteCurrentUser()).thenAnswer((_) async {});
        when(mockAuthService.currentUser).thenReturn(null);

        await vm.deleteAccount('u1');

        verify(
          mockReservationService.updateStatuses([
            'r1',
            'r2',
          ], ReservationStatus.cancelled),
        ).called(1);
        verify(mockService.anonymize('u1')).called(1);
        verify(mockAuthService.deleteCurrentUser()).called(1);
      });

      test('no llama a updateStatuses si no hay reservas activas', () async {
        when(
          mockReservationService.getActiveByUser('u1'),
        ).thenAnswer((_) async => []);
        when(mockService.anonymize('u1')).thenAnswer((_) async {});
        when(mockAuthService.deleteCurrentUser()).thenAnswer((_) async {});
        when(mockAuthService.currentUser).thenReturn(null);

        await vm.deleteAccount('u1');

        verifyNever(mockReservationService.updateStatuses(any, any));
        verify(mockService.anonymize('u1')).called(1);
      });
    });
  });
}
