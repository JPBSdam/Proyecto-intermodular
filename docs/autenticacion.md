# 🔐 Sistema de Autenticación

## 📋 Resumen

El proyecto usa **Firebase Authentication** para gestionar usuarios con tres métodos de inicio de sesión distintos. Toda la lógica de Firebase queda encapsulada en `AuthService`, de forma que ni las pantallas ni los ViewModels hablan directamente con Firebase.

---

## 🎯 Métodos de autenticación implementados

### 1. Email y contraseña
- Registro de nuevos usuarios
- Inicio de sesión con credenciales
- Recuperación de contraseña por email
- Verificación del email tras el registro

### 2. Google Sign-In
- Inicio de sesión con cuenta de Google
- Integración OAuth completa con Firebase

### 3. Acceso anónimo (invitado)
- El usuario puede explorar la app sin registrarse
- No puede acceder a reservas ni perfil
- Si intenta hacerlo, se le pide que inicie sesión

---

## 🏗️ Arquitectura

```
lib/data/services/auth/
  └── auth_service.dart          ← Toda la lógica de Firebase Auth

lib/ui/viewmodels/auth/
  ├── login_viewmodel.dart       ← Estado y lógica de la pantalla de login
  └── register_viewmodel.dart    ← Estado y lógica de la pantalla de registro

lib/ui/views/auth/
  ├── login_view.dart            ← Pantalla de login (solo UI)
  └── register_view.dart         ← Pantalla de registro (solo UI)

lib/core/navigation/
  └── app_router.dart            ← Protección de rutas con GoRouter redirect
```

---

## 🔧 Qué expone AuthService

```dart
class AuthService {
  // ─── Stream ─────────────────────────────────────────────
  // Emite el usuario cada vez que cambia el estado de sesión.
  // GoRouter lo escucha para redirigir automáticamente.
  Stream<User?> get authStateChanges

  // ─── Estado actual ───────────────────────────────────────
  User? get currentUser           // null si no hay sesión
  bool get isEmailVerified        // si el email está verificado
  bool isAnonymous()              // true si es sesión de invitado

  // ─── Autenticación ───────────────────────────────────────
  Future<UserCredential?> signUpWithEmail({email, password})
  Future<UserCredential?> signInWithEmail({email, password})
  Future<UserCredential?> signInWithGoogle()
  Future<UserCredential?> signInAnonymously()
  Future<void> signOut()
  Future<void> resetPassword({email})

  // ─── Verificación de email ───────────────────────────────
  Future<void> sendEmailVerification()
  Future<void> reloadUser()

  // ─── Eliminación de cuenta ───────────────────────────────
  Future<void> deleteCurrentUser()   
}
```

---

## 🎨 Cómo lo usan los ViewModels

Los ViewModels llaman a `AuthService` y gestionan el estado de la UI (cargando, error). `LoginViewModel` también consulta `UserRepository` para bloquear cuentas eliminadas:

```dart
class LoginViewModel extends ChangeNotifier {
  final AuthService _authService;
  final UserRepository _userRepository;

  Future<bool> signInWithEmail({required String email, required String password}) async {
    _setLoading(true);
    _clearError();
    try {
      final credential = await _authService.signInWithEmail(email: email, password: password);
      await _checkUserActive(credential?.user?.uid);  // bloquea cuentas eliminadas
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _checkUserActive(String? uid) async {
    if (uid == null) return;
    try {
      final user = await _userRepository.getById(uid);
      if (user != null && user.isActive == false) {
        await _authService.signOut();
        throw 'Esta cuenta no existe o ha sido eliminada.';
      }
    } catch (e) {
      if (e is String) rethrow;
      await _authService.signOut();  // fallo inesperado → cerrar sesión por seguridad
      rethrow;
    }
  }
}
```

La vista solo lee `isLoading` y `errorMessage` del ViewModel: no sabe nada de Firebase.

---

## 🔒 Protección de rutas

La protección de rutas la hace **GoRouter** directamente, sin necesidad de un widget envolvente. El router escucha el stream de autenticación y redirige automáticamente cuando cambia el estado de sesión.

```dart
final GoRouter appRouter = GoRouter(
  // refreshListenable avisa a GoRouter cada vez que el stream emite un nuevo valor
  refreshListenable: GoRouterRefreshStream(
    FirebaseAuth.instance.authStateChanges(),
  ),

  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;
    final location = state.matchedLocation;

    final isAuthRoute = location == '/login' || location == '/register';
    final isProtectedRoute =
        location.startsWith('/profile') || location.startsWith('/reservations');

    // Sin usuario → no puede acceder a zonas protegidas
    if (user == null && isProtectedRoute) return AppRoutes.login;

    // Con sesión real → no tiene sentido ir al login/registro
    if (user != null && !user.isAnonymous && isAuthRoute) return AppRoutes.home;

    return null; // Sin redirección: continúa normalmente
  },
```

**¿Qué es `GoRouterRefreshStream`?**
GoRouter necesita un `ChangeNotifier` para saber cuándo re-evaluar las redirecciones. Pero `authStateChanges` es un `Stream`, no un `ChangeNotifier`. Esta clase puente los convierte:

```dart
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }
  late final StreamSubscription _subscription;
  // ...
}
```

---

## 📧 Verificación de email

Tras el registro, `RegisterViewModel` envía automáticamente el email de verificación:

```
Usuario completa el formulario de registro
    ↓
RegisterViewModel.signUpWithEmail()
    ↓
AuthService.signUpWithEmail() — crea la cuenta en Firebase
    ↓
AuthService.sendEmailVerification() — envía el email
    ↓
La app navega a Home y muestra un banner hasta que se verifique
```

En la pantalla Home, si el email no está verificado, `VerificationBanner` muestra un aviso con la opción de reenviar el correo. Cuando el usuario vuelve a la app después de verificarlo, `HomeViewModel.checkEmailVerification()` recarga el usuario y el banner desaparece.

---

## ❌ Manejo de errores

`AuthService` incluye un método privado `_mapAuthException` que traduce los códigos de error de Firebase a mensajes en español legibles. Así los ViewModels solo necesitan hacer `catch (e)` y mostrar `e.toString()` sin conocer los detalles de Firebase.

| Código Firebase | Mensaje al usuario |
|---|---|
| `weak-password` | La contraseña es demasiado débil. |
| `email-already-in-use` | Ya existe una cuenta con este correo electrónico. |
| `invalid-email` | El correo electrónico no es válido. |
| `user-not-found` | No existe ninguna cuenta con este correo. |
| `wrong-password` | Contraseña incorrecta. |
| `user-disabled` | Esta cuenta ha sido deshabilitada. |
| `too-many-requests` | Demasiados intentos. Intenta más tarde. |
| `account-exists-with-different-credential` | Ya existe una cuenta con este correo usando otro método. |

---

## 🚀 Flujos principales

### Registro
```
Usuario completa formulario
    ↓
RegisterViewModel.signUpWithEmail()
    ↓
AuthService.signUpWithEmail() → Firebase crea usuario
    ↓
AuthService.sendEmailVerification()
    ↓
authStateChanges emite el nuevo usuario
    ↓
GoRouter detecta el cambio y redirige a Home automáticamente
```

### Login
```
Usuario introduce credenciales
    ↓
LoginViewModel.signInWithEmail()
    ↓
AuthService.signInWithEmail() → Firebase valida
    ↓
authStateChanges emite el usuario autenticado
    ↓
GoRouter redirige a Home automáticamente
```

### Cerrar sesión
```
Usuario pulsa "Cerrar sesión"
    ↓
HomeViewModel.signOut()
    ↓
AuthService.signOut() → cierra sesión en Google (si aplica) y en Firebase
    ↓
authStateChanges emite null
    ↓
GoRouter detecta que no hay usuario y redirige a Login automáticamente
```

---

## 💡 Buenas prácticas aplicadas

1. **Separación de responsabilidades**: `AuthService` → `ViewModel` → `View`. Cada capa tiene una sola responsabilidad.
2. **Manejo centralizado de errores**: todos los errores de Firebase pasan por `_mapAuthException`.
3. **Mensajes en español**: el usuario recibe mensajes claros, no códigos técnicos.
4. **Reactividad**: `authStateChanges` actualiza el router automáticamente sin código manual de navegación.
5. **Cierre de sesión completo**: incluye `googleSignIn.signOut()` cuando aplica.

---

## 📚 Recursos

- [Firebase Authentication Docs](https://firebase.google.com/docs/auth)
- [Google Sign-In Flutter](https://pub.dev/packages/google_sign_in)
- [GoRouter Documentation](https://pub.dev/packages/go_router)
