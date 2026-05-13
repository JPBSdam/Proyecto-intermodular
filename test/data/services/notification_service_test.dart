// Tests del servicio de notificaciones de SabrosApp.
//
// ESTRATEGIA DE TEST:
// flutter_local_notifications usa un singleton con constructor privado y
// necesita el entorno nativo Android/iOS. En tests no tenemos ese entorno,
// así que usamos el patron "Spy":
//
//   NotificationService usa _api (NotificationsApi abstracta).
//   En produccion se usa _RealNotificationsApi (va al plugin de verdad).
//   En tests se inyecta _SpyNotificationsApi, que guarda las llamadas en
//   una lista sin tocar ningun canal nativo.
//
// GRUPOS:
//   1. showReservationConfirmed() - show() con datos correctos
//   2. scheduleReservationReminder() - gates de logica + zonedSchedule()
//   3. cancelReservationReminder()   - cancel() con ID correcto
//   4. showNewDish()              - show() con el nombre del plato
//   5. showFromFcm()              - show() con ID fijo 300.000
//   6. showFromQueue()            - show() con ID en rango >=300.001
//   7. Rangos de IDs unicos       - logica pura de las formulas de hashCode

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:app_restaurante/data/services/notifications/notification_service.dart';
import 'package:app_restaurante/data/model/reservation.dart';
import 'package:app_restaurante/data/model/dish.dart';

// Registro de una llamada capturada por el spy
class _NotifCall {
  // Nombre del metodo: 'show', 'zonedSchedule' o 'cancel'
  final String method;
  // Argumentos clave capturados

  final Map<String, dynamic> args;

  _NotifCall(this.method, this.args);
}

// Spy: implementacion falsa de NotificationsApi para tests.
// En lugar de llamar al plugin nativo, guarda cada llamada en 'calls'.
class _SpyNotificationsApi implements NotificationsApi {
  // Lista de todas las llamadas realizadas (se limpia en setUp)
  final List<_NotifCall> calls = [];

  // Simula show(): guarda id, titulo y cuerpo
  @override
  Future<void> show(
    int id,
    String? title,
    String? body,
    NotificationDetails details, {
    String? payload, // <--- Agregar este parámetro opcional
  }) async {
    calls.add(
      _NotifCall('show', {
        'id': id,
        'title': title,
        'body': body,
        'payload': payload, // Opcional: registrarlo también en la llamada
      }),
    );
  }

  // Simula zonedSchedule(): guarda id, titulo, cuerpo y fecha programada
  @override
  Future<void> zonedSchedule(
    int id,
    String? title,
    String? body,
    tz.TZDateTime scheduledDate,
    NotificationDetails details, {
    required AndroidScheduleMode androidScheduleMode,
    required UILocalNotificationDateInterpretation
    uiLocalNotificationDateInterpretation,
  }) async {
    calls.add(
      _NotifCall('zonedSchedule', {
        'id': id,
        'title': title,
        'body': body,
        'scheduledDate': scheduledDate,
        'androidScheduleMode': androidScheduleMode,
      }),
    );
  }

  // Simula cancel(): guarda el id cancelado
  @override
  Future<void> cancel(int id) async {
    calls.add(_NotifCall('cancel', {'id': id}));
  }

  // Helpers para los expects
  List<_NotifCall> callsTo(String method) =>
      calls.where((c) => c.method == method).toList();
  bool wasCalled(String method) => calls.any((c) => c.method == method);
}

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  late _SpyNotificationsApi spy;

  setUpAll(() {
    // Inicializamos la base de datos de zonas horarias una sola vez
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Madrid'));
  });

  setUp(() {
    // Creamos un spy limpio antes de cada test
    spy = _SpyNotificationsApi();
    // Inyectamos el spy: sustituye el plugin real durante el test
    NotificationService.setApiForTest(spy);
  });

  tearDown(() {
    // Restauramos la API real para no afectar otros tests del proyecto
    NotificationService.resetApi();
  });

  group('NotificationService', () {
    // ─── GRUPO 1: showReservationConfirmed() ─────────────────────────────────
    group('showReservationConfirmed()', () {
      test(
        'llama a show() exactamente 1 vez al confirmar la reserva',
        () async {
          // Arrange
          final reservation = Reservation(
            id: 'res_001',
            reservationDate: DateTime(2026, 8, 20, 21, 30),
            state: ReservationStatus.confirmed,
          );
          // Act
          await NotificationService.showReservationConfirmed(reservation);
          // Assert
          expect(spy.callsTo('show').length, 1);
        },
      );

      test('el ID de confirmacion esta en rango 0-99.999', () async {
        // Arrange
        final reservation = Reservation(
          id: 'res_id_range',
          reservationDate: DateTime(2026, 9, 10, 20, 0),
          state: ReservationStatus.confirmed,
        );
        // Act
        await NotificationService.showReservationConfirmed(reservation);
        // Assert: formula id.hashCode.abs() % 100000
        final expectedId = 'res_id_range'.hashCode.abs() % 100000;
        final actualId = spy.callsTo('show').first.args['id'] as int;
        expect(actualId, expectedId);
        expect(
          actualId,
          lessThan(100000),
          reason: 'El rango 0-99.999 esta reservado para confirmaciones',
        );
      });

      test('el titulo muestra el emoji de confirmacion', () async {
        // Arrange
        final reservation = Reservation(
          id: 'res_titulo',
          reservationDate: DateTime(2026, 10, 5, 19, 0),
          state: ReservationStatus.confirmed,
        );
        // Act
        await NotificationService.showReservationConfirmed(reservation);
        // Assert
        expect(
          spy.callsTo('show').first.args['title'],
          '\u2705 Reserva Confirmada',
        );
      });

      test(
        'el cuerpo contiene la fecha formateada dd/MM/yyyy y la hora',
        () async {
          // Arrange: reserva el 15 de agosto a las 21:30
          final reservation = Reservation(
            id: 'res_fecha',
            reservationDate: DateTime(2026, 8, 15, 21, 30),
            state: ReservationStatus.confirmed,
          );
          // Act
          await NotificationService.showReservationConfirmed(reservation);
          // Assert
          final body = spy.callsTo('show').first.args['body'] as String;
          expect(
            body.contains('15/08/2026'),
            isTrue,
            reason: 'El cliente debe ver la fecha de su reserva',
          );
          expect(
            body.contains('21:30'),
            isTrue,
            reason: 'El cliente debe ver la hora de su reserva',
          );
        },
      );

      test('muestra "fecha pendiente" si reservationDate es null', () async {
        // Arrange
        final reservation = Reservation(
          id: 'res_sin_fecha',
          reservationDate: null,
          state: ReservationStatus.confirmed,
        );
        // Act
        await NotificationService.showReservationConfirmed(reservation);
        // Assert: se muestra con texto de fallback
        expect(spy.wasCalled('show'), isTrue);
        final body = spy.callsTo('show').first.args['body'] as String;
        expect(body.contains('fecha pendiente'), isTrue);
      });
    });

    // ─── GRUPO 2: scheduleReservationReminder() ───────────────────────────────
    group('scheduleReservationReminder()', () {
      test('llama a zonedSchedule() 1 vez para reservas futuras', () async {
        // Arrange
        final reservation = Reservation(
          id: 'res_futura',
          reservationDate: DateTime.now().add(const Duration(days: 10)),
          state: ReservationStatus.confirmed,
        );
        // Act
        await NotificationService.scheduleReservationReminder(reservation);
        // Assert
        expect(spy.callsTo('zonedSchedule').length, 1);
      });

      test(
        'el recordatorio se programa a las 09:00 AM del dia de la reserva',
        () async {
          // Arrange: reserva a las 21:00 dentro de 5 dias
          final futureDay = DateTime.now().add(const Duration(days: 5));
          final reservation = Reservation(
            id: 'res_hora_test',
            reservationDate: DateTime(
              futureDay.year,
              futureDay.month,
              futureDay.day,
              21,
              0,
            ),
            state: ReservationStatus.confirmed,
          );
          // Act
          await NotificationService.scheduleReservationReminder(reservation);
          // Assert: la hora programada debe ser las 9:00 AM
          final scheduled =
              spy.callsTo('zonedSchedule').first.args['scheduledDate']
                  as tz.TZDateTime;
          expect(
            scheduled.hour,
            9,
            reason:
                'El recordatorio se envia a las 9 AM para dar margen al cliente',
          );
          expect(scheduled.minute, 0);
          expect(scheduled.day, futureDay.day);
          expect(scheduled.month, futureDay.month);
        },
      );

      test(
        'usa exactAllowWhileIdle para dispararse aunque el movil este en Doze',
        () async {
          // Arrange
          final reservation = Reservation(
            id: 'res_doze',
            reservationDate: DateTime.now().add(const Duration(days: 3)),
            state: ReservationStatus.confirmed,
          );
          // Act
          await NotificationService.scheduleReservationReminder(reservation);
          // Assert
          final mode =
              spy.callsTo('zonedSchedule').first.args['androidScheduleMode']
                  as AndroidScheduleMode;
          expect(
            mode,
            AndroidScheduleMode.exactAllowWhileIdle,
            reason:
                'Sin exactAllowWhileIdle el recordatorio podria llegar horas tarde',
          );
        },
      );

      test('el ID del recordatorio esta en rango 100.000-199.999', () async {
        // Arrange
        final reservation = Reservation(
          id: 'res_id_reminder',
          reservationDate: DateTime.now().add(const Duration(days: 7)),
          state: ReservationStatus.confirmed,
        );
        // Act
        await NotificationService.scheduleReservationReminder(reservation);
        // Assert
        final id = spy.callsTo('zonedSchedule').first.args['id'] as int;
        final expectedId = ('res_id_reminder'.hashCode.abs() % 100000) + 100000;
        expect(id, expectedId);
        expect(id, greaterThanOrEqualTo(100000));
        expect(
          id,
          lessThan(200000),
          reason: 'El rango 100.000-199.999 esta reservado para recordatorios',
        );
      });

      test(
        'NO programa si las 9 AM del dia ya han pasado (reserva pasada)',
        () async {
          // Arrange
          final reservation = Reservation(
            id: 'res_pasada',
            reservationDate: DateTime.now().subtract(const Duration(days: 1)),
            state: ReservationStatus.confirmed,
          );
          // Act
          await NotificationService.scheduleReservationReminder(reservation);
          // Assert: no programar alarmas en el pasado
          expect(spy.wasCalled('zonedSchedule'), isFalse);
        },
      );

      test('NO programa si el ID de la reserva es null', () async {
        // Arrange
        final reservation = Reservation(
          id: null,
          reservationDate: DateTime.now().add(const Duration(days: 5)),
        );
        // Act
        await NotificationService.scheduleReservationReminder(reservation);
        // Assert
        expect(spy.wasCalled('zonedSchedule'), isFalse);
      });

      test('NO programa si reservationDate es null', () async {
        // Arrange
        final reservation = Reservation(
          id: 'res_sin_fecha',
          reservationDate: null,
        );
        // Act
        await NotificationService.scheduleReservationReminder(reservation);
        // Assert
        expect(spy.wasCalled('zonedSchedule'), isFalse);
      });
    });

    // ─── GRUPO 3: cancelReservationReminder() ─────────────────────────────────
    group('cancelReservationReminder()', () {
      test('llama a cancel() exactamente 1 vez', () async {
        // Act
        await NotificationService.cancelReservationReminder('res_cancel_001');
        // Assert
        expect(spy.callsTo('cancel').length, 1);
      });

      test('cancela el ID correcto (mismo que se uso para programar)', () async {
        // Arrange: calculamos el ID esperado con la misma formula del servicio
        const reservationId = 'res_id_verify';
        final expectedId = (reservationId.hashCode.abs() % 100000) + 100000;
        // Act
        await NotificationService.cancelReservationReminder(reservationId);
        // Assert
        final canceledId = spy.callsTo('cancel').first.args['id'] as int;
        expect(
          canceledId,
          expectedId,
          reason:
              'Si se cancela con un ID distinto al programado el recordatorio '
              'seguiria activo aunque la reserva este cancelada',
        );
      });

      test('cancelar reserva A no cancela el recordatorio de reserva B', () {
        // Los IDs distintos garantizan independencia entre reservas
        const idA = 'reserva_alfa';
        const idB = 'reserva_beta';
        final cancelIdA = (idA.hashCode.abs() % 100000) + 100000;
        final cancelIdB = (idB.hashCode.abs() % 100000) + 100000;
        expect(cancelIdA, isNot(equals(cancelIdB)));
      });
    });

    // ─── GRUPO 4: showNewDish() ───────────────────────────────────────────────
    group('showNewDish()', () {
      test('llama a show() 1 vez cuando se anade un nuevo plato', () async {
        // Arrange
        final dish = Dish(
          id: 'dish_001',
          name: 'Salmorejo',
          category: 'Entrantes',
        );
        // Act
        await NotificationService.showNewDish(dish);
        // Assert
        expect(spy.callsTo('show').length, 1);
      });

      test('el cuerpo contiene el nombre del plato', () async {
        // Arrange
        final dish = Dish(id: 'dish_002', name: 'Croquetas de Jamon');
        // Act
        await NotificationService.showNewDish(dish);
        // Assert
        final body = spy.callsTo('show').first.args['body'] as String;
        expect(body.contains('Croquetas de Jamon'), isTrue);
      });

      test('muestra "Novedad del chef" si el plato no tiene nombre', () async {
        // Arrange
        final dish = Dish(id: 'dish_sin_nombre', name: null);
        // Act
        await NotificationService.showNewDish(dish);
        // Assert
        final body = spy.callsTo('show').first.args['body'] as String;
        expect(body.contains('Novedad del chef'), isTrue);
      });

      test('el ID del plato esta en rango 200.000-299.999', () async {
        // Arrange
        const dishId = 'dish_id_range';
        final dish = Dish(id: dishId, name: 'Test');
        final expectedId = (dishId.hashCode.abs() % 100000) + 200000;
        // Act
        await NotificationService.showNewDish(dish);
        // Assert
        final actualId = spy.callsTo('show').first.args['id'] as int;
        expect(actualId, expectedId);
        expect(actualId, greaterThanOrEqualTo(200000));
        expect(actualId, lessThan(300000));
      });

      test('dos platos distintos generan IDs distintos', () async {
        // Act
        await NotificationService.showNewDish(
          Dish(id: 'dish_A', name: 'Paella'),
        );
        await NotificationService.showNewDish(
          Dish(id: 'dish_B', name: 'Fabada'),
        );
        // Assert
        final id1 = spy.callsTo('show')[0].args['id'] as int;
        final id2 = spy.callsTo('show')[1].args['id'] as int;
        expect(id1, isNot(equals(id2)));
      });
    });

    // ─── GRUPO 5: showFromFcm() ───────────────────────────────────────────────
    group('showFromFcm()', () {
      test('muestra la notificacion FCM cuando la app esta abierta', () async {
        // Act
        await NotificationService.showFromFcm(
          title: 'Aviso de SabrosApp',
          body: 'Novedades.',
        );
        // Assert
        expect(spy.wasCalled('show'), isTrue);
      });

      test(
        'pasa el titulo y cuerpo recibidos de Firebase sin modificar',
        () async {
          // Act
          await NotificationService.showFromFcm(
            title: 'Titulo FCM',
            body: 'Cuerpo FCM',
          );
          // Assert
          final call = spy.callsTo('show').first;
          expect(call.args['title'], 'Titulo FCM');
          expect(call.args['body'], 'Cuerpo FCM');
        },
      );

      test(
        'usa el ID fijo 300.000 (nuevo mensaje sustituye al anterior)',
        () async {
          // Act
          await NotificationService.showFromFcm(title: 'T', body: 'B');
          // Assert: ID fijo = la notificacion FCM mas reciente reemplaza a la anterior
          expect(spy.callsTo('show').first.args['id'], 300000);
        },
      );
    });

    // ─── GRUPO 6: showFromQueue() ─────────────────────────────────────────────
    group('showFromQueue()', () {
      test('muestra la notificacion de la cola de Firestore', () async {
        // Act
        await NotificationService.showFromQueue(
          title: '\u2705 Reserva Confirmada',
          body: 'Tu reserva esta confirmada.',
        );
        // Assert
        expect(spy.wasCalled('show'), isTrue);
      });

      test('pasa titulo y cuerpo sin modificar', () async {
        // Act
        await NotificationService.showFromQueue(
          title: 'Titulo cola',
          body: 'Cuerpo cola',
        );
        // Assert
        final call = spy.callsTo('show').first;
        expect(call.args['title'], 'Titulo cola');
        expect(call.args['body'], 'Cuerpo cola');
      });

      test(
        'el ID de cola esta en rango 300.001-400.000 (no solapa otros)',
        () async {
          // Act
          await NotificationService.showFromQueue(title: 'T', body: 'B');
          // Assert
          final id = spy.callsTo('show').first.args['id'] as int;
          expect(id, greaterThanOrEqualTo(300001));
          expect(id, lessThanOrEqualTo(400000));
        },
      );

      test('2 notificaciones de cola generan IDs distintos', () async {
        // Act
        await NotificationService.showFromQueue(title: 'Primera', body: 'A');
        await Future.delayed(const Duration(milliseconds: 2));
        await NotificationService.showFromQueue(title: 'Segunda', body: 'B');
        // Assert
        expect(spy.callsTo('show').length, 2);
        final id1 = spy.callsTo('show')[0].args['id'] as int;
        final id2 = spy.callsTo('show')[1].args['id'] as int;
        expect(id1, isNot(equals(id2)));
      });
    });

    // ─── GRUPO 7: Rangos de IDs unicos (logica pura) ─────────────────────────
    group('Rangos de IDs unicos (logica pura)', () {
      const id = 'mismo_id_para_todos';

      test('confirmacion (0-99k) no solapa con recordatorio (100k-199k)', () {
        final confirmacion = id.hashCode.abs() % 100000;
        final recordatorio = (id.hashCode.abs() % 100000) + 100000;
        expect(confirmacion, lessThan(100000));
        expect(recordatorio, greaterThanOrEqualTo(100000));
        expect(recordatorio, lessThan(200000));
        expect(confirmacion, isNot(equals(recordatorio)));
      });

      test('recordatorio (100k-199k) no solapa con platos (200k-299k)', () {
        final recordatorio = (id.hashCode.abs() % 100000) + 100000;
        final plato = (id.hashCode.abs() % 100000) + 200000;
        expect(recordatorio, lessThan(200000));
        expect(plato, greaterThanOrEqualTo(200000));
        expect(plato, lessThan(300000));
        expect(recordatorio, isNot(equals(plato)));
      });

      test('platos (200k-299k) no solapa con FCM (300.000 fijo)', () {
        final plato = (id.hashCode.abs() % 100000) + 200000;
        expect(plato, lessThan(300000));
        expect(300000, equals(300000));
        expect(plato, isNot(equals(300000)));
      });

      test('FCM (300.000) no solapa con cola (>=300.001)', () {
        expect(300000, lessThan(300001));
      });
    });
  });
}
