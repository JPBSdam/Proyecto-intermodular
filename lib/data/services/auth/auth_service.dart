import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Servicio de autenticación que encapsula toda la interacción con FirebaseAuth

class AuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  AuthService({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
    : _auth = auth ?? FirebaseAuth.instance,
      _googleSignIn = googleSignIn ?? GoogleSignIn();

  // ─── Streams ─────────────────────────────
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ─── Getters ─────────────────────────────
  User? get currentUser => _auth.currentUser;
  bool isAnonymous() => _auth.currentUser?.isAnonymous ?? false;
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

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
      if (e.code == 'popup-closed-by-user' ||
          e.code == 'canceled' ||
          e.code == 'user-cancelled') {
        return null;
      }
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

  Future<void> deleteCurrentUser() =>
      _handleErrors(() => _auth.currentUser!.delete());

  Future<void> sendEmailVerification() =>
      _handleErrors(() => _auth.currentUser!.sendEmailVerification());

  Future<void> reloadUser() => _handleErrors(() => _auth.currentUser!.reload());

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
      case 'requires-recent-login':
        return 'Por seguridad, cierra sesión, vuelve a iniciarla y elimina la cuenta de nuevo.';
      case 'operation-not-allowed':
        return 'Operación no permitida.';
      case 'account-exists-with-different-credential':
        return 'Ya existe una cuenta con este correo usando otro método.';
      default:
        return 'Error de autenticación: ${e.message}';
    }
  }
}
