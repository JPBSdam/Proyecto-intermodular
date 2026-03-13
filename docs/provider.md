# 📢 Explicación del uso de Provider

## 🏗️ Conceptos Clave

### 1. **ViewModel = Almacén de Datos**
Una clase `ViewModel` que extiende de `ChangeNotifier` se convierte en un **almacén donde ir a pedir la información**.

- `ChangeNotifier` es la clase base que notifica los cambios
- Por eso tenemos separado el `home_view.dart` (que solo es la vista)

### 2. **Separación de Responsabilidades**
Separamos:
- **Vista (View)**: `home_view.dart` - Solo UI, lo que se ve
- **Lógica de Vista (ViewModel)**: `home_viewmodel.dart` - Estado y lógica

---

## 💡 Ventajas Principales

### ✅ Sin "Props Drilling"
Simplifica la forma de notificar de un widget a otro que algo ha cambiado **sin tener que pasar por muchas capas** (es decir, hijos de un `Scaffold`, por ejemplo).

Antes:
```dart
// ❌ Pasar datos por 5 niveles
Scaffold → Column → Container → Widget → OtroWidget
```

Ahora:
```dart
// ✅ Acceso directo desde cualquier nivel
Consumer<HomeViewModel>()
```

### ✅ Rendimiento Optimizado
- **`setState()`** reconstruye **TODO** el widget
- **`notifyListeners()`** (método que dice "oye, cambié algo") avisa solo del cambio producido en ese sitio, **reconstruyendo solo lo necesario**

```dart
// En el ViewModel
void loadData() {
  _isLoading = true;
  notifyListeners(); // ← Solo reconstruye los Consumer que escuchan
  // ... lógica ...
  _isLoading = false;
  notifyListeners(); // ← Solo reconstruye los Consumer que escuchan
}
```

---

## 🔧 Cómo Está configurado en nuestro proyecto

### En `app_router.dart` tenemos:

```dart
GoRoute(
  path: AppRoutes.home,
  builder: (context, state) => ChangeNotifierProvider(
    create: (_) => HomeViewModel(),
    child: const HomeScreen(),
  ),
)
```

**¿Qué hace cada parte?**

| Código | ¿Qué hace? |
|--------|-----------|
| `ChangeNotifierProvider` | Construye el "almacén" (hace disponible el ViewModel) |
| `create: (_) => HomeViewModel()` | Función que crea el ViewModel de la home |
| `child: const HomeScreen()` | El widget (y todos sus hijos) pueden acceder al ViewModel |

---

## 📋 Estructura en Nuestro Código

```
lib/ui/
├── viewmodels/
│   └── home/
│       └── home_viewmodel.dart    ← LÓGICA (estado + métodos)
│           ├── isLoading
│           ├── menus
│           ├── errorMessage
│           └── loadHomeData()
│
└── views/
    └── home/
        └── home_view.dart          ← VISTA (solo UI)
            └── Consumer<HomeViewModel>  ← Escucha cambios
```