import 'dart:async';
import 'package:app_restaurante/data/services/auth/auth_service.dart';
import 'package:app_restaurante/data/services/avatar/avatar_service.dart';
import 'package:app_restaurante/data/services/firestore/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// ViewModel de la pantalla Home y gestión de sesión global.
class HomeViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  // Estado del perfil (Firestore)
  String _actualRole = 'USER'; // Rol real en la base de datos
  String? _userName;
  String? _userPhotoUrl;
  String? _userGooglePhotoUrl;

  // Modo Vista Cliente (para admins)
  bool _previewMode = false;

  // Estado de UI
  bool _isLoading = false;
  String _errorMessage = '';
  StreamSubscription? _userSubscription;

  // Getters
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  /// Retorna el rol efectivo (USER si previewMode está activo)
  String get userRole {
    if (_actualRole == 'ADMIN' && _previewMode) return 'USER';
    return _actualRole;
  }

  /// Retorna el rol real sin filtros
  String get actualRole => _actualRole;

  bool get previewMode => _previewMode;

  void togglePreviewMode() {
    if (_actualRole == 'ADMIN') {
      _previewMode = !_previewMode;
      notifyListeners();
    }
  }

  // Getters - Información del usuario
  User? get currentUser => _authService.currentUser;
  bool get isAnonymous => _authService.isAnonymous();

  /// true si el usuario NO está autenticado con una cuenta real:
  /// es decir, si currentUser es null o si está en modo anónimo.
  bool get isGuest => currentUser == null || isAnonymous;

  // Lógica de visualización: Prioridad Firestore > Auth > Email > Fallback
  String get displayName {
    if (isGuest) return 'Invitado';
    if (_userName != null && _userName!.isNotEmpty) return _userName!;
    if (currentUser?.displayName != null &&
        currentUser!.displayName!.isNotEmpty) {
      return currentUser!.displayName!;
    }
    return currentUser?.email ?? 'Usuario';
  }

  String? get photoUrl {
    if (isGuest) return null;
    return AvatarService.resolveFromAuth(
      storageImage: _userPhotoUrl,
      googlePhotoUrl: _userGooglePhotoUrl,
      authUser: currentUser,
    );
  }

  String get email => currentUser?.email ?? '';
  bool get isEmailVerified => currentUser?.emailVerified ?? false;

  HomeViewModel() {
    _setupAuthListener();
  }

  void _setupAuthListener() {
    // 1. Carga inicial
    _initUserStream(currentUser);

    // 2. Escucha cambios de auth
    _authService.authStateChanges.listen((user) {
      _initUserStream(user);
    });
  }

  void _initUserStream(User? user) {
    _userSubscription?.cancel();

    // Reset agresivo de datos al cambiar de usuario
    _actualRole = 'USER';
    _previewMode = false;
    _userName = null;
    _userPhotoUrl = null;
    _userGooglePhotoUrl = null;
    _errorMessage = '';

    if (user != null && !user.isAnonymous) {
      _userService
          .ensureUserExistsFromAuth(user)
          .catchError((e) => debugPrint("Sync Error: $e"));

      notifyListeners();

      _userSubscription = _userService
          .watchUser(user.uid)
          .listen(
            (userData) {
              _actualRole = userData?.role?.toUpperCase() ?? 'USER';
              _userName = userData?.name;
              _userPhotoUrl = userData?.urlImage;
              _userGooglePhotoUrl = userData?.googlePhotoUrl;
              notifyListeners();
            },
            onError: (e) {
              debugPrint("Error Firestore Stream: $e");
            },
          );
    } else {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }

  // ==================== ACCIONES ====================

  Future<void> checkEmailVerification() async {
    if (currentUser != null) {
      await currentUser!.reload();
      notifyListeners();
    }
  }

  Future<void> resendVerificationEmail() async {
    try {
      await _authService.sendEmailVerification();
    } catch (e) {
      _setError('Error: $e');
    }
  }

  // ==================== CERRAR SESIÓN ====================
  Future<bool> signOut() async {
    _setLoading(true);
    try {
      // 1. Cancelamos suscripción antes de nada
      await _userSubscription?.cancel();
      // 2. Cerramos sesión en Firebase
      await _authService.signOut();
      // 3. Reseteamos datos localmente
      _actualRole = 'USER';
      _previewMode = false;
      _userName = null;
      _userPhotoUrl = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Error al cerrar sesión: $e');
      _setLoading(false);
      return false;
    }
  }

  // ==================== HELPERS INTERNOS ====================
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }
}
