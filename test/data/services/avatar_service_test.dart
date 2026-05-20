import 'package:app_restaurante/data/services/avatar/avatar_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AvatarService', () {
    test('prioriza storageImage sobre googlePhotoUrl y authPhotoUrl', () {
      final url = AvatarService.resolveAvatarUrl(
        storageImage: 'https://storage.example.com/avatar.jpg',
        googlePhotoUrl: 'https://google.example.com/avatar.jpg',
        authPhotoUrl: 'https://auth.example.com/avatar.jpg',
      );

      expect(url, 'https://storage.example.com/avatar.jpg');
    });

    test('prioriza googlePhotoUrl cuando storageImage no existe', () {
      final url = AvatarService.resolveAvatarUrl(
        storageImage: null,
        googlePhotoUrl: 'https://google.example.com/avatar.jpg',
        authPhotoUrl: 'https://auth.example.com/avatar.jpg',
      );

      expect(url, 'https://google.example.com/avatar.jpg');
    });

    test('usa authPhotoUrl cuando solo existe authPhotoUrl', () {
      final url = AvatarService.resolveAvatarUrl(
        storageImage: null,
        googlePhotoUrl: null,
        authPhotoUrl: 'https://auth.example.com/avatar.jpg',
      );

      expect(url, 'https://auth.example.com/avatar.jpg');
    });

    test('retorna null cuando no hay ninguna imagen', () {
      final url = AvatarService.resolveAvatarUrl(
        storageImage: null,
        googlePhotoUrl: null,
        authPhotoUrl: null,
      );

      expect(url, isNull);
    });
  });
}
