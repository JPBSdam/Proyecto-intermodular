import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';

// ─── Handler de mensajes con app CERRADA ─────────────
// IMPORTANTE: esta función debe estar fuera de la clase, porque Android
// necesita encontrarla directamente cuando llega la notificación push aunque la app esté cerrada.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Este handler se ejecuta cuando llega un mensaje FCM y la app está completamente cerrada (no en background).
}

// ─── Clase principal del servicio ────────────────────────────────────────────
class FcmService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static StreamSubscription? _queueSubscription;
  static StreamSubscription? _tokenRefreshSubscription;

  static Future<void> init() async {
    // Registramos el handler para mensajes con app cerrada (DEBE ir primero)
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    unawaited(() async {
      try {
        await _fcm.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );
      } catch (_) {}
    }());

    // Cuando la app está en primer plano, el listener de Firestore (listenToNotificationQueue)
    // ya muestra la notificación local. No duplicamos con onMessage.
  }

  // ─── Gestión del token FCM ────────────────────────────────────────────────

  // Obtiene el token FCM del dispositivo y lo guarda en el documento
  // del usuario en Firestore. Este token identifica este dispositivo
  // para poder enviarle notificaciones push directas.
  static Future<void> saveUserToken(String userId) async {
    final String? token;
    try {
      token = await _fcm.getToken();
    } catch (e) {
      // APNS token not yet available on iOS (common on simulator / first launch)
      if (kDebugMode) print('[FcmService] getToken() skipped: $e');
      return;
    }
    if (token == null) return;

    await _db.collection('users').doc(userId).set({
      'fcmToken': token,
      // Guardamos cuándo se actualizó para detectar tokens expirados (90 días)
      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Cancelamos la suscripción anterior antes de crear una nueva para evitar
    // que un listener de una sesión anterior escriba en el usuario incorrecto.
    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = _fcm.onTokenRefresh.listen((
      String newToken,
    ) async {
      await _db.collection('users').doc(userId).set({
        'fcmToken': newToken,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  // ─── Cola de notificaciones en Firestore ─────────────────────────────────
  // La colección "notification_queue" en Firestore actúa como buzón

  // Cuando el usuario inicia sesión.
  static void listenToNotificationQueue(String userId) {
    // Cancelamos cualquier suscripción anterior para evitar duplicados
    _queueSubscription?.cancel();

    _queueSubscription = _db
        .collection('notification_queue')
        .where('toUserId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .listen((QuerySnapshot snapshot) {
          for (final DocumentChange change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final Map<String, dynamic> data =
                  change.doc.data() as Map<String, dynamic>;

              NotificationService.showFromQueue(
                title: data['title'] as String? ?? 'SabrosApp',
                body: data['body'] as String? ?? '',
                type: data['type'] as String? ?? 'default',
                reservationId: data['reservationId'] as String?,
              );
              change.doc.reference.update({'isRead': true});
            }
          }
        });
  }

  // Para de escuchar la cola cuando el usuario cierra sesión.
  static void stopListening() {
    _queueSubscription?.cancel();
    _queueSubscription = null;
    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
  }

  // ─── Escritura en la cola (lado del admin) ────────────────────────────────
  static Future<void> enqueueForUser({
    required String toUserId,
    required String title,
    required String body,
    required String type,
    String? reservationId,
  }) async {
    final userDoc = await _db.collection('users').doc(toUserId).get();
    final notificationsEnabled =
        userDoc.data()?['notificationsEnabled'] as bool? ?? true;
    if (!notificationsEnabled) return;

    final data = {
      'toUserId': toUserId,
      'title': title,
      'body': body,
      'type': type,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    };

    // Agregar ID de la reserva si se proporciona
    if (reservationId != null && reservationId.isNotEmpty) {
      data['reservationId'] = reservationId;
    }

    await _db.collection('notification_queue').add(data);
  }

  // ─── Notificar a TODOS los clientes (plato nuevo) ───────────────────────
  static Future<void> enqueueForAllCustomers({
    required String title,
    required String body,
    required String type,
  }) async {
    try {
      final snapshot = await _db.collection('users').get();

      for (final doc in snapshot.docs) {
        final role = doc.data()['role'] as String?;
        if (role == 'ADMIN') continue;

        final notificationsEnabled =
            doc.data()['notificationsEnabled'] as bool? ?? true;
        if (!notificationsEnabled) continue;

        await enqueueForUser(
          toUserId: doc.id,
          title: title,
          body: body,
          type: type,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('[FcmService] Error al notificar clientes: $e');
      }
    }
  }

  // ─── Notificar a TODOS los admins (reserva nueva) ────────────────────────
  static Future<void> enqueueForAllAdmins({
    required String title,
    required String body,
    required String type,
  }) async {
    try {
      final snapshot = await _db
          .collection('users')
          .where('role', isEqualTo: 'ADMIN')
          .get();

      for (final doc in snapshot.docs) {
        final notificationsEnabled =
            doc.data()['notificationsEnabled'] as bool? ?? true;
        if (!notificationsEnabled) continue;

        await enqueueForUser(
          toUserId: doc.id,
          title: title,
          body: body,
          type: type,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('[FcmService] Error al notificar admins: $e');
      }
    }
  }

  static User? get currentUser => FirebaseAuth.instance.currentUser;
}
