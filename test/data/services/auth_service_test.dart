import 'package:app_restaurante/data/services/auth/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mock_exceptions/mock_exceptions.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'auth_service_test.mocks.dart';

@GenerateMocks([GoogleSignIn, GoogleSignInAccount, GoogleSignInAuthentication])
void main() {
  group('AuthService', () {
    late MockFirebaseAuth mockAuth;
    late MockGoogleSignIn mockGoogleSignIn;
    late MockGoogleSignInAccount mockAccount;
    late MockGoogleSignInAuthentication mockGoogleAuth;
    late AuthService authService;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockGoogleSignIn = MockGoogleSignIn();
      mockAccount = MockGoogleSignInAccount();
      mockGoogleAuth = MockGoogleSignInAuthentication();
      authService = AuthService(auth: mockAuth, googleSignIn: mockGoogleSignIn);
    });

    // ─── signUpWithEmail ──────────────────────────────────────────────────────

    group('signUpWithEmail', () {
      test('registra un usuario y devuelve UserCredential', () async {
        // Act
        final result = await authService.signUpWithEmail(
          email: 'nuevo@test.com',
          password: 'password123',
        );

        // Assert
        expect(result, isNotNull);
        expect(mockAuth.currentUser?.email, 'nuevo@test.com');
      });

      test('lanza error con contraseña débil', () async {
        // Arrange
        whenCalling(
          Invocation.method(#createUserWithEmailAndPassword, null, {}),
        ).on(mockAuth).thenThrow(FirebaseAuthException(code: 'weak-password'));

        // Act & Assert
        await expectLater(
          authService.signUpWithEmail(email: 'test@test.com', password: '123'),
          throwsA('La contraseña es demasiado débil.'),
        );
      });

      test('lanza error con email ya en uso', () async {
        // Arrange
        whenCalling(
              Invocation.method(#createUserWithEmailAndPassword, null, {}),
            )
            .on(mockAuth)
            .thenThrow(FirebaseAuthException(code: 'email-already-in-use'));

        // Act & Assert
        await expectLater(
          authService.signUpWithEmail(
            email: 'existente@test.com',
            password: 'password123',
          ),
          throwsA('Ya existe una cuenta con este correo electrónico.'),
        );
      });

      test('lanza error con email inválido', () async {
        // Arrange
        whenCalling(
          Invocation.method(#createUserWithEmailAndPassword, null, {}),
        ).on(mockAuth).thenThrow(FirebaseAuthException(code: 'invalid-email'));

        // Act & Assert
        await expectLater(
          authService.signUpWithEmail(
            email: 'email-invalido',
            password: 'password123',
          ),
          throwsA('El correo electrónico no es válido.'),
        );
      });
    });

    // ─── signInWithEmail ──────────────────────────────────────────────────────

    group('signInWithEmail', () {
      test('inicia sesión y devuelve UserCredential', () async {
        // Arrange
        mockAuth.mockUser = MockUser(email: 'user@test.com');

        // Act
        final result = await authService.signInWithEmail(
          email: 'user@test.com',
          password: 'password123',
        );

        // Assert
        expect(result, isNotNull);
        expect(mockAuth.currentUser?.email, 'user@test.com');
      });

      test('lanza error: usuario no encontrado', () async {
        // Arrange
        whenCalling(
          Invocation.method(#signInWithEmailAndPassword, null, {}),
        ).on(mockAuth).thenThrow(FirebaseAuthException(code: 'user-not-found'));

        // Act & Assert
        await expectLater(
          authService.signInWithEmail(
            email: 'noexiste@test.com',
            password: 'pass',
          ),
          throwsA('No existe ninguna cuenta con este correo.'),
        );
      });

      test('lanza error: contraseña incorrecta', () async {
        // Arrange
        whenCalling(
          Invocation.method(#signInWithEmailAndPassword, null, {}),
        ).on(mockAuth).thenThrow(FirebaseAuthException(code: 'wrong-password'));

        // Act & Assert
        await expectLater(
          authService.signInWithEmail(
            email: 'user@test.com',
            password: 'incorrecta',
          ),
          throwsA('Contraseña incorrecta.'),
        );
      });

      test('lanza error: cuenta deshabilitada', () async {
        // Arrange
        whenCalling(
          Invocation.method(#signInWithEmailAndPassword, null, {}),
        ).on(mockAuth).thenThrow(FirebaseAuthException(code: 'user-disabled'));

        // Act & Assert
        await expectLater(
          authService.signInWithEmail(email: 'user@test.com', password: 'pass'),
          throwsA('Esta cuenta ha sido deshabilitada.'),
        );
      });

      test('lanza error: demasiados intentos', () async {
        // Arrange
        whenCalling(Invocation.method(#signInWithEmailAndPassword, null, {}))
            .on(mockAuth)
            .thenThrow(FirebaseAuthException(code: 'too-many-requests'));

        // Act & Assert
        await expectLater(
          authService.signInWithEmail(email: 'user@test.com', password: 'pass'),
          throwsA('Demasiados intentos. Intenta más tarde.'),
        );
      });
    });

    // ─── signInAnonymously ────────────────────────────────────────────────────

    group('signInAnonymously', () {
      test('inicia sesión anónimamente y el usuario es anónimo', () async {
        // Arrange
        mockAuth.mockUser = MockUser(isAnonymous: true);

        // Act
        final result = await authService.signInAnonymously();

        // Assert
        expect(result, isNotNull);
        expect(mockAuth.currentUser?.isAnonymous, isTrue);
      });
    });

    // ─── signInWithGoogle ─────────────────────────────────────────────────────

    group('signInWithGoogle', () {
      test('retorna null cuando el usuario cancela', () async {
        // Arrange
        when(mockGoogleSignIn.signIn()).thenAnswer((_) async => null);

        // Act
        final result = await authService.signInWithGoogle();

        // Assert
        expect(result, isNull);
      });

      test('retorna null con PlatformException de cancelación', () async {
        // Arrange
        when(
          mockGoogleSignIn.signIn(),
        ).thenThrow(PlatformException(code: 'sign_in_canceled'));

        // Act
        final result = await authService.signInWithGoogle();

        // Assert
        expect(result, isNull);
      });

      test('retorna null con PlatformException "canceled"', () async {
        // Arrange
        when(
          mockGoogleSignIn.signIn(),
        ).thenThrow(PlatformException(code: 'canceled'));

        // Act
        final result = await authService.signInWithGoogle();

        // Assert
        expect(result, isNull);
      });

      test('lanza String con PlatformException no cancelado', () async {
        // Arrange
        when(mockGoogleSignIn.signIn()).thenThrow(
          PlatformException(code: 'network_error', message: 'Error de red'),
        );

        // Act & Assert
        await expectLater(
          authService.signInWithGoogle(),
          throwsA(isA<String>()),
        );
      });

      test('inicia sesión con Google correctamente', () async {
        // Arrange
        when(mockGoogleSignIn.signIn()).thenAnswer((_) async => mockAccount);
        when(
          mockAccount.authentication,
        ).thenAnswer((_) async => mockGoogleAuth);
        when(mockGoogleAuth.accessToken).thenReturn('fake_access_token');
        when(mockGoogleAuth.idToken).thenReturn('fake_id_token');

        // Act
        final result = await authService.signInWithGoogle();

        // Assert
        expect(result, isNotNull);
        expect(mockAuth.currentUser, isNotNull);
      });

      test(
        'lanza String con FirebaseAuthException al validar credencial',
        () async {
          // Arrange
          when(mockGoogleSignIn.signIn()).thenAnswer((_) async => mockAccount);
          when(
            mockAccount.authentication,
          ).thenAnswer((_) async => mockGoogleAuth);
          when(mockGoogleAuth.accessToken).thenReturn('fake_access_token');
          when(mockGoogleAuth.idToken).thenReturn('fake_id_token');
          whenCalling(Invocation.method(#signInWithCredential, []))
              .on(mockAuth)
              .thenThrow(
                FirebaseAuthException(
                  code: 'account-exists-with-different-credential',
                ),
              );

          // Act & Assert
          await expectLater(
            authService.signInWithGoogle(),
            throwsA('Ya existe una cuenta con este correo usando otro método.'),
          );
        },
      );
    });

    // ─── signOut ──────────────────────────────────────────────────────────────

    group('signOut', () {
      test(
        'llama a googleSignIn.signOut() cuando hay sesión de Google activa',
        () async {
          // Arrange
          when(mockGoogleSignIn.isSignedIn()).thenAnswer((_) async => true);
          when(mockGoogleSignIn.signOut()).thenAnswer((_) async => null);

          // Act
          await authService.signOut();

          // Assert
          verify(mockGoogleSignIn.signOut()).called(1);
        },
      );

      test('no llama a googleSignIn.signOut() sin sesión de Google', () async {
        // Arrange
        when(mockGoogleSignIn.isSignedIn()).thenAnswer((_) async => false);

        // Act
        await authService.signOut();

        // Assert
        verifyNever(mockGoogleSignIn.signOut());
      });

      test('cierra la sesión de Firebase correctamente', () async {
        // Arrange
        mockAuth.mockUser = MockUser(email: 'user@test.com');
        when(mockGoogleSignIn.isSignedIn()).thenAnswer((_) async => false);
        await authService.signInWithEmail(
          email: 'user@test.com',
          password: 'pass',
        );
        expect(authService.currentUser, isNotNull);

        // Act
        await authService.signOut();

        // Assert
        expect(authService.currentUser, isNull);
      });
    });

    // ─── currentUser ─────────────────────────────────────────────────────────

    group('currentUser', () {
      test('retorna null cuando no hay sesión', () {
        expect(authService.currentUser, isNull);
      });

      test('retorna el usuario cuando hay sesión activa', () async {
        // Arrange
        mockAuth.mockUser = MockUser(uid: 'abc123', email: 'user@test.com');
        await authService.signInWithEmail(
          email: 'user@test.com',
          password: 'pass',
        );

        // Assert
        expect(authService.currentUser, isNotNull);
        expect(authService.currentUser?.email, 'user@test.com');
      });
    });

    // ─── isAnonymous ──────────────────────────────────────────────────────────

    group('isAnonymous', () {
      test('retorna false cuando no hay usuario', () {
        expect(authService.isAnonymous(), isFalse);
      });

      test('retorna false para usuario autenticado con email', () async {
        // Arrange
        mockAuth.mockUser = MockUser(
          email: 'user@test.com',
          isAnonymous: false,
        );
        await authService.signInWithEmail(
          email: 'user@test.com',
          password: 'pass',
        );

        // Assert
        expect(authService.isAnonymous(), isFalse);
      });

      test('retorna true para usuario anónimo', () async {
        // Arrange
        mockAuth.mockUser = MockUser(isAnonymous: true);
        await authService.signInAnonymously();

        // Assert
        expect(authService.isAnonymous(), isTrue);
      });
    });

    // ─── isEmailVerified ──────────────────────────────────────────────────────

    group('isEmailVerified', () {
      test('retorna false cuando no hay usuario', () {
        expect(authService.isEmailVerified, isFalse);
      });

      test('retorna true cuando el email está verificado', () async {
        // Arrange
        mockAuth.mockUser = MockUser(
          email: 'user@test.com',
          isEmailVerified: true,
        );
        await authService.signInWithEmail(
          email: 'user@test.com',
          password: 'pass',
        );

        // Assert
        expect(authService.isEmailVerified, isTrue);
      });

      test('retorna false cuando el email no está verificado', () async {
        // Arrange
        mockAuth.mockUser = MockUser(
          email: 'user@test.com',
          isEmailVerified: false,
        );
        await authService.signInWithEmail(
          email: 'user@test.com',
          password: 'pass',
        );

        // Assert
        expect(authService.isEmailVerified, isFalse);
      });
    });

    // ─── authStateChanges ─────────────────────────────────────────────────────

    group('authStateChanges', () {
      test('emite el usuario tras iniciar sesión', () async {
        // Arrange
        mockAuth.mockUser = MockUser(uid: 'abc123', email: 'user@test.com');
        final userFuture = authService.authStateChanges.firstWhere(
          (u) => u != null,
        );

        // Act
        await authService.signInWithEmail(
          email: 'user@test.com',
          password: 'pass',
        );

        // Assert
        final user = await userFuture;
        expect(user, isNotNull);
        expect(user?.email, 'user@test.com');
      });

      test('emite null tras cerrar sesión', () async {
        // Arrange
        mockAuth.mockUser = MockUser(email: 'user@test.com');
        await authService.signInWithEmail(
          email: 'user@test.com',
          password: 'pass',
        );
        when(mockGoogleSignIn.isSignedIn()).thenAnswer((_) async => false);
        final nullFuture = authService.authStateChanges.firstWhere(
          (u) => u == null,
        );

        // Act
        await authService.signOut();

        // Assert
        expect(await nullFuture, isNull);
      });
    });

    // ─── resetPassword ────────────────────────────────────────────────────────

    group('resetPassword', () {
      test('envía el email de recuperación sin errores', () async {
        await expectLater(
          authService.resetPassword(email: 'user@test.com'),
          completes,
        );
      });

      test('lanza error si el usuario no existe', () async {
        // Arrange
        whenCalling(
          Invocation.method(#sendPasswordResetEmail, null, {}),
        ).on(mockAuth).thenThrow(FirebaseAuthException(code: 'user-not-found'));

        // Act & Assert
        await expectLater(
          authService.resetPassword(email: 'noexiste@test.com'),
          throwsA('No existe ninguna cuenta con este correo.'),
        );
      });
    });
  });
}
