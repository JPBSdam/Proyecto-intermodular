# 📢 Gestión de estado con Provider

## 🏗️ Conceptos clave

### ViewModel = almacén de datos de la pantalla

Un `ViewModel` es una clase que extiende `ChangeNotifier`. Guarda el estado de la pantalla (datos cargados, si está cargando, mensajes de error…) y avisa a la UI cuando algo cambia.

```dart
class DishViewModel extends ChangeNotifier {
  List<Dish> _dishes = [];
  bool _isLoading = false;

  List<Dish> get dishes => _dishes;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners(); // ← avisa a todos los widgets que escuchan
  }
}
```

### Por qué no usamos `setState`

`setState()` reconstruye **todo** el widget donde se llama, aunque solo haya cambiado un pequeño detalle. `notifyListeners()` solo reconstruye los widgets que están escuchando ese dato concreto, lo que es mucho más eficiente.

---

## 💡 Cómo se pone el ViewModel disponible

El ViewModel se crea al definir la ruta en `app_router.dart`, usando `ChangeNotifierProvider`. Así está disponible para esa pantalla y todos sus widgets hijos:

```dart
GoRoute(
  path: AppRoutes.dishes,
  builder: (context, state) => ChangeNotifierProvider(
    create: (_) => DishViewModel(DishService())..watchDishes(),
    child: const DishesListView(),  // ← la vista y todos sus hijos lo pueden usar
  ),
),
```

El ViewModel se crea al entrar a la ruta y se destruye al salir. No hay que gestionar la memoria manualmente.

---

## 🔧 Cómo consumir el ViewModel en la UI

Hay tres formas principales. Cada una tiene su propósito:

### `context.watch<T>()` — escuchar y reconstruir

Reconstruye el widget cada vez que el ViewModel notifica un cambio. Se usa cuando el widget muestra datos del ViewModel.

```dart
@override
Widget build(BuildContext context) {
  final dishVM = context.watch<DishViewModel>();

  if (dishVM.isLoading) return const CircularProgressIndicator();
  return ListView(children: dishVM.dishes.map(...).toList());
}
```

### `context.read<T>()` — acceder sin escuchar

Solo obtiene el ViewModel para llamar a un método, sin suscribirse a cambios. Se usa en callbacks (pulsaciones de botón, `initState`, etc.) donde no necesitas reconstruir el widget.

```dart
ElevatedButton(
  onPressed: () => context.read<DishViewModel>().deleteDish(dish.id!),
  child: const Text('Eliminar'),
),
```

**Regla práctica**: dentro de `build()` usa `watch`, fuera de `build()` usa `read`.

### `Consumer<T>()` — reconstruir solo una parte

Cuando un widget grande solo necesita reconstruir una parte pequeña, `Consumer` limita la reconstrucción a ese subtárbol:

```dart
Scaffold(
  appBar: AppBar(title: const Text('Platos')),
  body: Consumer<DishViewModel>(
    builder: (context, dishVM, child) {
      // Solo esta parte se reconstruye cuando cambia DishViewModel
      return Text('${dishVM.dishes.length} platos disponibles');
    },
  ),
),
```

---

## 📦 MultiProvider — varias fuentes de estado a la vez

Algunas pantallas necesitan más de un ViewModel simultáneamente. `MultiProvider` los pone todos disponibles en esa ruta:

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

En la vista, cada ViewModel se consume por separado:
```dart
final menuVM  = context.watch<MenuViewModel>();
final dishVM  = context.watch<DishViewModel>();
```

---

## 📋 ViewModels del proyecto

```
lib/ui/viewmodels/
│
├── auth/
│   ├── login_viewmodel.dart       ← Lógica de login (email, Google, anónimo)
│   └── register_viewmodel.dart    ← Lógica de registro y envío de verificación
│
├── firestore/
│   ├── dish_viewmodel.dart        ← CRUD de platos + stream en tiempo real
│   ├── menu_viewmodel.dart        ← CRUD de menús + stream en tiempo real
│   ├── reservation_viewmodel.dart ← CRUD de reservas + conteo de pendientes
│   ├── restaurant_viewmodel.dart  ← Datos del restaurante
│   └── user_viewmodel.dart        ← Datos del perfil de usuario
│
└── home/
    └── home_viewmodel.dart        ← Estado global: rol, nombre, sesión, cerrar sesión
```

---

## 🔄 Flujo completo de datos

Tomando como ejemplo la pantalla de platos:

```
app_router.dart
  └── crea DishViewModel(DishService())..watchDishes()
        ↓
      DishViewModel
        ├── llama a DishService.watchDishes()
        ├── recibe el stream de Firestore
        └── cuando llegan datos → guarda en _dishes → notifyListeners()
              ↓
            DishesListView
              └── context.watch<DishViewModel>() → reconstruye la lista
```

---

## 💡 Cómo se pasan los servicios a los ViewModels

Los ViewModels reciben el servicio que necesitan a través del constructor. Esto es **inyección de dependencias**: el ViewModel no crea el servicio por su cuenta, se lo pasan desde fuera.

```dart
// En app_router.dart, al crear el ViewModel, se le pasa el servicio
create: (_) => DishViewModel(DishService())

// El ViewModel lo guarda
class DishViewModel extends ChangeNotifier {
  final DishService _service;
  DishViewModel(this._service);
}
```

**¿Por qué hacerlo así?**
- Facilita los tests: en los tests se puede pasar un servicio falso (mock) en lugar del real.
- Hace explícito de qué depende cada ViewModel.

---

## 📚 Recursos

- [Provider Package](https://pub.dev/packages/provider)
- [Flutter State Management](https://docs.flutter.dev/data-and-backend/state-mgmt/intro)
- [ChangeNotifier docs](https://api.flutter.dev/flutter/foundation/ChangeNotifier-class.html)
