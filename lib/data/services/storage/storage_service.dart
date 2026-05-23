import 'dart:io';
import 'package:app_restaurante/data/repositories/storage_repository.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

// Servicio de gestión de Firebase Storage.

class StorageService {
  // ─── Singleton ───
  static final StorageService _instance = StorageService._internal();

  factory StorageService() => _instance;

  StorageService._internal();

  // ─── Repository ──────────────────────────────────────────────────
  final StorageRepository _repository = StorageRepository();

  // ─── Rutas base ──────────────────────────────────────────────────
  static const String _dishesPath = 'sabrosaapp/dishes';
  static const String _restaurantsPath = 'sabrosaapp/restaurants';
  static const String _usersPath = 'sabrosaapp/users';

  // ─── Validaciones ────────────────────────────────────────────────
  // Tamaño máximo de imagen: 2MB
  static const int _maxFileSizeBytes = 2 * 1024 * 1024;

  void _validateImageFile(File file) {
    if (!file.existsSync()) {
      throw ArgumentError('El archivo no existe');
    }

    final fileSize = file.lengthSync();
    if (fileSize > _maxFileSizeBytes) {
      throw ArgumentError(
        'La imagen es demasiado grande. Máximo ${_maxFileSizeBytes ~/ (1024 * 1024)}MB',
      );
    }

    final extension = file.path.split('.').last.toLowerCase();
    final allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];
    if (!allowedExtensions.contains(extension)) {
      throw ArgumentError('Tipo de archivo no permitido. Solo JPG, PNG, WebP');
    }
  }

  // ─── DISH IMAGES ─────────────────────────────────────────────────
  Future<String> uploadDishImage(File imageFile, String dishId) async {
    return _handleErrors(() async {
      _validateImageFile(imageFile);

      final storagePath = '$_dishesPath/$dishId/image.jpg';
      debugPrint('📸 StorageService.uploadDishImage - Ruta: $storagePath');
      await _repository.uploadFile(imageFile, storagePath);
      return await _repository.getDownloadUrl(storagePath);
    });
  }

  Future<void> deleteDishImage(String dishUrlImage) async {
    return _handleErrors(() async {
      if (dishUrlImage.isNotEmpty) {
        await _repository.deleteImageByUrl(dishUrlImage);
      }
    });
  }

  // ─── RESTAURANT IMAGES ───────────────────────────────────────────

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

  Future<void> deleteRestaurantImage(String restaurantUrlImage) async {
    return _handleErrors(() async {
      if (restaurantUrlImage.isNotEmpty) {
        await _repository.deleteImageByUrl(restaurantUrlImage);
      }
    });
  }

  // ─── USER AVATARS ────────────────────────────────────────────────

  Future<String> uploadUserAvatar(File imageFile, String userId) async {
    return _handleErrors(() async {
      _validateImageFile(imageFile);

      final storagePath = '$_usersPath/$userId/avatar.jpg';
      await _repository.uploadFile(imageFile, storagePath);
      return await _repository.getDownloadUrl(storagePath);
    });
  }

  Future<void> deleteUserAvatar(String userUrlImage) async {
    return _handleErrors(() async {
      if (userUrlImage.isNotEmpty) {
        await _repository.deleteImageByUrl(userUrlImage);
      }
    });
  }

  // ─── Manejo de errores ───────────────────────────────────────────

  Future<T> _handleErrors<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseException catch (e) {
      throw _mapFirebaseException(e);
    } on ArgumentError catch (e) {
      throw e.message;
    } catch (e) {
      throw 'Error inesperado al procesar la imagen: $e';
    }
  }

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
