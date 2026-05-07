# 🧭 Sistema de Navegación

## 📋 Resumen

El proyecto usa **GoRouter** para gestionar todas las rutas de la app de forma declarativa. GoRouter también se encarga de proteger rutas privadas: escucha el estado de autenticación de Firebase y redirige automáticamente cuando el usuario inicia o cierra sesión.

---

## 🏗️ Arquitectura

```
lib/core/navigation/
├── app_router.dart      ← Configuración completa del router (rutas + protección)
└── app_routes.dart      ← Constantes y generadores de rutas
```
---

## 🗺️ Todas las rutas de la app

| Ruta | Descripción | Acceso |
|------|-------------|--------|
| `/home` | Pantalla principal | Todos |
| `/login` | Inicio de sesión | Solo sin sesión |
| `/register` | Registro de cuenta | Solo sin sesión |
| `/profile` | Perfil del usuario | Requiere sesión real |
| `/profile/form/:id` | Editar perfil | Requiere sesión real |
| `/restaurant/form` | Gestionar restaurante | Solo admin |
| `/dishes` | Listado de platos | Todos |
| `/dishes/form` | Crear plato | Solo admin |
| `/dishes/form/:id` | Editar plato | Solo admin |
| `/dishes/detail/:id` | Detalle de un plato | Todos |
| `/menus` | Listado de menús | Todos |
| `/menus/form` | Crear menú | Solo admin |
| `/menus/form/:id` | Editar menú | Solo admin |
| `/menus/detail/:id` | Detalle de un menú | Todos |
| `/reservations` | Gestión de reservas | Requiere sesión real |
| `/reservations/form` | Nueva reserva | Requiere sesión real |
| `/reservations/form/:id` | Editar reserva | Requiere sesión real |
| `/reservations/detail/:id` | Detalle de reserva | Requiere sesión real |

---

## 🔧 Cómo está configurado el router

### Estructura general

```dart
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.home,

  // 1. Escucha cambios de autenticación para re-evaluar redirecciones
  refreshListenable: GoRouterRefreshStream(
    FirebaseAuth.instance.authStateChanges(),
  ),

  // 2. Lógica de protección de rutas
  redirect: (context, state) { ... },

  // 3. Definición de todas las rutas
  routes: [ ... ],
);
```

### El bridge entre Firebase y GoRouter: `GoRouterRefreshStream`

GoRouter necesita un `ChangeNotifier` para saber cuándo re-ejecutar la lógica de redirección. Firebase Auth expone un `Stream`, no un `ChangeNotifier`. Esta pequeña clase hace de puente:

```dart
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    // Cada vez que el stream emite (login, logout...), avisa a GoRouter
    _subscription = stream.listen((_) => notifyListeners());
  }
  late final StreamSubscription _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
```

Gracias a esto, cada vez que el usuario inicia o cierra sesión, GoRouter re-evalúa automáticamente las redirecciones.

---

## 🔒 Protección de rutas

La lógica de protección está en el `redirect` del router:

```dart
redirect: (context, state) {
  final user = FirebaseAuth.instance.currentUser;
  final location = state.matchedLocation;   // ruta que el usuario intenta visitar

  final isAuthRoute = location == '/login' || location == '/register';
  final isProtectedRoute =
      location.startsWith('/profile') || location.startsWith('/reservations');

  // Sin usuario → no puede ir a zonas que requieren sesión
  if (user == null && isProtectedRoute) return AppRoutes.login;

  // Con sesión real (no anónima) → no tiene sentido ir al login o registro
  if (user != null && !user.isAnonymous && isAuthRoute) return AppRoutes.home;

  return null; // null = sin redirección, continúa normal
},
```

**¿Cuándo se ejecuta `redirect`?**
- Al navegar a cualquier ruta
- Automáticamente cada vez que `refreshListenable` notifica un cambio (es decir, cuando cambia el estado de autenticación)

---

## 📝 Constantes de rutas: `AppRoutes`

En lugar de escribir strings a mano por toda la app, todas las rutas están centralizadas en `AppRoutes`:

```dart
class AppRoutes {
  // Rutas simples (constantes)
  static const String home         = '/home';
  static const String login        = '/login';
  static const String register     = '/register';
  static const String profile      = '/profile';
  static const String dishes       = '/dishes';
  static const String menus        = '/menus';
  static const String reservations = '/reservations';
  static const String restaurantForm = '/restaurant/form';

  // Rutas con parámetros (métodos generadores)
  static String profileEdit(String id)          => '/profile/form/$id';
  static String dishDetail(String id)           => '/dishes/detail/$id';
  static String dishFormEdit(String id)         => '/dishes/form/$id';
  static String dishFormCreate()                => '/dishes/form';
  static String menuDetail(String id)           => '/menus/detail/$id';
  static String menuFormEdit(String id)         => '/menus/form/$id';
  static String menuFormCreate()                => '/menus/form';
  static String reservationDetail(String id)    => '/reservations/detail/$id';
  static String reservationFormEdit(String id)  => '/reservations/form/$id';
  static String reservationFormCreate()         => '/reservations/form';
}
```

**Uso correcto:**
```dart
// ✅ Bien — usa la constante
context.go(AppRoutes.dishes);
context.push(AppRoutes.dishDetail(dish.id!));

// ❌ Evitar — string hardcodeado, fácil de romper con un typo
context.go('/dishes');
context.push('/dishes/detail/${dish.id}');
```

---

## 🎨 Cómo se inyectan los ViewModels en las rutas

Cada ruta crea su propio ViewModel con `ChangeNotifierProvider`. Así el ViewModel se crea al entrar a la ruta y se destruye al salir, gestionando automáticamente la memoria.

### Ruta simple (un ViewModel)
```dart
GoRoute(
  path: AppRoutes.dishes,
  builder: (context, state) => ChangeNotifierProvider(
    create: (_) => DishViewModel(DishService())..watchDishes(),
    child: const DishesListView(),
  ),
),
```

`..watchDishes()` usa la cascada de Dart para llamar al método justo después de crear el ViewModel — equivale a crearlo y luego llamar al método en la misma línea.

### Ruta con parámetro en la URL
```dart
GoRoute(
  path: '/dishes/detail/:id',   // :id es el parámetro
  builder: (context, state) {
    final id = state.pathParameters['id']!;   // extrae el valor de la URL
    return ChangeNotifierProvider(
      create: (_) => DishViewModel(DishService()),
      child: DishDetailView(dishId: id),
    );
  },
),
```

### Ruta con varios ViewModels: `MultiProvider`
Algunas pantallas necesitan más de un ViewModel simultáneamente. Para eso se usa `MultiProvider`:

```dart
GoRoute(
  path: AppRoutes.menus,
  builder: (context, state) => MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (_) => MenuViewModel(MenuService(), DishService())..watchMenus(),
      ),
      ChangeNotifierProvider(
        create: (_) => DishViewModel(DishService())..watchDishes(),
      ),
    ],
    child: const MenuListView(),
  ),
),
```

La pantalla de menús necesita los dos porque muestra menús y también necesita los platos disponibles para asignarlos a un menú.

---

## 🚀 Cómo navegar en el código

### `context.go()` — navegar reemplazando el stack
```dart
// Va a la pantalla de inicio (no se puede volver atrás)
context.go(AppRoutes.home);

// Va al detalle de un plato (no se puede volver atrás)
context.go(AppRoutes.dishDetail(dish.id!));
```

### `context.push()` — navegar añadiendo al stack
```dart
// Abre el detalle de un plato (se puede volver con el botón de atrás)
context.push(AppRoutes.dishDetail(dish.id!));
```

**¿Cuándo usar cada uno?**
- `go` → navegación principal (menús del bottom nav, cerrar sesión, ir a home)
- `push` → abrir un detalle o formulario desde dentro de una pantalla

---

## 🔍 Debugging de navegación

Para ver en consola qué rutas está procesando GoRouter, activa los logs en desarrollo:

```dart
GoRouter(
  debugLogDiagnostics: true,  // ← solo en desarrollo
  ...
)
```

---

## 📚 Recursos

- [GoRouter Documentation](https://pub.dev/packages/go_router)
- [Flutter Navigation Guide](https://docs.flutter.dev/development/ui/navigation)
