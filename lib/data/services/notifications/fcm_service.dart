// Servicio de Firebase Cloud Messaging (FCM) para SabrosApp.
//
// ¿Cómo funciona el sistema de notificaciones push GRATUITO?
// ─────────────────────────────────────────────────────────────
//  Sin Cloud Functions (de pago), usamos Firestore como "buzón de notificaciones":
//
//  Admin confirma reserva
//          │
//          ▼
//  Escribimos en Firestore → colección "notification_queue"
//          │
//          ├─ App en PRIMER PLANO   → stream de Firestore lo detecta al instante
//          ├─ App en SEGUNDO PLANO  → stream sigue activo  → local notification
//          └─ App CERRADA           → al re-abrir la app   → se procesa la cola
//
//  FCM se usa para:
//   • Recibir notificaciones enviadas manualmente desde Firebase Console (tests)
//   • Mostrar local notifications cuando llega un mensaje FCM con la app abierta
//   • En el futuro: si se añade un backend barato (Railway, Render free tier)
//     podría enviar push con app cerrada automáticamente

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'notification_service.dart';

// ─── Handler de mensajes con app CERRADA (isolate de background) ─────────────
// IMPORTANTE: esta función DEBE estar a nivel de archivo (fuera de la clase).
// Se ejecuta en un isolate separado cuando llega un FCM con la app terminada.
// La anotación @pragma es obligatoria para que el compilador de Flutter
// no la elimine en el proceso de tree-shaking (optimización del compilador).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase ya muestra la notificación push automáticamente si el mensaje
  // tiene un campo "notification". Esta función es útil para mensajes
  // "data-only" (solo datos, sin título/cuerpo), que necesitan ser procesados.
  // Para el proyecto no hacemos nada aquí, pero el handler DEBE existir
  // para que FCM funcione correctamente en Android cuando la app está cerrada.
}

// ─── Clase principal del servicio ────────────────────────────────────────────
class FcmService {
  // Instancia de Firebase Messaging
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  // Referencia a Firestore para leer y escribir la cola de notificaciones
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Suscripción al stream de la cola de notificaciones del usuario actual
  static StreamSubscription? _queueSubscription;

  // ─── Inicialización (llamar una vez al arrancar la app) ───────────────────

  /// Registra el handler de background y configura los listeners de FCM.
  /// Se llama en main.dart ANTES de runApp().
  static Future<void> init() async {
    // Registramos el handler para mensajes con app cerrada (DEBE ir primero)
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Pedimos permiso al usuario para recibir notificaciones push.
    // En Android 13+ esto muestra un diálogo al usuario.
    // En iOS siempre muestra el diálogo.
    await _fcm.requestPermission(
      alert: true, // Mostrar alerta
      badge: true, // Mostrar badge (número) en el icono de la app
      sound: true, // Reproducir sonido
      provisional: false, // Pedir permiso definitivo (no provisional)
    );

    // Escuchamos mensajes FCM cuando la app está en PRIMER PLANO.
    // (En background/cerrada, Android los muestra automáticamente en la bandeja)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      // Solo actuamos si el mensaje tiene título y/o cuerpo
      if (notification != null) {
        // Como la app está en primer plano, FCM NO muestra nada visualmente.
        // Lo mostramos nosotros como notificación local.
        NotificationService.showFromFcm(
          title: notification.title ?? 'SabrosApp',
          body: notification.body ?? '',
        );
      }
    });
  }

  // ─── Gestión del token FCM ────────────────────────────────────────────────

  /// Obtiene el token FCM del dispositivo y lo guarda en el documento
  /// del usuario en Firestore. Este token identifica este dispositivo
  /// para poder enviarle notificaciones push directas.
  static Future<void> saveUserToken(String userId) async {
    // Obtenemos el token único de este dispositivo para FCM
    final String? token = await _fcm.getToken();
    if (token == null) return;

    // Guardamos el token en el perfil del usuario en Firestore.
    // SetOptions(merge: true) asegura que no sobreescribimos otros campos.
    await _db.collection('users').doc(userId).set({
      // El token es necesario si en el futuro se añade un backend para enviar push
      'fcmToken': token,
      // Guardamos cuándo se actualizó para detectar tokens expirados (90 días)
      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // FCM puede regenerar el token en cualquier momento.
    // Nos suscribimos para actualizarlo en Firestore automáticamente.
    _fcm.onTokenRefresh.listen((String newToken) async {
      await _db.collection('users').doc(userId).set({
        'fcmToken': newToken,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  // ─── Cola de notificaciones en Firestore ─────────────────────────────────
  //
  // La colección "notification_queue" en Firestore actúa como buzón:
  // • El admin (o la lógica del servidor) escribe documentos en ella.
  // • El dispositivo del cliente los lee y muestra como notificación local.
  // • Funciona en foreground Y background (Firestore streams son persistentes).
  //
  // Estructura de cada documento en "notification_queue":
  // {
  //   toUserId: "uid_del_destinatario",
  //   title:    "✅ Reserva Confirmada",
  //   body:     "Tu reserva para el 15/05 ha sido confirmada.",
  //   type:     "reservation_confirmed" | "reservation_cancelled" | "new_dish",
  //   isRead:   false,
  //   createdAt: Timestamp
  // }

  /// Empieza a escuchar la cola de notificaciones de este usuario.
  /// Llama a este método cuando el usuario inicia sesión.
  static void listenToNotificationQueue(String userId) {
    // Cancelamos cualquier suscripción anterior para evitar duplicados
    _queueSubscription?.cancel();

    _queueSubscription = _db
        .collection('notification_queue')
        // Solo documentos dirigidos a este usuario
        .where('toUserId', isEqualTo: userId)
        // Solo los no leídos (evitamos mostrar la misma notificación dos veces)
        .where('isRead', isEqualTo: false)
        // Más recientes primero (por si hay varias acumuladas)
        .orderBy('createdAt', descending: true)
        // Máximo 20 a la vez para no saturar
        .limit(20)
        .snapshots()
        .listen((QuerySnapshot snapshot) {
          for (final DocumentChange change in snapshot.docChanges) {
            // Solo procesamos documentos RECIÉN AÑADIDOS.
            // DocumentChangeType.modified y .removed los ignoramos.
            if (change.type == DocumentChangeType.added) {
              final Map<String, dynamic> data =
                  change.doc.data() as Map<String, dynamic>;

              // Mostramos la notificación local con el contenido de Firestore
              NotificationService.showFromQueue(
                title: data['title'] as String? ?? 'SabrosApp',
                body: data['body'] as String? ?? '',
              );

              // Marcamos como leída para no volver a mostrarla en la próxima sesión
              change.doc.reference.update({'isRead': true});
            }
          }
        });
  }

  /// Para de escuchar la cola. Llama a este método cuando el usuario cierra sesión.
  static void stopListening() {
    _queueSubscription?.cancel();
    _queueSubscription = null;
  }

  // ─── Escritura en la cola (lado del admin) ────────────────────────────────

  /// Añade una notificación a la cola de Firestore para un usuario concreto.
  /// El destinatario la recibirá:
  ///   • Instantáneamente si tiene la app abierta o en background
  ///   • La próxima vez que abra la app si la tenía cerrada
  static Future<void> enqueueForUser({
    required String toUserId,
    required String title,
    required String body,
    // Tipo para identificar la notificación (útil para navegación futura)
    required String type,
  }) async {
    await _db.collection('notification_queue').add({
      // ID del usuario que va a recibir la notificación
      'toUserId': toUserId,
      // Contenido visible de la notificación
      'title': title,
      'body': body,
      // Categoría de la notificación (reservation_confirmed, new_dish, etc.)
      'type': type,
      // Marca de tiempo para ordenarlas cronológicamente
      'createdAt': FieldValue.serverTimestamp(),
      // Estado inicial: no leída. Cuando el cliente la procesa, pasa a true.
      'isRead': false,
    });
  }

  // ─── Notificar a TODOS los admins (reserva nueva) ────────────────────────

  /// Escribe una notificación en la cola para TODOS los usuarios con role='ADMIN'.
  /// Se llama cuando un cliente crea una reserva nueva, para que todos los admins
  /// reciban un push inmediato y vean el badge en la barra de navegación.
  static Future<void> enqueueForAllAdmins({
    required String title,
    required String body,
    required String type,
  }) async {
    try {
      // Consultamos Firestore para obtener los IDs de todos los admins
      final snapshot = await _db
          .collection('users')
          .where('role', isEqualTo: 'ADMIN')
          .get();

      // Encolamos la notificación para cada admin individualmente
      for (final doc in snapshot.docs) {
        await enqueueForUser(
          toUserId: doc.id,
          title: title,
          body: body,
          type: type,
        );
      }
    } catch (e) {
      // Si falla la consulta no interrumpimos el flujo de reserva
      // ignore: avoid_print
      print('[FcmService] Error al notificar admins: $e');
    }
  }

  /// Obtiene el usuario actualmente autenticado en Firebase Auth.
  /// Método de utilidad para usarlo desde otros ViewModels.
  static User? get currentUser => FirebaseAuth.instance.currentUser;
}
