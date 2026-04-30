import 'dart:async';

import 'package:app_restaurante/data/model/dish.dart';
import 'package:app_restaurante/data/services/firestore/dish_service.dart';
import 'package:app_restaurante/ui/viewmodels/firestore/dish_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'dish_viewmodel_test.mocks.dart';

@GenerateMocks([DishService])
void main() {
  group('DishViewModel', () {
    late MockDishService mockService;
    late DishViewModel dishVM;
    late StreamController<List<Dish>> streamController;

    final testDish = Dish(
      id: '1',
      name: 'Paella',
      description: 'Paella valenciana',
      category: 'Principales',
      price: 15.50,
      available: true,
    );

    setUp(() {
      mockService = MockDishService();
      streamController = StreamController<List<Dish>>.broadcast();
      when(
        mockService.watchDishes(),
      ).thenAnswer((_) => streamController.stream);
      dishVM = DishViewModel(mockService);
    });

    tearDown(() {
      streamController.close();
      dishVM.dispose();
    });

    // ─── Estado inicial ───────────────────────────────────────────────────────

    group('estado inicial', () {
      test('dishes está vacío', () => expect(dishVM.dishes, isEmpty));
      test('isLoading es false', () => expect(dishVM.isLoading, isFalse));
      test('errorMessage está vacío', () => expect(dishVM.errorMessage, ''));
      test(
        'isWatchingDishes es false',
        () => expect(dishVM.isWatchingDishes, isFalse),
      );
    });

    // ─── watchDishes ──────────────────────────────────────────────────────────

    group('watchDishes', () {
      test('actualiza dishes cuando el stream emite datos', () async {
        // Act
        dishVM.watchDishes();
        streamController.add([testDish]);
        await Future.microtask(() {});

        // Assert
        expect(dishVM.dishes, hasLength(1));
        expect(dishVM.dishes.first.name, 'Paella');
        expect(dishVM.isLoading, isFalse);
      });

      test('no re-suscribe si ya está escuchando', () {
        // Act
        dishVM.watchDishes();
        dishVM.watchDishes();

        // Assert — solo se llama una vez al servicio
        verify(mockService.watchDishes()).called(1);
      });

      test('actualiza dishes con lista vacía', () async {
        // Act
        dishVM.watchDishes();
        streamController.add([]);
        await Future.microtask(() {});

        // Assert
        expect(dishVM.dishes, isEmpty);
        expect(dishVM.isLoading, isFalse);
      });

      test('notifica a la UI cuando llegan datos', () async {
        // Arrange
        var notifyCount = 0;
        dishVM.addListener(() => notifyCount++);

        // Act
        dishVM.watchDishes();
        streamController.add([testDish]);
        await Future.microtask(() {});

        // Assert
        expect(notifyCount, greaterThan(0));
      });
    });

    // ─── addDish ──────────────────────────────────────────────────────────────

    group('addDish', () {
      test('llama al servicio con el plato correcto', () async {
        // Arrange
        when(mockService.createDish(any)).thenAnswer((_) async {});

        // Act
        await dishVM.addDish(testDish);

        // Assert
        verify(mockService.createDish(testDish)).called(1);
      });

      test('setea errorMessage si el servicio lanza un error', () async {
        // Arrange
        when(mockService.createDish(any)).thenThrow('Error inesperado');

        // Act
        await dishVM.addDish(testDish);

        // Assert
        expect(dishVM.errorMessage, isNotEmpty);
      });

      test('isLoading es false al terminar', () async {
        // Arrange
        when(mockService.createDish(any)).thenAnswer((_) async {});

        // Act
        await dishVM.addDish(testDish);

        // Assert
        expect(dishVM.isLoading, isFalse);
      });
    });

    // ─── updateDish ───────────────────────────────────────────────────────────

    group('updateDish', () {
      test('llama al servicio con el plato actualizado', () async {
        // Arrange
        when(mockService.updateDish(any)).thenAnswer((_) async {});
        final updated = Dish(id: '1', name: 'Paella actualizada', price: 18.0);

        // Act
        await dishVM.updateDish(updated);

        // Assert
        verify(mockService.updateDish(updated)).called(1);
      });

      test('setea errorMessage si el servicio falla', () async {
        // Arrange
        when(
          mockService.updateDish(any),
        ).thenThrow('No tienes permisos para realizar esta operación.');

        // Act
        await dishVM.updateDish(testDish);

        // Assert
        expect(dishVM.errorMessage, isNotEmpty);
      });
    });

    // ─── deleteDish ───────────────────────────────────────────────────────────

    group('deleteDish', () {
      test('llama al servicio con el id correcto', () async {
        // Arrange
        when(mockService.deleteDish(any)).thenAnswer((_) async {});

        // Act
        await dishVM.deleteDish('1');

        // Assert
        verify(mockService.deleteDish('1')).called(1);
      });

      test('setea errorMessage si el servicio falla', () async {
        // Arrange
        when(mockService.deleteDish(any)).thenThrow('El documento no existe.');

        // Act
        await dishVM.deleteDish('999');

        // Assert
        expect(dishVM.errorMessage, isNotEmpty);
      });
    });

    // ─── fetchDishById ────────────────────────────────────────────────────────

    group('fetchDishById', () {
      test('retorna el plato cuando existe', () async {
        // Arrange
        when(mockService.getDishById(any)).thenAnswer((_) async => testDish);

        // Act
        final result = await dishVM.fetchDishById('1');

        // Assert
        expect(result, isNotNull);
        expect(result?.name, 'Paella');
      });

      test('retorna null y setea errorMessage si falla', () async {
        // Arrange
        when(mockService.getDishById(any)).thenThrow('El documento no existe.');

        // Act
        final result = await dishVM.fetchDishById('999');

        // Assert
        expect(result, isNull);
        expect(dishVM.errorMessage, isNotEmpty);
      });
    });
  });
}
