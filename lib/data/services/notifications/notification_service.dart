// Servicio central de notificaciones locales para SabrosApp.
// Maneja tres tipos de notificaciones:
//   1. Reserva confirmada  → notificación inmediata cuando el admin confirma
//   2. Recordatorio del día → programada a las 9:00 AM del día de la reserva
//   3. Nuevo plato en carta → cuando el restaurante añade un plato nuevo

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

// ─── Capa de abstracción del plugin ─────────────────────────────────────────
// FlutterLocalNotificationsPlugin es un singleton con constructor privado;
// no se puede instanciar en tests sin el entorno nativo Android/iOS.
// Definimos esta interfaz para que los tests puedan inyectar un "spy"
// que registre las llamadas sin necesitar hardware real.

/// Contrato de las 3 operaciones que NotificationService necesita del plugin.
/// La implementación real usa FlutterLocalNotificationsPlugin.
/// Los tests inyectan una implementación falsa (spy) a través de [setApiForTest].
abstract class NotificationsApi {
  // Muestra una notificación inmediata
  Future<void> show(
    int id,
    String? title,
    String? body,
    NotificationDetails details, {
    String? payload,
  });

  // Programa una notificación para una fecha y hora exacta
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

  // Cancela una notificación programada por su ID
  Future<void> cancel(int id);
}

// Implementación real que delega en el plugin de Flutter
class _RealNotificationsApi implements NotificationsApi {
  // Instancia singleton del plugin (solo hay una en toda la app)
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
  // API activa: en producción usa el plugin real; en tests lo sustituimos
  static NotificationsApi _api = _RealNotificationsApi();

  /// Solo para tests: inyecta una implementación alternativa (spy/fake).
  /// No llamar desde código de producción.
  @visibleForTesting
  static void setApiForTest(NotificationsApi api) {
    _api = api;
  }

  /// Restaura la implementación real tras los tests.
  @visibleForTesting
  static void resetApi() {
    _api = _RealNotificationsApi();
  }

  // ─── Referencia al plugin para init() (necesita inicializar canales) ─────
  // init() necesita acceso directo al plugin para configurar los canales y
  // pedir permisos; no pasa por _api para no complicar la interfaz.
  static final FlutterLocalNotificationsPlugin _initPlugin =
      FlutterLocalNotificationsPlugin();

  // ─── Callback para navegación cuando se hace click en notificación ────────
  static NotificationTapCallback? _onNotificationTap;

  /// Establece el callback que se ejecutará cuando el usuario haga click
  /// en una notificación. Se utiliza para navegar a la reserva confirmada.
  static void setNavigationCallback(NotificationTapCallback callback) {
    _onNotificationTap = callback;
  }

  // ─── Canales de Android ──────────────────────────────────────────────────
  // Android agrupa las notificaciones en "canales"; el usuario puede silenciar
  // cada canal de forma independiente desde los ajustes del sistema.

  // Canal exclusivo para avisos relacionados con reservas
  static const String _reservationChannelId = 'reservations';
  static const String _reservationChannelName = 'Reservas';

  // Canal exclusivo para avisos de nuevos platos en la carta
  static const String _dishesChannelId = 'dishes';
  static const String _dishesChannelName = 'Nuevos Platos';

  // ─── Inicialización ──────────────────────────────────────────────────────

  /// Llama a este método UNA SOLA VEZ al arrancar la app (en main.dart).
  /// Configura la zona horaria del dispositivo e inicializa el plugin.
  static Future<void> init() async {
    // Cargamos todas las zonas horarias disponibles en el paquete timezone
    tz_data.initializeTimeZones();

    // En flutter_timezone 5.x getLocalTimezone() devuelve un TimezoneInfo.
    // Usamos .identifier para obtener el nombre IANA (ej: "Europe/Madrid")
    final timezoneInfo = await FlutterTimezone.getLocalTimezone();

    // Configuramos la zona horaria local para que las notificaciones
    // programadas usen la hora del dispositivo y no UTC
    tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));

    // Configuración de Android: usamos el icono del lanzador de la app
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuración de iOS/macOS: pedimos permisos de alerta, badge y sonido
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    // Unimos la configuración de ambas plataformas
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: iosSettings,
    );

    // Inicializamos el plugin con la configuración anterior
    await _initPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Se ejecuta cuando el usuario hace click en una notificación
        onNotificationTapped(response.payload);
      },
    );

    // Configuramos permisos de notificación
    _initPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    // En iOS también pedimos permiso para mostrar alertas y reproducir sonido
    await _initPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  // ─── 1. Reserva confirmada ───────────────────────────────────────────────

  /// Muestra una notificación inmediata cuando el estado pasa a "confirmed".
  /// Se llama desde ReservationViewModel al detectar el cambio en el stream.
  static Future<void> showReservationConfirmed(Reservation reservation) async {
    // Formateamos la fecha de la reserva para mostrarla en el mensaje
    final date = reservation.reservationDate;
    final dateStr = date != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(date)
        : 'fecha pendiente';

    // Delegamos en _api (real en producción, spy en tests)
    await _api.show(
      // ID único de la notificación (convertimos el String de Firestore a int)
      _reservationNotificationId(reservation.id ?? ''),
      // Título de la notificación
      '✅ Reserva Confirmada',
      // Cuerpo del mensaje con la fecha formateada
      'Tu reserva para el $dateStr ha sido confirmada. ¡Te esperamos!',
      // Detalles específicos de cada plataforma
      NotificationDetails(
        android: AndroidNotificationDetails(
          _reservationChannelId,
          _reservationChannelName,
          // Descripción que aparece en los ajustes del sistema
          channelDescription: 'Notificaciones sobre el estado de tus reservas',
          // Alta importancia → aparece como heads-up (emergente) en pantalla
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
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

  /// Programa una notificación para las 09:00 AM del día de la reserva.
  /// Se cancela automáticamente si la reserva se cancela.
  static Future<void> scheduleReservationReminder(
    Reservation reservation,
  ) async {
    final date = reservation.reservationDate;

    // Si no hay fecha o ID no podemos programar nada
    if (date == null || reservation.id == null) return;

    // Construimos el momento exacto: 09:00 AM del día de la reserva
    // usando la zona horaria local del dispositivo
    final reminderDateTime = tz.TZDateTime(
      tz.local, // zona horaria local (ej: Europe/Madrid)
      date.year,
      date.month,
      date.day,
      9, // hora: 9 AM
      0, // minutos: 0
    );

    // Si el momento ya pasó (reserva de ayer, por ejemplo), no programamos
    if (reminderDateTime.isBefore(tz.TZDateTime.now(tz.local))) return;

    // Formateamos solo la hora de la reserva para el mensaje
    final timeStr = DateFormat('HH:mm').format(date);

    // Delegamos en _api el almacenado real de la notificación programada
    await _api.zonedSchedule(
      // ID único para este recordatorio (rango diferente al de confirmación)
      _reservationReminderNotificationId(reservation.id!),
      // Título del recordatorio
      '🍽️ Recordatorio de Reserva',
      // Mensaje con la hora concreta de la reserva
      'Hoy tienes una reserva a las $timeStr. ¡Que lo disfrutes!',
      // Fecha y hora programadas en la zona horaria local
      reminderDateTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _reservationChannelId,
          _reservationChannelName,
          channelDescription: 'Recordatorio del día de tu reserva',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
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
      // exactAllowWhileIdle: la notificación se dispara a la hora exacta
      // incluso si el dispositivo está en modo reposo (Doze)
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      // En iOS indicamos que la hora se interpreta en la zona horaria local
      // del dispositivo (no en UTC), para que el recordatorio sea preciso
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Cancela el recordatorio programado para una reserva concreta.
  /// Se llama cuando el usuario o el admin cancela la reserva.
  static Future<void> cancelReservationReminder(String reservationId) async {
    // Cancelamos la notificación usando el mismo ID con el que fue creada
    await _api.cancel(_reservationReminderNotificationId(reservationId));
  }

  // ─── 3. Nuevo plato en carta ─────────────────────────────────────────────

  /// Muestra una notificación cuando el restaurante añade un nuevo plato.
  /// Se llama desde DishViewModel al detectar un ID nuevo en el stream.
  static Future<void> showNewDish(Dish dish) async {
    await _api.show(
      // ID único basado en el ID del plato en Firestore
      _dishNotificationId(dish.id ?? ''),
      // Título llamativo para atraer la atención del cliente
      '🆕 ¡Nuevo Plato en Carta!',
      // Mostramos el nombre del plato en el mensaje
      'Descubre nuestro nuevo plato: ${dish.name ?? 'Novedad del chef'}. ¡No te lo pierdas!',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _dishesChannelId,
          _dishesChannelName,
          channelDescription: 'Avisos cuando se añaden nuevos platos al menú',
          // Importancia normal: no interrumpe, aparece en la barra de estado
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
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
  // Las notificaciones de Flutter usan int como ID.
  // Usamos hashCode con módulo para convertir los IDs de Firestore (String)
  // a enteros únicos sin colisiones entre los tres rangos:
  //   · 0 - 99.999   → notificación de confirmación de reserva
  //   · 100.000 - 199.999 → recordatorio del día de la reserva
  //   · 200.000 - 299.999 → notificación de nuevo plato
  //   · 300.000+          → notificaciones de FCM y cola de Firestore

  // ID para la notificación de "reserva confirmada"
  static int _reservationNotificationId(String id) =>
      id.hashCode.abs() % 100000;

  // ID para el recordatorio programado del día de la reserva
  static int _reservationReminderNotificationId(String id) =>
      (id.hashCode.abs() % 100000) + 100000;

  // ID para la notificación de nuevo plato
  static int _dishNotificationId(String id) =>
      (id.hashCode.abs() % 100000) + 200000;

  // ─── 4. Notificaciones desde FCM (app en primer plano) ───────────────────

  /// Se llama desde FcmService cuando llega un mensaje FCM con la app ABIERTA.
  /// En primer plano, FCM NO muestra la notificación automáticamente,
  /// así que la mostramos nosotros con flutter_local_notifications.
  static Future<void> showFromFcm({
    required String title,
    required String body,
  }) async {
    // Usamos un ID fijo para FCM; si llegan varias sustituyen a la anterior
    // (comportamiento esperado: la más reciente es la que importa)
    await _api.show(
      // ID fijo en el rango reservado para FCM
      300000,
      // Título y cuerpo vienen directamente del mensaje de Firebase
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          // Reutilizamos el canal de reservas para unificar ajustes del usuario
          _reservationChannelId,
          _reservationChannelName,
          channelDescription: 'Notificaciones push de SabrosApp',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
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

  /// Se llama desde FcmService cuando aparece un nuevo documento en
  /// la colección "notification_queue" en Firestore.
  /// Funciona en primer plano Y en segundo plano (stream activo).
  static Future<void> showFromQueue({
    required String title,
    required String body,
    String? type,
    String? reservationId,
  }) async {
    // Generamos un ID único basado en el tiempo para evitar colisiones
    // cuando llegan varias notificaciones de cola en poco tiempo
    final int notificationId =
        (DateTime.now().millisecondsSinceEpoch % 100000) + 300001;

    await _api.show(
      notificationId,
      // Título y cuerpo vienen del documento de Firestore (escritos por el admin)
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _reservationChannelId,
          _reservationChannelName,
          channelDescription: 'Notificaciones push de SabrosApp',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
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

  /// Se llama cuando el usuario hace click en una notificación.
  /// El payload contiene el ID de la reserva, que usamos para navegar.
  static void onNotificationTapped(String? payload) {
    // Solo procesamos si hay un callback configurado
    if (_onNotificationTap != null && payload != null && payload.isNotEmpty) {
      // Llamamos el callback con el ID de la reserva para que navegue
      _onNotificationTap!(payload);
    }
  }
}
