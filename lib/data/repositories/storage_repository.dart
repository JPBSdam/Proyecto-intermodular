import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageRepository {
  // ─── Singleton ───
  static final StorageRepository _instance = StorageRepository._internal();

  factory StorageRepository() => _instance;

  StorageRepository._internal();

  // ─── Firebase Storage ─────────────────────────────────────────────
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ─── UPLOAD ──────────────────────────────────────────────────────
  Future<String> uploadFile(File file, String storagePath) async {
    final reference = _storage.ref(storagePath);
    await reference.putFile(file);
    return storagePath;
  }

  // ─── GET DOWNLOAD URL ────────────────────────────────────────────
  Future<String> getDownloadUrl(String storagePath) async {
    final reference = _storage.ref(storagePath);
    return await reference.getDownloadURL();
  }

  // ─── DELETE ──────────────────────────────────────────────────────
  Future<void> deleteImageByUrl(String downloadUrl) async {
    final storagePath = _extractStoragePathFromUrl(downloadUrl);
    await deleteImage(storagePath);
  }

  Future<void> deleteImage(String storagePath) async {
    final reference = _storage.ref(storagePath);
    await reference.delete();
  }

  // ─── HELPERS ─────────────────────────────────────────────────────
  String _extractStoragePathFromUrl(String downloadUrl) {
    try {
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

      return Uri.decodeComponent(encodedPath);
    } catch (e) {
      throw ArgumentError(
        'No se pudo extraer la ruta de storage de la URL: $downloadUrl',
      );
    }
  }
}
