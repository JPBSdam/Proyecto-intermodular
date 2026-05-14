import 'dart:io';
import 'package:app_restaurante/data/repositories/storage_repository.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Servicio de gestión de Firebase Storage.
///
/// Responsabilidades:
/// • Construir rutas específicas para cada tipo de entidad
/// • Validar archivos antes de subir (tamaño, tipo)
/// • Manejar errores de Firebase y traducirlos a mensajes legibles
/// • Gestionar operaciones CRUD de imágenes
///
/// Arquitectura:
/// • Delega acceso directo a datos en `StorageRepository`
/// • Añade lógica de negocio y validaciones
/// • Manejo centralizado de errores
class StorageService {
  // ─── Singleton ───
  static final StorageService _instance = StorageService._internal();

  factory StorageService() => _instance;

  StorageService._internal();

  // ─── Repository ──────────────────────────────────────────────────
  final StorageRepository _repository = StorageRepository();

  // ─── Rutas base ──────────────────────────────────────────────────
  static const String _basePath = 'sabrosaapp';
  static const String _dishesPath = '$_basePath/dishes';
  static const String _restaurantsPath = '$_basePath/restaurants';
  static const String _usersPath = '$_basePath/users';

  // ─── Validaciones ────────────────────────────────────────────────
  /// Tamaño máximo de imagen: 5MB
  static const int _maxFileSizeBytes = 5 * 1024 * 1024;

  /// Valida un archivo de imagen antes de subirlo.
  ///
  /// Lanza [ArgumentError] si el archivo no es válido.
  void _validateImageFile(File file) {
    // Verificar que el archivo existe
    if (!file.existsSync()) {
      throw ArgumentError('El archivo no existe');
    }

    // Verificar tamaño
    final fileSize = file.lengthSync();
    if (fileSize > _maxFileSizeBytes) {
      throw ArgumentError(
        'La imagen es demasiado grande. Máximo ${_maxFileSizeBytes ~/ (1024 * 1024)}MB',
      );
    }

    // Verificar extensión del archivo
    final extension = file.path.split('.').last.toLowerCase();
    final allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];
    if (!allowedExtensions.contains(extension)) {
      throw ArgumentError('Tipo de archivo no permitido. Solo JPG, PNG, WebP');
    }

    // Nota: La validación de tipos MIME se haría aquí si tuviéramos acceso
    // al tipo MIME real del archivo, pero por simplicidad usamos la extensión.
    // Los tipos MIME permitidos están definidos en _allowedMimeTypes para
    // futura implementación si se necesita validación más estricta.
  }

  // ─── DISH IMAGES ─────────────────────────────────────────────────
  /// Sube una imagen para un plato.
  ///
  /// Retorna la URL de descarga de la imagen subida.
  Future<String> uploadDishImage(File imageFile, String dishId) async {
    return _handleErrors(() async {
      _validateImageFile(imageFile);

      final storagePath = '$_dishesPath/$dishId/image.jpg';
      await _repository.uploadFile(imageFile, storagePath);
      return await _repository.getDownloadUrl(storagePath);
    });
  }

  /// Borra la imagen de un plato.
  Future<void> deleteDishImage(String dishUrlImage) async {
    return _handleErrors(() async {
      if (dishUrlImage.isNotEmpty) {
        await _repository.deleteImageByUrl(dishUrlImage);
      }
    });
  }

  // ─── RESTAURANT IMAGES ───────────────────────────────────────────
  /// Sube una imagen para un restaurante.
  ///
  /// Retorna la URL de descarga de la imagen subida.
  Future<String> uploadRestaurantImage(
    File imageFile,
    String restaurantId,
  ) async {
    return _handleErrors(() async {
      _validateImageFile(imageFile);

      final storagePath = '$_restaurantsPath/$restaurantId/image.jpg';
      await _repository.uploadFile(imageFile, storagePath);
      return await _repository.getDownloadUrl(storagePath);
    });
  }

  /// Borra la imagen de un restaurante.
  Future<void> deleteRestaurantImage(String restaurantUrlImage) async {
    return _handleErrors(() async {
      if (restaurantUrlImage.isNotEmpty) {
        await _repository.deleteImageByUrl(restaurantUrlImage);
      }
    });
  }

  // ─── USER AVATARS ────────────────────────────────────────────────
  /// Sube un avatar para un usuario.
  ///
  /// Retorna la URL de descarga del avatar subido.
  Future<String> uploadUserAvatar(File imageFile, String userId) async {
    return _handleErrors(() async {
      _validateImageFile(imageFile);

      final storagePath = '$_usersPath/$userId/avatar.jpg';
      await _repository.uploadFile(imageFile, storagePath);
      return await _repository.getDownloadUrl(storagePath);
    });
  }

  /// Borra el avatar de un usuario.
  Future<void> deleteUserAvatar(String userUrlImage) async {
    return _handleErrors(() async {
      if (userUrlImage.isNotEmpty) {
        await _repository.deleteImageByUrl(userUrlImage);
      }
    });
  }

  // ─── Manejo de errores ───────────────────────────────────────────
  /// Decorador para manejar errores de Firebase Storage.
  ///
  /// Traduce excepciones de Firebase a mensajes legibles para el usuario.
  Future<T> _handleErrors<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseException catch (e) {
      throw _mapFirebaseException(e);
    } on ArgumentError catch (e) {
      // Re-lanzar errores de validación tal cual
      throw e.message;
    } catch (e) {
      throw 'Error inesperado al procesar la imagen: $e';
    }
  }

  /// Mapea excepciones de Firebase Storage a mensajes legibles.
  String _mapFirebaseException(FirebaseException e) {
    switch (e.code) {
      case 'object-not-found':
        return 'La imagen no existe o ya fue eliminada';
      case 'unauthorized':
        return 'No tienes permisos para acceder a esta imagen';
      case 'quota-exceeded':
        return 'Se ha excedido el límite de almacenamiento';
      case 'invalid-argument':
        return 'Los datos de la imagen no son válidos';
      case 'cancelled':
        return 'La subida de imagen fue cancelada';
      case 'unknown':
        return 'Error desconocido de Firebase Storage';
      default:
        return 'Error de almacenamiento: ${e.message}';
    }
  }
}
