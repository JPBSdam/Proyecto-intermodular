import 'package:firebase_auth/firebase_auth.dart' as firebase;

class AvatarService {
  const AvatarService._();

  // Determina la URL de avatar correcta según la prioridad:
  // 1. imagen de Storage propia (`storageImage`)
  // 2. imagen almacenada de Google en Firestore (`googlePhotoUrl`)
  // 3. imagen del proveedor de autenticación (`authPhotoUrl`)
  static String? resolveAvatarUrl({
    String? storageImage,
    String? googlePhotoUrl,
    String? authPhotoUrl,
  }) {
    if (storageImage != null && storageImage.isNotEmpty) {
      return storageImage;
    }
    if (googlePhotoUrl != null && googlePhotoUrl.isNotEmpty) {
      return googlePhotoUrl;
    }
    if (authPhotoUrl != null && authPhotoUrl.isNotEmpty) {
      return authPhotoUrl;
    }
    return null;
  }

  static String? resolveFromAuth({
    String? storageImage,
    String? googlePhotoUrl,
    firebase.User? authUser,
  }) {
    return resolveAvatarUrl(
      storageImage: storageImage,
      googlePhotoUrl: googlePhotoUrl,
      authPhotoUrl: authUser?.photoURL,
    );
  }
}
