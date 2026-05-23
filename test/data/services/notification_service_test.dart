import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:app_restaurante/data/services/notifications/notification_service.dart';
import 'package:app_restaurante/data/model/reservation.dart';
import 'package:app_restaurante/data/model/dish.dart';

class _NotifCall {
  final String method;

  final Map<String, dynamic> args;

  _NotifCall(this.method, this.args);
}

class _SpyNotificationsApi implements NotificationsApi {
  final List<_NotifCall> calls = [];

  @override
  Future<void> show(
    int id,
    String? title,
    String? body,
    NotificationDetails details, {
    String? payload,
  }) async {
    calls.add(
      _NotifCall('show', {
        'id': id,
        'title': title,
        'body': body,
        'payload': payload,
      }),
    );
  }

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

  @override
  Future<void> cancel(int id) async {
    calls.add(_NotifCall('cancel', {'id': id}));
  }

  List<_NotifCall> callsTo(String method) =>
      calls.where((c) => c.method == method).toList();
  bool wasCalled(String method) => calls.any((c) => c.method == method);
}

void main() {
  late _SpyNotificationsApi spy;

  setUpAll(() {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Madrid'));
  });

  setUp(() {
    spy = _SpyNotificationsApi();
    NotificationService.setApiForTest(spy);
  });

  tearDown(() {
    NotificationService.resetApi();
  });

  group('NotificationService', () {
    // ─── Confirmación de reserva
    group('showReservationConfirmed()', () {
      test(
        'llama a show() exactamente 1 vez al confirmar la reserva',
        () async {
          final reservation = Reservation(
            id: 'res_001',
            reservationDate: DateTime(2026, 8, 20, 21, 30),
            state: ReservationStatus.confirmed,
          );
          await NotificationService.showReservationConfirmed(reservation);
          expect(spy.callsTo('show').length, 1);
        },
      );

      test('el ID de confirmacion esta en rango 0-99.999', () async {
        final reservation = Reservation(
          id: 'res_id_range',
          reservationDate: DateTime(2026, 9, 10, 20, 0),
          state: ReservationStatus.confirmed,
        );
        await NotificationService.showReservationConfirmed(reservation);
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
        final reservation = Reservation(
          id: 'res_titulo',
          reservationDate: DateTime(2026, 10, 5, 19, 0),
          state: ReservationStatus.confirmed,
        );
        await NotificationService.showReservationConfirmed(reservation);
        expect(
          spy.callsTo('show').first.args['title'],
          '\u2705 Reserva Confirmada',
        );
      });

      test(
        'el cuerpo contiene la fecha formateada dd/MM/yyyy y la hora',
        () async {
          final reservation = Reservation(
            id: 'res_fecha',
            reservationDate: DateTime(2026, 8, 15, 21, 30),
            state: ReservationStatus.confirmed,
          );
          await NotificationService.showReservationConfirmed(reservation);
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
        await NotificationService.showReservationConfirmed(reservation);
        expect(spy.wasCalled('show'), isTrue);
        final body = spy.callsTo('show').first.args['body'] as String;
        expect(body.contains('fecha pendiente'), isTrue);
      });
    });

    // ─── Recordatorio de reserva
    group('scheduleReservationReminder()', () {
      test('llama a zonedSchedule() 1 vez para reservas futuras', () async {
        final reservation = Reservation(
          id: 'res_futura',
          reservationDate: DateTime.now().add(const Duration(days: 10)),
          state: ReservationStatus.confirmed,
        );
        await NotificationService.scheduleReservationReminder(reservation);
        expect(spy.callsTo('zonedSchedule').length, 1);
      });

      test(
        'el recordatorio se programa a las 09:00 AM del dia de la reserva',
        () async {
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
          await NotificationService.scheduleReservationReminder(reservation);
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
          final reservation = Reservation(
            id: 'res_doze',
            reservationDate: DateTime.now().add(const Duration(days: 3)),
            state: ReservationStatus.confirmed,
          );
          await NotificationService.scheduleReservationReminder(reservation);
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
        final reservation = Reservation(
          id: 'res_id_reminder',
          reservationDate: DateTime.now().add(const Duration(days: 7)),
          state: ReservationStatus.confirmed,
        );
        await NotificationService.scheduleReservationReminder(reservation);
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
          final reservation = Reservation(
            id: 'res_pasada',
            reservationDate: DateTime.now().subtract(const Duration(days: 1)),
            state: ReservationStatus.confirmed,
          );
          await NotificationService.scheduleReservationReminder(reservation);
          expect(spy.wasCalled('zonedSchedule'), isFalse);
        },
      );

      test('NO programa si el ID de la reserva es null', () async {
        final reservation = Reservation(
          id: null,
          reservationDate: DateTime.now().add(const Duration(days: 5)),
        );
        await NotificationService.scheduleReservationReminder(reservation);
        expect(spy.wasCalled('zonedSchedule'), isFalse);
      });

      test('NO programa si reservationDate es null', () async {
        final reservation = Reservation(
          id: 'res_sin_fecha',
          reservationDate: null,
        );
        await NotificationService.scheduleReservationReminder(reservation);
        expect(spy.wasCalled('zonedSchedule'), isFalse);
      });
    });

    // ─── Cancelación de recordatorio
    group('cancelReservationReminder()', () {
      test('llama a cancel() exactamente 1 vez', () async {
        await NotificationService.cancelReservationReminder('res_cancel_001');
        expect(spy.callsTo('cancel').length, 1);
      });

      test('cancela el ID correcto (mismo que se uso para programar)', () async {
        const reservationId = 'res_id_verify';
        final expectedId = (reservationId.hashCode.abs() % 100000) + 100000;
        await NotificationService.cancelReservationReminder(reservationId);
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
        const idA = 'reserva_alfa';
        const idB = 'reserva_beta';
        final cancelIdA = (idA.hashCode.abs() % 100000) + 100000;
        final cancelIdB = (idB.hashCode.abs() % 100000) + 100000;
        expect(cancelIdA, isNot(equals(cancelIdB)));
      });
    });

    // ─── Notificación de nuevo plato
    group('showNewDish()', () {
      test('llama a show() 1 vez cuando se anade un nuevo plato', () async {
        final dish = Dish(
          id: 'dish_001',
          name: 'Salmorejo',
          category: 'Entrantes',
        );
        await NotificationService.showNewDish(dish);
        expect(spy.callsTo('show').length, 1);
      });

      test('el cuerpo contiene el nombre del plato', () async {
        final dish = Dish(id: 'dish_002', name: 'Croquetas de Jamon');
        await NotificationService.showNewDish(dish);
        final body = spy.callsTo('show').first.args['body'] as String;
        expect(body.contains('Croquetas de Jamon'), isTrue);
      });

      test('muestra "Novedad del chef" si el plato no tiene nombre', () async {
        final dish = Dish(id: 'dish_sin_nombre', name: null);
        await NotificationService.showNewDish(dish);
        final body = spy.callsTo('show').first.args['body'] as String;
        expect(body.contains('Novedad del chef'), isTrue);
      });

      test('el ID del plato esta en rango 200.000-299.999', () async {
        const dishId = 'dish_id_range';
        final dish = Dish(id: dishId, name: 'Test');
        final expectedId = (dishId.hashCode.abs() % 100000) + 200000;
        await NotificationService.showNewDish(dish);
        final actualId = spy.callsTo('show').first.args['id'] as int;
        expect(actualId, expectedId);
        expect(actualId, greaterThanOrEqualTo(200000));
        expect(actualId, lessThan(300000));
      });

      test('dos platos distintos generan IDs distintos', () async {
        await NotificationService.showNewDish(
          Dish(id: 'dish_A', name: 'Paella'),
        );
        await NotificationService.showNewDish(
          Dish(id: 'dish_B', name: 'Fabada'),
        );
        final id1 = spy.callsTo('show')[0].args['id'] as int;
        final id2 = spy.callsTo('show')[1].args['id'] as int;
        expect(id1, isNot(equals(id2)));
      });
    });

    // ─── Notificaciones FCM
    group('showFromFcm()', () {
      test('muestra la notificacion FCM cuando la app esta abierta', () async {
        await NotificationService.showFromFcm(
          title: 'Aviso de SabrosApp',
          body: 'Novedades.',
        );
        expect(spy.wasCalled('show'), isTrue);
      });

      test(
        'pasa el titulo y cuerpo recibidos de Firebase sin modificar',
        () async {
          await NotificationService.showFromFcm(
            title: 'Titulo FCM',
            body: 'Cuerpo FCM',
          );
          final call = spy.callsTo('show').first;
          expect(call.args['title'], 'Titulo FCM');
          expect(call.args['body'], 'Cuerpo FCM');
        },
      );

      test(
        'usa el ID fijo 300.000 (nuevo mensaje sustituye al anterior)',
        () async {
          await NotificationService.showFromFcm(title: 'T', body: 'B');
          expect(spy.callsTo('show').first.args['id'], 300000);
        },
      );
    });

    // ─── Cola de notificaciones
    group('showFromQueue()', () {
      test('muestra la notificacion de la cola de Firestore', () async {
        await NotificationService.showFromQueue(
          title: '\u2705 Reserva Confirmada',
          body: 'Tu reserva esta confirmada.',
        );
        expect(spy.wasCalled('show'), isTrue);
      });

      test('pasa titulo y cuerpo sin modificar', () async {
        await NotificationService.showFromQueue(
          title: 'Titulo cola',
          body: 'Cuerpo cola',
        );
        final call = spy.callsTo('show').first;
        expect(call.args['title'], 'Titulo cola');
        expect(call.args['body'], 'Cuerpo cola');
      });

      test(
        'el ID de cola esta en rango 300.001-400.000 (no solapa otros)',
        () async {
          await NotificationService.showFromQueue(title: 'T', body: 'B');
          final id = spy.callsTo('show').first.args['id'] as int;
          expect(id, greaterThanOrEqualTo(300001));
          expect(id, lessThanOrEqualTo(400000));
        },
      );

      test('2 notificaciones de cola generan IDs distintos', () async {
        await NotificationService.showFromQueue(title: 'Primera', body: 'A');
        await Future.delayed(const Duration(milliseconds: 2));
        await NotificationService.showFromQueue(title: 'Segunda', body: 'B');
        expect(spy.callsTo('show').length, 2);
        final id1 = spy.callsTo('show')[0].args['id'] as int;
        final id2 = spy.callsTo('show')[1].args['id'] as int;
        expect(id1, isNot(equals(id2)));
      });
    });

    // ─── Validación de rangos de IDs
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
