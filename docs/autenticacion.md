# 🔐 Sistema de Autenticación

## 📋 Resumen

El proyecto utiliza **Firebase Authentication** para gestionar usuarios con múltiples métodos de inicio de sesión.

---

## 🎯 Métodos de autenticación Implementados

### 1. **Email y Contraseña**
- Registro de nuevos usuarios
- Inicio de sesión con credenciales
- Validación de formato de email
- Manejo de contraseñas

### 2. **Google Sign-In**
- Inicio de sesión con cuenta de Google
- Integración con Firebase
- Flujo OAuth completo

### 3. **Inicio de Sesión Anónimo**
- Acceso temporal sin registro
- Útil para probar la app

---

## 🏗️ Arquitectura

```
lib/data/services/auth/
  └── auth_service.dart                  ← Servicio de autenticación Firebase
  
lib/ui/viewmodels/auth/
  ├── login_viewmodel.dart               ← Lógica de login
  └── register_viewmodel.dart            ← Lógica de registro
  
lib/ui/views/auth/
  ├── login_view.dart                    ← Pantalla de login
  └── register_view.dart                 ← Pantalla de registro
  
lib/core/navigation/
  └── auth_wrapper.dart                  ← Wrapper para rutas protegidas
```

---

## 🔧 Funcionalidades del AuthService

### Métodos Principales

```dart
// Registro
Future<UserCredential?> signUpWithEmail({
  required String email,
  required String password,
})

// Login con email
Future<UserCredential?> signInWithEmail({
  required String email,
  required String password,
})

// Login con Google
Future<UserCredential?> signInWithGoogle()

// Login anónimo
Future<UserCredential?> signInAnonymously()

// Cerrar sesión
Future<void> signOut()

// Restablecer contraseña
Future<void> resetPassword({required String email})

// Estado actual
User? get currentUser
Stream<User?> get authStateChanges
bool isAnonymous()
```

---

## 🎨 Integración con ViewModels

Los ViewModels utilizan `AuthService` para manejar la autenticación:

```dart
// LoginViewModel
class LoginViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    // Lógica con manejo de estado
    await _authService.signInWithEmail(...);
  }
}
```

**Ventajas:**
- ✅ Separación de lógica de UI y servicios
- ✅ Gestión de estado con Provider
- ✅ Fácil de testear
- ✅ Manejo centralizado de errores

---

## 🔒 Protección de rutas

### AuthWrapper
El `AuthWrapper` protege rutas que requieren autenticación:

```dart
class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        // Si está autenticado → HomeView
        if (snapshot.hasData) {
          return ChangeNotifierProvider(
            create: (_) => HomeViewModel()..loadHomeData(),
            child: const HomeView(),
          );
        }
        // Si NO está autenticado → LoginView
        return const LoginView();
      },
    );
  }
}
```

**¿Cómo funciona?**
1. Escucha cambios en el estado de autenticación con `authStateChanges`
2. Si hay un usuario autenticado → muestra la pantalla principal
3. Si NO hay usuario → redirige al login

---

## ❌ Manejo de Errores

El `AuthService` incluye un método `_handleAuthException` que traduce los errores de Firebase a mensajes en español:

### Errores Comunes

| Código Firebase | Mensaje al Usuario |
|----------------|-------------------|
| `weak-password` | La contraseña es demasiado débil |
| `email-already-in-use` | Ya existe una cuenta con este correo |
| `invalid-email` | El correo electrónico no es válido |
| `user-not-found` | No existe ninguna cuenta con este correo |
| `wrong-password` | Contraseña incorrecta |
| `too-many-requests` | Demasiados intentos. Intenta más tarde |
| `user-disabled` | Esta cuenta ha sido deshabilitada |

---

## 🚀 Flujo de Autenticación

### Registro de Usuario
```
Usuario completa formulario
    ↓
RegisterViewModel.signUpWithEmail()
    ↓
AuthService.signUpWithEmail()
    ↓
Firebase crea usuario
    ↓
authStateChanges emite evento
    ↓
AuthWrapper detecta usuario
    ↓
Navega a HomeView
```

### Inicio de Sesión
```
Usuario ingresa credenciales
    ↓
LoginViewModel.signInWithEmail()
    ↓
AuthService.signInWithEmail()
    ↓
Firebase valida credenciales
    ↓
authStateChanges emite evento
    ↓
AuthWrapper detecta usuario
    ↓
Navega a HomeView
```

### Cerrar Sesión
```
Usuario presiona "Cerrar Sesión"
    ↓
HomeViewModel.signOut()
    ↓
AuthService.signOut()
    ↓
Firebase cierra sesión
    ↓
authStateChanges emite null
    ↓
AuthWrapper detecta sin usuario
    ↓
Navega a LoginView
```

---

## 💡 Buenas Prácticas Implementadas

1. ✅ **Separación de responsabilidades**: Service → ViewModel → View
2. ✅ **Manejo centralizado de errores**: Todos los errores pasan por `_handleAuthException`
3. ✅ **Mensajes en español**: Usuario recibe mensajes claros
4. ✅ **Estado reactivo**: `authStateChanges` actualiza UI automáticamente
5. ✅ **Cierre de sesión completo**: Incluye Google Sign-In
6. ✅ **Validación de usuario anónimo**: Método `isAnonymous()`

---

## 📚 Recursos

- [Firebase Authentication Docs](https://firebase.google.com/docs/auth)
- [Google Sign-In Flutter](https://pub.dev/packages/google_sign_in)
- [GoRouter Documentation](https://pub.dev/packages/go_router)

---
