import 'package:app_restaurante/data/model/user.dart' as model;
import 'package:app_restaurante/data/repositories/user_repository.dart';
import 'package:app_restaurante/data/services/auth/auth_service.dart';
import 'package:app_restaurante/ui/viewmodels/auth/login_viewmodel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'login_viewmodel_test.mocks.dart';

class _FakeUserCredential extends Fake implements UserCredential {
  @override
  User? get user => null;
}

@GenerateMocks([AuthService, UserRepository])
void main() {
  group('LoginViewModel', () {
    late MockAuthService mockAuthService;
    late MockUserRepository mockUserRepository;
    late LoginViewModel loginVM;

    final fakeCredential = _FakeUserCredential();

    setUp(() {
      mockAuthService = MockAuthService();
      mockUserRepository = MockUserRepository();
      loginVM = LoginViewModel(
        authService: mockAuthService,
        userRepository: mockUserRepository,
      );
    });

    tearDown(() => loginVM.dispose());

    // ─── Estado inicial

    group('estado inicial', () {
      test('isLoading es false', () => expect(loginVM.isLoading, isFalse));
      test('errorMessage es null', () => expect(loginVM.errorMessage, isNull));
    });

    // ─── Inicio de sesión con email

    group('signInWithEmail', () {
      test('retorna true y no setea error en éxito', () async {
        when(
          mockAuthService.signInWithEmail(
            email: anyNamed('email'),
            password: anyNamed('password'),
          ),
        ).thenAnswer((_) async => fakeCredential);

        final result = await loginVM.signInWithEmail(
          email: 'user@test.com',
          password: 'pass123',
        );

        expect(result, isTrue);
        expect(loginVM.errorMessage, isNull);
      });

      test('retorna false y setea errorMessage en error', () async {
        when(
          mockAuthService.signInWithEmail(
            email: anyNamed('email'),
            password: anyNamed('password'),
          ),
        ).thenThrow('Contraseña incorrecta.');

        final result = await loginVM.signInWithEmail(
          email: 'user@test.com',
          password: 'mal',
        );

        expect(result, isFalse);
        expect(loginVM.errorMessage, 'Contraseña incorrecta.');
      });

      test('isLoading es false al terminar', () async {
        when(
          mockAuthService.signInWithEmail(
            email: anyNamed('email'),
            password: anyNamed('password'),
          ),
        ).thenAnswer((_) async => fakeCredential);

        await loginVM.signInWithEmail(
          email: 'user@test.com',
          password: 'pass123',
        );

        expect(loginVM.isLoading, isFalse);
      });

      test('limpia el error anterior al iniciar una nueva operación', () async {
        when(
          mockAuthService.signInWithEmail(
            email: anyNamed('email'),
            password: anyNamed('password'),
          ),
        ).thenThrow('Contraseña incorrecta.');
        await loginVM.signInWithEmail(email: 'user@test.com', password: 'mal');
        expect(loginVM.errorMessage, isNotNull);

        when(
          mockAuthService.signInWithEmail(
            email: anyNamed('email'),
            password: anyNamed('password'),
          ),
        ).thenAnswer((_) async => fakeCredential);

        await loginVM.signInWithEmail(
          email: 'user@test.com',
          password: 'pass123',
        );

        expect(loginVM.errorMessage, isNull);
      });

      test('notifica a la UI durante la operación', () async {
        var notifyCount = 0;
        loginVM.addListener(() => notifyCount++);
        when(
          mockAuthService.signInWithEmail(
            email: anyNamed('email'),
            password: anyNamed('password'),
          ),
        ).thenAnswer((_) async => fakeCredential);

        await loginVM.signInWithEmail(
          email: 'user@test.com',
          password: 'pass123',
        );

        expect(notifyCount, greaterThanOrEqualTo(3));
      });
    });

    // ─── Inicio de sesión con Google

    group('signInWithGoogle', () {
      test('retorna true cuando Google devuelve credencial', () async {
        when(
          mockAuthService.signInWithGoogle(),
        ).thenAnswer((_) async => fakeCredential);

        expect(await loginVM.signInWithGoogle(), isTrue);
      });

      test('retorna false cuando el usuario cancela (retorna null)', () async {
        when(mockAuthService.signInWithGoogle()).thenAnswer((_) async => null);

        expect(await loginVM.signInWithGoogle(), isFalse);
        expect(loginVM.errorMessage, isNull);
      });

      test('retorna false y setea errorMessage en error', () async {
        when(
          mockAuthService.signInWithGoogle(),
        ).thenThrow('Error inesperado: ...');

        final result = await loginVM.signInWithGoogle();

        expect(result, isFalse);
        expect(loginVM.errorMessage, isNotNull);
      });
    });

    // ─── Inicio de sesión anónimo

    group('signInAnonymously', () {
      test('retorna true en éxito', () async {
        when(
          mockAuthService.signInAnonymously(),
        ).thenAnswer((_) async => _FakeUserCredential());

        expect(await loginVM.signInAnonymously(), isTrue);
      });

      test('retorna false y setea errorMessage en error', () async {
        when(mockAuthService.signInAnonymously()).thenThrow('Error inesperado');

        final result = await loginVM.signInAnonymously();

        expect(result, isFalse);
        expect(loginVM.errorMessage, isNotNull);
      });
    });

    // ─── Recuperación de contraseña

    group('resetPassword', () {
      test('retorna true en éxito', () async {
        when(
          mockAuthService.resetPassword(email: anyNamed('email')),
        ).thenAnswer((_) async {});

        expect(await loginVM.resetPassword(email: 'user@test.com'), isTrue);
      });

      test('retorna false y setea errorMessage en error', () async {
        when(
          mockAuthService.resetPassword(email: anyNamed('email')),
        ).thenThrow('No existe ninguna cuenta con este correo.');

        final result = await loginVM.resetPassword(email: 'no@test.com');

        expect(result, isFalse);
        expect(
          loginVM.errorMessage,
          'No existe ninguna cuenta con este correo.',
        );
      });
    });

    // ─── Validación de usuario activo

    group('checkUserActive', () {
      test(
        'signInWithEmail retorna false y cierra sesión si isActive es false',
        () async {
          final inactiveUser = model.User(id: 'uid1', isActive: false);

          // El login de Auth tiene éxito pero devuelve un UID real
          final fakeUser = _FakeUser('uid1');
          final fakeCredentialWithUser = _FakeUserCredentialWithUser(fakeUser);

          when(
            mockAuthService.signInWithEmail(
              email: anyNamed('email'),
              password: anyNamed('password'),
            ),
          ).thenAnswer((_) async => fakeCredentialWithUser);

          when(
            mockUserRepository.getById('uid1'),
          ).thenAnswer((_) async => inactiveUser);

          when(mockAuthService.signOut()).thenAnswer((_) async {});

          final result = await loginVM.signInWithEmail(
            email: 'deleted@test.com',
            password: 'pass123',
          );

          expect(result, isFalse);
          expect(
            loginVM.errorMessage,
            contains('Tu cuenta ha sido eliminada. Puedes registrarte de nuevo con el mismo correo.'),
          );
          verify(mockAuthService.signOut()).called(1);
        },
      );

      test('signInWithEmail permite acceso si isActive es true', () async {
        final activeUser = model.User(id: 'uid2', isActive: true);
        final fakeUser = _FakeUser('uid2');
        final fakeCredentialWithUser = _FakeUserCredentialWithUser(fakeUser);

        when(
          mockAuthService.signInWithEmail(
            email: anyNamed('email'),
            password: anyNamed('password'),
          ),
        ).thenAnswer((_) async => fakeCredentialWithUser);

        when(
          mockUserRepository.getById('uid2'),
        ).thenAnswer((_) async => activeUser);

        final result = await loginVM.signInWithEmail(
          email: 'active@test.com',
          password: 'pass123',
        );

        expect(result, isTrue);
        verifyNever(mockAuthService.signOut());
      });
    });
  });
}

// Fakes para simular UserCredential con un User real
class _FakeUser extends Fake implements User {
  @override
  final String uid;
  _FakeUser(this.uid);
}

class _FakeUserCredentialWithUser extends Fake implements UserCredential {
  final User _user;
  _FakeUserCredentialWithUser(this._user);
  @override
  User get user => _user;
}
