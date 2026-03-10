# 🧭 Sistema de Navegación

## 📋 Resumen

El proyecto utiliza **GoRouter** para la navegación declarativa con integración de Provider y protección de rutas.

---

## 🎯 Rutas Implementadas

| Ruta | Descripción | Protegida |
|------|-------------|-----------|
| `/` | Wrapper de autenticación (redirige según estado) | No |
| `/login` | Pantalla de inicio de sesión | No |
| `/register` | Pantalla de registro | No |
| `/home` | Pantalla principal (requiere autenticación) | Sí |

---

## 🏗️ Arquitectura

```
lib/core/navigation/
├── app_router.dart       ← Configuración de rutas
├── app_routes.dart       ← Constantes de rutas
└── auth_wrapper.dart     ← Wrapper para protección
```

---

## 🔧 Configuración del Router

### app_router.dart
```dart
final router = GoRouter(
  initialLocation: AppRoutes.home,  // Ruta inicial
  debugLogDiagnostics: true,        // Debug en desarrollo
  routes: [
    // Ruta raíz con AuthWrapper
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const AuthWrapper(),
    ),
    
    // Login
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginView(),
    ),
    
    // Registro
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterView(),
    ),
    
    // Home con Provider
    GoRoute(
      path: '/home',
      builder: (context, state) => ChangeNotifierProvider(
        create: (_) => HomeViewModel(),
        child: const HomeView(title: 'Restaurante'),
      ),
    ),
  ],
);
```

---

## 🔒 Protección de Rutas con AuthWrapper

### ¿Qué es AuthWrapper?
Es un widget que decide qué pantalla mostrar basándose en el estado de autenticación.

```dart
class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        // Cargando
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen();
        }
        
        // Autenticado → Home
        if (snapshot.hasData) {
          return ChangeNotifierProvider(
            create: (_) => HomeViewModel()..loadHomeData(),
            child: const HomeScreen(),
          );
        }
        
        // NO autenticado → Login
        return const LoginView();
      },
    );
  }
}
```

### Flujo de Decisión
```
Usuario accede a la app
    ↓
AuthWrapper escucha authStateChanges
    ↓
¿Hay usuario autenticado?
    ├─ SÍ → Muestra HomeView (con Provider)
    └─ NO → Muestra LoginView
```

---

## 🎨 Integración con Provider

Las rutas que necesitan estado (ViewModels) usan `ChangeNotifierProvider`:

```dart
GoRoute(
  path: '/home',
  builder: (context, state) => ChangeNotifierProvider(
    create: (_) => HomeViewModel(),     // Crea el ViewModel
    child: const HomeView(title: 'Restaurante'), // Vista que lo consume
  ),
),
```

**Ventajas:**
- ✅ El ViewModel se crea al entrar a la ruta
- ✅ Se destruye al salir (gestión automática de memoria)
- ✅ Toda la vista tiene acceso al ViewModel

---
## 📝 Constantes de Rutas

### app_routes.dart
```dart
class AppRoutes {
  static const String home = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String homeScreen = '/home';
  
  // Prevenir instanciación
  AppRoutes._();
}
```

**Uso:**
```dart
// ✅ Bien
context.go(AppRoutes.login);

// ❌ Evitar
context.go('/login');
```

---
## 🚀 Navegación en el Código

### Navegación Básica
```dart
// Ir a login
context.go(AppRoutes.login);

// Ir a registro
context.go(AppRoutes.register);

// Ir a home
context.go(AppRoutes.home);
```

### Navegación con Push (mantiene stack)
```dart
// Añadir pantalla al stack
context.push(AppRoutes.profile);

// Volver atrás
context.pop();
```

### Navegación desde ViewModels
```dart
class LoginViewModel extends ChangeNotifier {
  Future<bool> signInWithEmail(...) async {
    final success = await _authService.signInWithEmail(...);
    
    if (success) {
      // AuthWrapper se encarga automáticamente
      // No necesitas navegar manualmente
    }
    
    return success;
  }
}
```

---

## 🔍 Debugging

### Ver logs de navegación
```dart
GoRouter(
  debugLogDiagnostics: true,  // ← Activa logs
)
```

**Output en consola:**
```
[GoRouter] known full paths for routes:
[GoRouter]   /
[GoRouter]   /login
[GoRouter]   /register
[GoRouter]   /home
```

---

## 📚 Recursos

- [GoRouter Documentation](https://pub.dev/packages/go_router)
- [Flutter Navigation Best Practices](https://docs.flutter.dev/development/ui/navigation)
- [Provider with GoRouter](https://pub.dev/packages/go_router#using-with-provider)
