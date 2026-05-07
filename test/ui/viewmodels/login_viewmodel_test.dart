import 'package:app_restaurante/data/services/auth/auth_service.dart';
import 'package:app_restaurante/ui/viewmodels/auth/login_viewmodel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'login_viewmodel_test.mocks.dart';

class _FakeUserCredential extends Fake implements UserCredential {}

@GenerateMocks([AuthService])
void main() {
  group('LoginViewModel', () {
    late MockAuthService mockAuthService;
    late LoginViewModel loginVM;

    final fakeCredential = _FakeUserCredential();

    setUp(() {
      mockAuthService = MockAuthService();
      loginVM = LoginViewModel(authService: mockAuthService);
    });

    tearDown(() => loginVM.dispose());

    // ─── Estado inicial ───────────────────────────────────────────────────────

    group('estado inicial', () {
      test('isLoading es false', () => expect(loginVM.isLoading, isFalse));
      test('errorMessage es null', () => expect(loginVM.errorMessage, isNull));
    });

    // ─── signInWithEmail ──────────────────────────────────────────────────────

    group('signInWithEmail', () {
      test('retorna true y no setea error en éxito', () async {
        // Arrange
        when(
          mockAuthService.signInWithEmail(
            email: anyNamed('email'),
            password: anyNamed('password'),
          ),
        ).thenAnswer((_) async => fakeCredential);

        // Act
        final result = await loginVM.signInWithEmail(
          email: 'user@test.com',
          password: 'pass123',
        );

        // Assert
        expect(result, isTrue);
        expect(loginVM.errorMessage, isNull);
      });

      test('retorna false y setea errorMessage en error', () async {
        // Arrange
        when(
          mockAuthService.signInWithEmail(
            email: anyNamed('email'),
            password: anyNamed('password'),
          ),
        ).thenThrow('Contraseña incorrecta.');

        // Act
        final result = await loginVM.signInWithEmail(
          email: 'user@test.com',
          password: 'mal',
        );

        // Assert
        expect(result, isFalse);
        expect(loginVM.errorMessage, 'Contraseña incorrecta.');
      });

      test('isLoading es false al terminar', () async {
        // Arrange
        when(
          mockAuthService.signInWithEmail(
            email: anyNamed('email'),
            password: anyNamed('password'),
          ),
        ).thenAnswer((_) async => fakeCredential);

        // Act
        await loginVM.signInWithEmail(
          email: 'user@test.com',
          password: 'pass123',
        );

        // Assert
        expect(loginVM.isLoading, isFalse);
      });

      test('limpia el error anterior al iniciar una nueva operación', () async {
        // Arrange — primera llamada falla
        when(
          mockAuthService.signInWithEmail(
            email: anyNamed('email'),
            password: anyNamed('password'),
          ),
        ).thenThrow('Contraseña incorrecta.');
        await loginVM.signInWithEmail(email: 'user@test.com', password: 'mal');
        expect(loginVM.errorMessage, isNotNull);

        // Segunda llamada tiene éxito
        when(
          mockAuthService.signInWithEmail(
            email: anyNamed('email'),
            password: anyNamed('password'),
          ),
        ).thenAnswer((_) async => fakeCredential);

        // Act
        await loginVM.signInWithEmail(
          email: 'user@test.com',
          password: 'pass123',
        );

        // Assert
        expect(loginVM.errorMessage, isNull);
      });

      test('notifica a la UI durante la operación', () async {
        // Arrange
        var notifyCount = 0;
        loginVM.addListener(() => notifyCount++);
        when(
          mockAuthService.signInWithEmail(
            email: anyNamed('email'),
            password: anyNamed('password'),
          ),
        ).thenAnswer((_) async => fakeCredential);

        // Act
        await loginVM.signInWithEmail(
          email: 'user@test.com',
          password: 'pass123',
        );

        // Assert — al menos: clearError + setLoading(true) + setLoading(false)
        expect(notifyCount, greaterThanOrEqualTo(3));
      });
    });

    // ─── signInWithGoogle ─────────────────────────────────────────────────────

    group('signInWithGoogle', () {
      test('retorna true cuando Google devuelve credencial', () async {
        // Arrange
        when(
          mockAuthService.signInWithGoogle(),
        ).thenAnswer((_) async => fakeCredential);

        // Act & Assert
        expect(await loginVM.signInWithGoogle(), isTrue);
      });

      test('retorna false cuando el usuario cancela (retorna null)', () async {
        // Arrange
        when(mockAuthService.signInWithGoogle()).thenAnswer((_) async => null);

        // Act & Assert
        expect(await loginVM.signInWithGoogle(), isFalse);
        expect(loginVM.errorMessage, isNull);
      });

      test('retorna false y setea errorMessage en error', () async {
        // Arrange
        when(
          mockAuthService.signInWithGoogle(),
        ).thenThrow('Error inesperado: ...');

        // Act
        final result = await loginVM.signInWithGoogle();

        // Assert
        expect(result, isFalse);
        expect(loginVM.errorMessage, isNotNull);
      });
    });

    // ─── signInAnonymously ────────────────────────────────────────────────────

    group('signInAnonymously', () {
      test('retorna true en éxito', () async {
        // Arrange
        when(
          mockAuthService.signInAnonymously(),
        ).thenAnswer((_) async => _FakeUserCredential());

        // Act & Assert
        expect(await loginVM.signInAnonymously(), isTrue);
      });

      test('retorna false y setea errorMessage en error', () async {
        // Arrange
        when(mockAuthService.signInAnonymously()).thenThrow('Error inesperado');

        // Act
        final result = await loginVM.signInAnonymously();

        // Assert
        expect(result, isFalse);
        expect(loginVM.errorMessage, isNotNull);
      });
    });

    // ─── resetPassword ────────────────────────────────────────────────────────

    group('resetPassword', () {
      test('retorna true en éxito', () async {
        // Arrange
        when(
          mockAuthService.resetPassword(email: anyNamed('email')),
        ).thenAnswer((_) async {});

        // Act & Assert
        expect(await loginVM.resetPassword(email: 'user@test.com'), isTrue);
      });

      test('retorna false y setea errorMessage en error', () async {
        // Arrange
        when(
          mockAuthService.resetPassword(email: anyNamed('email')),
        ).thenThrow('No existe ninguna cuenta con este correo.');

        // Act
        final result = await loginVM.resetPassword(email: 'no@test.com');

        // Assert
        expect(result, isFalse);
        expect(
          loginVM.errorMessage,
          'No existe ninguna cuenta con este correo.',
        );
      });
    });
  });
}
