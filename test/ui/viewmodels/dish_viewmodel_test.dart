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

    // ─── Estado inicial

    group('estado inicial', () {
      test('dishes está vacío', () => expect(dishVM.dishes, isEmpty));
      test('isLoading es false', () => expect(dishVM.isLoading, isFalse));
      test('errorMessage está vacío', () => expect(dishVM.errorMessage, ''));
      test(
        'isWatchingDishes es false',
        () => expect(dishVM.isWatchingDishes, isFalse),
      );
    });

    // ─── Escucha de platos

    group('watchDishes', () {
      test('actualiza dishes cuando el stream emite datos', () async {
        dishVM.watchDishes();
        streamController.add([testDish]);
        await Future.microtask(() {});
        expect(dishVM.dishes, hasLength(1));
        expect(dishVM.dishes.first.name, 'Paella');
        expect(dishVM.isLoading, isFalse);
      });

      test('no re-suscribe si ya está escuchando', () {
        dishVM.watchDishes();
        dishVM.watchDishes();
        verify(mockService.watchDishes()).called(1);
      });

      test('actualiza dishes con lista vacía', () async {
        dishVM.watchDishes();
        streamController.add([]);
        await Future.microtask(() {});
        expect(dishVM.dishes, isEmpty);
        expect(dishVM.isLoading, isFalse);
      });

      test('notifica a la UI cuando llegan datos', () async {
        var notifyCount = 0;
        dishVM.addListener(() => notifyCount++);
        dishVM.watchDishes();
        streamController.add([testDish]);
        await Future.microtask(() {});
        expect(notifyCount, greaterThan(0));
      });
    });

    // ─── Crear plato

    group('saveDish (plato nuevo, sin imagen)', () {
      final newDish = Dish(
        name: 'Paella',
        description: 'Paella valenciana',
        category: 'Principales',
        price: 15.50,
        available: true,
      );

      test('llama a createDish cuando el plato no tiene id', () async {
        when(mockService.createDish(any)).thenAnswer((_) async {});

        await dishVM.saveDish(newDish, null);

        verify(mockService.createDish(newDish)).called(1);
        verifyNever(mockService.updateDish(any));
      });

      test('setea errorMessage si createDish lanza un error', () async {
        when(mockService.createDish(any)).thenThrow('Error inesperado');

        await dishVM.saveDish(newDish, null);

        expect(dishVM.errorMessage, isNotEmpty);
      });

      test('isLoading es false al terminar', () async {
        when(mockService.createDish(any)).thenAnswer((_) async {});

        await dishVM.saveDish(newDish, null);

        expect(dishVM.isLoading, isFalse);
      });
    });

    // ─── Editar/Actualizar plato

    group('saveDish (plato existente, sin imagen)', () {
      test('llama a updateDish cuando el plato ya tiene id', () async {
        when(mockService.updateDish(any)).thenAnswer((_) async {});
        final updated = Dish(id: '1', name: 'Paella actualizada', price: 18.0);
        await dishVM.saveDish(updated, null);
        verify(mockService.updateDish(updated)).called(1);
        verifyNever(mockService.createDish(any));
      });
      test('setea errorMessage si updateDish falla', () async {
        when(
          mockService.updateDish(any),
        ).thenThrow('No tienes permisos para realizar esta operación.');
        await dishVM.saveDish(testDish, null);
        expect(dishVM.errorMessage, isNotEmpty);
      });
    });

    // ─── Eliminar plato

    group('deleteDish', () {
      test('llama al servicio con el id correcto', () async {
        // Arrange
        when(mockService.deleteDish(any)).thenAnswer((_) async {});
        await dishVM.deleteDish('1');
        verify(mockService.deleteDish('1')).called(1);
      });
      test('setea errorMessage si el servicio falla', () async {
        when(mockService.deleteDish(any)).thenThrow('El documento no existe.');
        await dishVM.deleteDish('999');
        expect(dishVM.errorMessage, isNotEmpty);
      });
    });

    // ─── Obtener plato por ID

    group('fetchDishById', () {
      test('retorna el plato cuando existe', () async {
        when(mockService.getDishById(any)).thenAnswer((_) async => testDish);

        final result = await dishVM.fetchDishById('1');
        expect(result, isNotNull);
        expect(result?.name, 'Paella');
      });

      test('retorna null y setea errorMessage si falla', () async {
        when(mockService.getDishById(any)).thenThrow('El documento no existe.');
        final result = await dishVM.fetchDishById('999');
        expect(result, isNull);
        expect(dishVM.errorMessage, isNotEmpty);
      });
    });
  });
}
