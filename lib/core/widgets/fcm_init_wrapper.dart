import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:app_restaurante/data/services/notifications/fcm_service.dart';
import 'package:app_restaurante/data/services/notifications/notification_service.dart';
import 'package:app_restaurante/core/navigation/app_routes.dart';
import 'package:app_restaurante/ui/viewmodels/firestore/reservation_viewmodel.dart';

// Widget que inicializa FCM en el momento correcto del ciclo de vida.
class FcmInitWrapper extends StatefulWidget {
  final Widget child;

  const FcmInitWrapper({super.key, required this.child});

  @override
  State<FcmInitWrapper> createState() => _FcmInitWrapperState();
}

class _FcmInitWrapperState extends State<FcmInitWrapper> {
  String? _lastUserId;

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen(_onAuthStateChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.setNavigationCallback((reservationId) {
        if (reservationId != null && mounted) {
          GoRouter.of(context).go(AppRoutes.reservationDetail(reservationId));
        }
      });
    });
  }

  // Se ejecuta cada vez que cambia el estado de autenticación.
  void _onAuthStateChanged(User? user) {
    if (user != null && !user.isAnonymous) {
      if (_lastUserId == user.uid) return;
      _lastUserId = user.uid;

      FcmService.saveUserToken(user.uid);
      FcmService.listenToNotificationQueue(user.uid);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<ReservationViewModel>().watchByUser(user.uid);
      });
    } else {
      _lastUserId = null;

      FcmService.stopListening();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
