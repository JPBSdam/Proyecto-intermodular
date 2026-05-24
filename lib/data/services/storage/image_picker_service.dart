import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

// Servicio para seleccionar imágenes desde la cámara o galería, con manejo de permisos.
class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  Future<XFile?> pickImage({
    required ImageSource source,
    int imageQuality = 80,
    double maxWidth = 1200,
  }) async {
    if (!kIsWeb) {
      final granted = await _requestPermission(source);
      if (!granted) {
        throw Exception(
          source == ImageSource.camera
              ? 'Permiso de cámara denegado'
              : 'Permiso de galería denegado',
        );
      }
    }

    return await _picker.pickImage(
      source: source,
      imageQuality: imageQuality,
      maxWidth: maxWidth,
    );
  }

  Future<bool> _requestPermission(ImageSource source) async {
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      return status.isGranted;
    }

    if (Platform.isIOS) {
      final status = await Permission.photos.request();
      return status.isGranted;
    }

    if (Platform.isAndroid) {
      final storage = await Permission.storage.request();
      if (storage.isGranted) return true;

      final photos = await Permission.photos.request();
      return photos.isGranted;
    }

    return true;
  }
}
