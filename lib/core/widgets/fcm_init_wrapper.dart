// Widget que inicializa FCM en el momento correcto del ciclo de vida.
//
// Problema que resuelve:
//   FCM necesita saber QUIÉN es el usuario para:
//   - Guardar su token en Firestore
//   - Escuchar su cola de notificaciones
//   Pero el usuario puede iniciar o cerrar sesión en cualquier momento.
//
//   Además, las notificaciones de cambio de estado de reservas deben
//   funcionar desde CUALQUIER pantalla, no solo desde la de reservas.
//
// Solución:
//   Envolvemos toda la app con este widget, que escucha el stream de
//   autenticación de Firebase y reacciona a los cambios de sesión.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app_restaurante/data/services/notifications/fcm_service.dart';
// Importamos ReservationViewModel para activar el stream global de reservas
import 'package:app_restaurante/ui/viewmodels/firestore/reservation_viewmodel.dart';

class FcmInitWrapper extends StatefulWidget {
  // El widget hijo es toda la aplicación (MyApp → MaterialApp.router)
  final Widget child;

  const FcmInitWrapper({super.key, required this.child});

  @override
  State<FcmInitWrapper> createState() => _FcmInitWrapperState();
}

class _FcmInitWrapperState extends State<FcmInitWrapper> {
  // Guardamos el ID del último usuario autenticado para detectar cambios
  String? _lastUserId;

  @override
  void initState() {
    super.initState();
    // Nos suscribimos al stream de autenticación de Firebase.
    // Se emite cada vez que el usuario inicia o cierra sesión.
    FirebaseAuth.instance.authStateChanges().listen(_onAuthStateChanged);
  }

  /// Se ejecuta cada vez que cambia el estado de autenticación.
  void _onAuthStateChanged(User? user) {
    if (user != null && !user.isAnonymous) {
      // El usuario ha iniciado sesión con cuenta real

      if (_lastUserId == user.uid) return; // Ya inicializado para este usuario
      _lastUserId = user.uid;

      // ── FCM: guardar token y escuchar la cola de notificaciones ──────────
      // Guardamos el token FCM del dispositivo en su perfil de Firestore
      FcmService.saveUserToken(user.uid);
      // Escucha la colección "notification_queue" con los avisos pendientes
      FcmService.listenToNotificationQueue(user.uid);

      // ── Stream global de reservas para notificaciones ─────────────────────
      // Activamos el ReservationViewModel global (el de main.dart) para que
      // escuche las reservas del usuario desde cualquier pantalla.
      // Sin esto, las notificaciones de cambio de estado solo funcionarían
      // cuando el usuario está dentro de la pantalla de reservas.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // context.read accede al ReservationViewModel global del MultiProvider
        context.read<ReservationViewModel>().watchByUser(user.uid);
      });
    } else {
      // El usuario ha cerrado sesión (o no hay sesión activa)
      _lastUserId = null;

      // Paramos de escuchar la cola de Firestore para no desperdiciar recursos
      FcmService.stopListening();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Este widget es completamente transparente: solo gestiona el ciclo de vida
    // y muestra exactamente el mismo hijo que recibe
    return widget.child;
  }
}
