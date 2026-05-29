import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';

import 'package:app_restaurante/data/model/dish.dart';
import 'package:app_restaurante/data/model/reservation.dart';

// Tipo de callback para manejar navegación cuando se hace click en una notificación
typedef NotificationTapCallback = void Function(String? reservationId);

// Servicio central de notificaciones locales para SabrosApp.

abstract class NotificationsApi {
  Future<void> show(
    int id,
    String? title,
    String? body,
    NotificationDetails details, {
    String? payload,
  });

  Future<void> zonedSchedule(
    int id,
    String? title,
    String? body,
    tz.TZDateTime scheduledDate,
    NotificationDetails details, {
    required AndroidScheduleMode androidScheduleMode,
    required UILocalNotificationDateInterpretation
    uiLocalNotificationDateInterpretation,
  });

  Future<void> cancel(int id);
}

class _RealNotificationsApi implements NotificationsApi {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  @override
  Future<void> show(id, title, body, details, {payload}) =>
      _plugin.show(id, title, body, details, payload: payload);

  @override
  Future<void> zonedSchedule(
    id,
    title,
    body,
    scheduledDate,
    details, {
    required androidScheduleMode,
    required uiLocalNotificationDateInterpretation,
  }) => _plugin.zonedSchedule(
    id,
    title,
    body,
    scheduledDate,
    details,
    androidScheduleMode: androidScheduleMode,
    uiLocalNotificationDateInterpretation:
        uiLocalNotificationDateInterpretation,
  );

  @override
  Future<void> cancel(int id) => _plugin.cancel(id);
}

// ─────────────────────────────────────────────────────────────────────────────

class NotificationService {
  static NotificationsApi _api = _RealNotificationsApi();

  @visibleForTesting
  static void setApiForTest(NotificationsApi api) {
    _api = api;
  }

  @visibleForTesting
  static void resetApi() {
    _api = _RealNotificationsApi();
  }

  static final FlutterLocalNotificationsPlugin _initPlugin =
      FlutterLocalNotificationsPlugin();

  // ─── Callback para navegación cuando se hace click en notificación ────────
  static NotificationTapCallback? _onNotificationTap;

  static void setNavigationCallback(NotificationTapCallback callback) {
    _onNotificationTap = callback;
  }

  // ─── Canales de Android ──────────────────────────────────────────────────

  static const String _reservationChannelId = 'reservations';
  static const String _reservationChannelName = 'Reservas';

  static const String _dishesChannelId = 'dishes';
  static const String _dishesChannelName = 'Nuevos Platos';

  // ─── Inicialización ──────────────────────────────────────────────────────

  static Future<void> init() async {
    tz_data.initializeTimeZones();

    final timezoneInfo = await FlutterTimezone.getLocalTimezone();

    tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: iosSettings,
    );

    await _initPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        onNotificationTapped(response.payload);
      },
    );

    _initPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    await _initPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  // ─── 1. Reserva confirmada ───────────────────────────────────────────────

  static Future<void> showReservationConfirmed(Reservation reservation) async {
    final date = reservation.reservationDate;
    final dateStr = date != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(date)
        : 'fecha pendiente';

    await _api.show(
      _reservationNotificationId(reservation.id ?? ''),
      '✅ Reserva Confirmada',
      'Tu reserva para el $dateStr ha sido confirmada. ¡Te esperamos!',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _reservationChannelId,
          _reservationChannelName,
          channelDescription: 'Notificaciones sobre el estado de tus reservas',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        macOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  // ─── 2. Recordatorio del día de la reserva ───────────────────────────────

  static Future<void> scheduleReservationReminder(
    Reservation reservation,
  ) async {
    final date = reservation.reservationDate;

    if (date == null || reservation.id == null) return;

    final reminderDateTime = tz.TZDateTime(
      tz.local,
      date.year,
      date.month,
      date.day,
      9,
      0,
    );

    if (reminderDateTime.isBefore(tz.TZDateTime.now(tz.local))) return;

    final timeStr = DateFormat('HH:mm').format(date);

    await _api.zonedSchedule(
      _reservationReminderNotificationId(reservation.id!),
      '🍽️ Recordatorio de Reserva',
      'Hoy tienes una reserva a las $timeStr. ¡Que lo disfrutes!',
      reminderDateTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _reservationChannelId,
          _reservationChannelName,
          channelDescription: 'Recordatorio del día de tu reserva',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        macOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelReservationReminder(String reservationId) async {
    await _api.cancel(_reservationReminderNotificationId(reservationId));
  }

  // ─── 3. Nuevo plato en carta ─────────────────────────────────────────────

  // Muestra una notificación cuando el restaurante añade un nuevo plato.
  static Future<void> showNewDish(Dish dish) async {
    await _api.show(
      _dishNotificationId(dish.id ?? ''),
      '🆕 ¡Nuevo Plato en Carta!',
      'Descubre nuestro nuevo plato: ${dish.name ?? 'Novedad del chef'}. ¡No te lo pierdas!',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _dishesChannelId,
          _dishesChannelName,
          channelDescription: 'Avisos cuando se añaden nuevos platos al menú',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/launcher_icon',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        macOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  // ─── Helpers: conversión de ID String → int ──────────────────────────────

  static int _reservationNotificationId(String id) =>
      id.hashCode.abs() % 100000;

  static int _reservationReminderNotificationId(String id) =>
      (id.hashCode.abs() % 100000) + 100000;

  static int _dishNotificationId(String id) =>
      (id.hashCode.abs() % 100000) + 200000;

  // ─── 4. Notificaciones desde FCM (app en primer plano) ───────────────────

  static Future<void> showFromFcm({
    required String title,
    required String body,
  }) async {
    await _api.show(
      300000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _reservationChannelId,
          _reservationChannelName,
          channelDescription: 'Notificaciones push de SabrosApp',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        macOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  // ─── 5. Notificaciones desde la cola de Firestore ─────────────────────────

  static Future<void> showFromQueue({
    required String title,
    required String body,
    String? type,
    String? reservationId,
  }) async {
    final int notificationId =
        (DateTime.now().millisecondsSinceEpoch % 100000) + 300001;

    await _api.show(
      notificationId,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _reservationChannelId,
          _reservationChannelName,
          channelDescription: 'Notificaciones push de SabrosApp',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        macOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: reservationId,
    );
  }

  static void onNotificationTapped(String? payload) {
    if (_onNotificationTap != null && payload != null && payload.isNotEmpty) {
      _onNotificationTap!(payload);
    }
  }
}
