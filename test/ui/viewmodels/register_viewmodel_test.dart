import 'package:app_restaurante/data/services/auth/auth_service.dart';
import 'package:app_restaurante/ui/viewmodels/auth/register_viewmodel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'register_viewmodel_test.mocks.dart';

class _FakeUserCredential extends Fake implements UserCredential {}

@GenerateMocks([AuthService])
void main() {
  group('RegisterViewModel', () {
    late MockAuthService mockAuthService;
    late RegisterViewModel registerVM;

    final fakeCredential = _FakeUserCredential();

    setUp(() {
      mockAuthService = MockAuthService();
      registerVM = RegisterViewModel(authService: mockAuthService);
    });

    tearDown(() => registerVM.dispose());

    // ─── Estado inicial

    group('estado inicial', () {
      test('isLoading es false', () => expect(registerVM.isLoading, isFalse));
      test(
        'errorMessage es null',
        () => expect(registerVM.errorMessage, isNull),
      );
    });

    // ─── Registro de usuario

    group('signUpWithEmail', () {
      test('retorna true y envía email de verificación en éxito', () async {
        when(
          mockAuthService.signUpWithEmail(
            email: anyNamed('email'),
            password: anyNamed('password'),
          ),
        ).thenAnswer((_) async => fakeCredential);
        when(mockAuthService.sendEmailVerification()).thenAnswer((_) async {});

        final result = await registerVM.signUpWithEmail(
          email: 'nuevo@test.com',
          password: 'password123',
        );
        expect(result, isTrue);
        verify(mockAuthService.sendEmailVerification()).called(1);
      });

      test(
        'retorna false y setea errorMessage cuando el registro falla',
        () async {
          when(
            mockAuthService.signUpWithEmail(
              email: anyNamed('email'),
              password: anyNamed('password'),
            ),
          ).thenThrow('Ya existe una cuenta con este correo electrónico.');

          final result = await registerVM.signUpWithEmail(
            email: 'existente@test.com',
            password: 'pass123',
          );

          expect(result, isFalse);
          expect(
            registerVM.errorMessage,
            'Ya existe una cuenta con este correo electrónico.',
          );
        },
      );

      test('retorna true aunque falle el envío de verificación', () async {
        when(
          mockAuthService.signUpWithEmail(
            email: anyNamed('email'),
            password: anyNamed('password'),
          ),
        ).thenAnswer((_) async => fakeCredential);
        when(
          mockAuthService.sendEmailVerification(),
        ).thenThrow('Error al enviar verificación');

        final result = await registerVM.signUpWithEmail(
          email: 'nuevo@test.com',
          password: 'pass123',
        );

        expect(result, isTrue);
        expect(registerVM.errorMessage, isNotNull);
      });

      test('isLoading es false al terminar', () async {
        when(
          mockAuthService.signUpWithEmail(
            email: anyNamed('email'),
            password: anyNamed('password'),
          ),
        ).thenAnswer((_) async => fakeCredential);
        when(mockAuthService.sendEmailVerification()).thenAnswer((_) async {});
        await registerVM.signUpWithEmail(
          email: 'nuevo@test.com',
          password: 'pass123',
        );
        expect(registerVM.isLoading, isFalse);
      });

      test('notifica a la UI durante la operación', () async {
        var notifyCount = 0;
        registerVM.addListener(() => notifyCount++);
        when(
          mockAuthService.signUpWithEmail(
            email: anyNamed('email'),
            password: anyNamed('password'),
          ),
        ).thenAnswer((_) async => fakeCredential);
        when(mockAuthService.sendEmailVerification()).thenAnswer((_) async {});
        await registerVM.signUpWithEmail(
          email: 'nuevo@test.com',
          password: 'pass123',
        );
        expect(notifyCount, greaterThanOrEqualTo(3));
      });
    });
  });
}
