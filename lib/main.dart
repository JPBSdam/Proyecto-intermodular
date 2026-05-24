import 'package:app_restaurante/ui/viewmodels/auth/login_viewmodel.dart';
import 'package:app_restaurante/ui/viewmodels/auth/register_viewmodel.dart';
import 'package:app_restaurante/ui/viewmodels/theme_viewmodel.dart';
import 'package:app_restaurante/ui/viewmodels/firestore/dish_viewmodel.dart';
import 'package:app_restaurante/ui/viewmodels/firestore/restaurant_viewmodel.dart';
import 'package:app_restaurante/ui/viewmodels/firestore/reservation_viewmodel.dart';
import 'package:app_restaurante/ui/viewmodels/firestore/user_viewmodel.dart';
import 'package:app_restaurante/ui/viewmodels/home/home_viewmodel.dart';
import 'package:app_restaurante/data/services/firestore/dish_service.dart';
import 'package:app_restaurante/data/services/firestore/reservation_service.dart';
import 'package:app_restaurante/data/services/firestore/restaurant_service.dart';
import 'package:app_restaurante/data/services/notifications/notification_service.dart';
import 'package:app_restaurante/data/services/notifications/fcm_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'my_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (FirebaseAuth.instance.currentUser == null) {
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } catch (_) {}
  }

  await NotificationService.init();

  await FcmService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeViewModel()),
        ChangeNotifierProvider(create: (_) => LoginViewModel()),
        ChangeNotifierProvider(create: (_) => RegisterViewModel()),
        ChangeNotifierProvider(create: (_) => UserViewModel()),
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ChangeNotifierProvider(create: (_) => DishViewModel(DishService())),
        ChangeNotifierProvider(
          create: (_) => RestaurantViewModel(RestaurantService()),
        ),
        ChangeNotifierProvider(
          create: (_) => ReservationViewModel(ReservationService()),
        ),
      ],
      child: const MyApp(),
    ),
  );
}
