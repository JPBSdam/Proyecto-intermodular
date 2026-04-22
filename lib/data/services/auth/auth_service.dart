import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Servicio de autenticación que encapsula toda la interacción con FirebaseAuth
/// y Google Sign-In.
///
/// - Gestiona:
///   • Registro y login con email/password
///   • Login con Google y anónimo
///   • Cierre de sesión y recuperación de contraseña
///
/// - Expone:
///   • Un stream (`authStateChanges`) para reaccionar a cambios de sesión
///   • El usuario actual y su estado (ej: anónimo)
///
/// - Manejo de errores:
///   • Centralizado mediante `_handleErrors`
///   • Traduce excepciones de Firebase a mensajes legibles
///
/// Actúa como capa intermedia entre Firebase y la aplicación,
/// manteniendo la lógica de autenticación desacoplada de la UI.

class AuthService {
  // Instancias (dependencias)
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // ─── Streams ─────────────────────────────
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ─── Getters ─────────────────────────────
  User? get currentUser => _auth.currentUser;

  bool isAnonymous() => _auth.currentUser?.isAnonymous ?? false;

  // ─── Métodos de autenticación ─────────────

  Future<UserCredential?> signUpWithEmail({
    required String email,
    required String password,
  }) => _handleErrors(
    () =>
        _auth.createUserWithEmailAndPassword(email: email, password: password),
  );

  Future<UserCredential?> signInWithEmail({
    required String email,
    required String password,
  }) => _handleErrors(
    () => _auth.signInWithEmailAndPassword(email: email, password: password),
  );

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();

      // El usuario cerró el diálogo o pulsó atrás: no es un error.
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } on PlatformException catch (e) {
      final code = e.code.toLowerCase();
      if (code == 'sign_in_canceled' ||
          code == 'canceled' ||
          code == 'cancelled') {
        return null;
      }
      throw 'Error inesperado: ${e.message ?? e.code}';
    } on FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    } catch (e) {
      throw 'Error inesperado: $e';
    }
  }

  Future<UserCredential?> signInAnonymously() =>
      _handleErrors(() => _auth.signInAnonymously());

  Future<void> signOut() => _handleErrors(() async {
    if (await _googleSignIn.isSignedIn()) {
      await _googleSignIn.signOut();
    }
    await _auth.signOut();
  });

  Future<void> resetPassword({required String email}) =>
      _handleErrors(() => _auth.sendPasswordResetEmail(email: email));

  /// Envía un correo de verificación al usuario actual
  Future<void> sendEmailVerification() =>
      _handleErrors(() => _auth.currentUser!.sendEmailVerification());

  /// Recarga el usuario actual para obtener el estado más reciente de verificación
  Future<void> reloadUser() => _handleErrors(() => _auth.currentUser!.reload());

  /// Comprueba si el correo del usuario actual está verificado
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // ─── Manejo de errores ────────────────────

  Future<T> _handleErrors<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    } catch (e) {
      throw 'Error inesperado: $e';
    }
  }

  String _mapAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'La contraseña es demasiado débil.';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con este correo electrónico.';
      case 'invalid-email':
        return 'El correo electrónico no es válido.';
      case 'user-not-found':
        return 'No existe ninguna cuenta con este correo.';
      case 'wrong-password':
        return 'Contraseña incorrecta.';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada.';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde.';
      case 'operation-not-allowed':
        return 'Operación no permitida.';
      case 'account-exists-with-different-credential':
        return 'Ya existe una cuenta con este correo usando otro método.';
      default:
        return 'Error de autenticación: ${e.message}';
    }
  }
}
