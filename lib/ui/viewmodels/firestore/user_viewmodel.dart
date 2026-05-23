import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:app_restaurante/data/model/reservation.dart';
import 'package:app_restaurante/data/model/user.dart';
import 'package:app_restaurante/data/services/auth/auth_service.dart';
import 'package:app_restaurante/data/services/firestore/reservation_service.dart';
import 'package:app_restaurante/data/services/firestore/user_service.dart';
import 'package:app_restaurante/data/services/notifications/email_service.dart';
import 'package:app_restaurante/data/services/notifications/fcm_service.dart';
import 'package:app_restaurante/data/services/storage/storage_service.dart';

class UserViewModel extends ChangeNotifier {
  final UserService _service;
  final ReservationService _reservationService;
  final StorageService _storageService;
  final AuthService _authService;

  UserViewModel({
    UserService? service,
    ReservationService? reservationService,
    StorageService? storageService,
    AuthService? authService,
  }) : _service = service ?? UserService(),
       _reservationService = reservationService ?? ReservationService(),
       _storageService = storageService ?? StorageService(),
       _authService = authService ?? AuthService();

  User? _user;
  User? get user => _user;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _error = '';
  String get error => _error;

  StreamSubscription<User?>? _userSub;

  // ─── Escuchar cambios en tiempo real ───
  void watchUser(String uid) {
    _setLoading(true);
    _userSub?.cancel();
    _userSub = _service
        .watchUser(uid)
        .listen(
          (userData) {
            _user = userData;
            _setLoading(false);
          },
          onError: (e) {
            _error = 'Error al cargar el usuario: $e';
            _setLoading(false);
          },
        );
  }

  // ─── CRUD ──────────────────────────────
  Future<User?> fetchUserById(String id) async {
    try {
      _setLoading(true);
      return await _service.getUserById(id);
    } catch (e) {
      _error = 'Error al obtener usuario: $e';
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateUser(User user) async {
    _setLoading(true);
    _error = '';
    try {
      await _service.updateUser(user);
    } catch (e) {
      _error = 'Error al actualizar: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Guarda un usuario existente y opcionalmente sube/elimina su avatar.
  ///
  /// Nota: La creación de usuarios se gestiona en otro lugar (vinculada
  /// al flujo de Auth). Aquí solo gestionamos la subida del avatar y la
  /// actualización del documento del usuario.
  Future<void> saveUser(User user, File? imageFile) async {
    _setLoading(true);
    _error = '';
    try {
      // Subir avatar si se ha seleccionado uno. Usamos un path fijo para
      // el avatar que sobrescribe la imagen anterior, evitando el borrado.
      if (imageFile != null) {
        user.urlImage = await _storageService.uploadUserAvatar(
          imageFile,
          user.id!,
        );
      }

      // Actualizamos siempre el documento del usuario.
      await _service.updateUser(user);
    } catch (e) {
      _error = 'Error al guardar usuario: $e';
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> setNotificationsEnabled(String userId, bool value) async {
    _setLoading(true);
    _error = '';
    try {
      await _service.setNotificationsEnabled(userId, value);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  /// Soft delete: cancela reservas activas, anonimiza datos en Firestore
  /// (isActive=false) y elimina la cuenta de Firebase Auth.
  /// El documento de Firestore se conserva para la integridad referencial.
  Future<void> deleteAccount(String userId) async {
    _setLoading(true);
    _error = '';
    try {
      // 1. Cancelar reservas pendientes/confirmadas y notificar al admin
      await _cancelActiveReservations(userId);

      // 2. Anonimizar datos personales en Firestore
      await _service.anonymize(userId);

      // 3. Eliminar cuenta de Firebase Auth (libera el email para re-registro)
      await _authService.deleteCurrentUser();
      if (_authService.currentUser != null) {
        await _authService.signOut();
      }
    } catch (e) {
      _error = 'Error al eliminar la cuenta: $e';
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _cancelActiveReservations(String userId) async {
    final active = await _reservationService.getActiveByUser(userId);
    if (active.isEmpty) return;

    final ids = active.map((r) => r.id!).toList();
    await _reservationService.updateStatuses(ids, ReservationStatus.cancelled);

    // Notificar al admin por FCM (in-app) y email por cada reserva cancelada
    for (final reservation in active) {
      unawaited(
        FcmService.enqueueForAllAdmins(
          title: 'Reserva cancelada',
          body:
              'Una reserva fue cancelada porque el cliente eliminó su cuenta.',
          type: 'reservation_cancelled',
        ),
      );
      unawaited(EmailService.sendReservationCancelledToAdmins(reservation));
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _userSub?.cancel();
    super.dispose();
  }
}
