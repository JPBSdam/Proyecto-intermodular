import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

/// Repositorio de acceso directo a Firebase Storage.
///
/// Responsabilidades:
/// • Subir archivos a Firebase Storage (genérico)
/// • Obtener URLs de descarga
/// • Eliminar archivos por URL o por ruta
///
/// Nota: Este repositorio NO valida ni maneja errores.
/// Eso es responsabilidad del Service.
class StorageRepository {
  // ─── Singleton ───
  static final StorageRepository _instance = StorageRepository._internal();

  factory StorageRepository() => _instance;

  StorageRepository._internal();

  // ─── Firebase Storage ─────────────────────────────────────────────
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ─── UPLOAD ──────────────────────────────────────────────────────
  /// Sube cualquier archivo a Firebase Storage en la ruta especificada.
  ///
  /// Retorna la ruta completa donde se almacenó el archivo.
  Future<String> uploadFile(File file, String storagePath) async {
    final reference = _storage.ref(storagePath);
    await reference.putFile(file);
    return storagePath;
  }

  // ─── GET DOWNLOAD URL ────────────────────────────────────────────
  /// Obtiene la URL de descarga de un archivo almacenado.
  ///
  /// La URL es pública y puede compartirse, pero respeta las reglas
  /// de seguridad de Firebase Storage.
  Future<String> getDownloadUrl(String storagePath) async {
    final reference = _storage.ref(storagePath);
    return await reference.getDownloadURL();
  }

  // ─── DELETE ──────────────────────────────────────────────────────
  /// Elimina un archivo usando su URL de descarga.
  ///
  /// Extrae automáticamente la ruta de storage de la download URL.
  Future<void> deleteImageByUrl(String downloadUrl) async {
    final storagePath = _extractStoragePathFromUrl(downloadUrl);
    await deleteImage(storagePath);
  }

  /// Elimina un archivo usando su ruta de storage.
  ///
  /// Si el archivo no existe, Firebase lanza una excepción 'object-not-found'.
  Future<void> deleteImage(String storagePath) async {
    final reference = _storage.ref(storagePath);
    await reference.delete();
  }

  // ─── HELPERS ─────────────────────────────────────────────────────
  /// Extrae la ruta de storage de una download URL de Firebase Storage.
  ///
  /// Firebase Storage URLs tienen el formato:
  /// https://firebasestorage.googleapis.com/v0/b/{bucket}/o/{encoded-path}?alt=media&token={token}
  ///
  /// Esta función decodifica {encoded-path} para obtener la ruta original.
  String _extractStoragePathFromUrl(String downloadUrl) {
    try {
      // Encuentra la parte entre '/o/' y '?' o fin de string
      final oIndex = downloadUrl.indexOf('/o/');
      final questionIndex = downloadUrl.indexOf('?', oIndex);

      if (oIndex == -1) {
        throw ArgumentError(
          'URL de Firebase Storage inválida: no contiene "/o/"',
        );
      }

      final encodedPath = questionIndex == -1
          ? downloadUrl.substring(oIndex + 3)
          : downloadUrl.substring(oIndex + 3, questionIndex);

      // Decodificar URL encoding (ej: %2F → /)
      return Uri.decodeComponent(encodedPath);
    } catch (e) {
      throw ArgumentError(
        'No se pudo extraer la ruta de storage de la URL: $downloadUrl',
      );
    }
  }
}
