# 🏗️ Arquitectura MVVM

## ¿Qué es MVVM?

MVVM son las siglas de **Model – View – ViewModel**. Es un patrón de arquitectura que divide el código de la app en tres capas con responsabilidades bien separadas. El objetivo es que cada parte sea fácil de entender, modificar y testear por separado.

```
┌─────────────┐     ┌─────────────────┐     ┌───────────────┐
│    Model    │ ←── │   ViewModel     │ ←── │     View      │
│  (datos)    │     │  (lógica de UI) │     │   (pantalla)  │
└─────────────┘     └─────────────────┘     └───────────────┘
```

---

### 🗂️ Model — los datos

Son las clases que representan la información del dominio de la app. En este proyecto están en `lib/data/model/`:

```
lib/data/model/
├── dish.dart         ← Un plato del menú
├── menu.dart         ← Un menú (agrupación de platos)
├── reservation.dart  ← Una reserva de mesa
├── restaurant.dart   ← Información del restaurante
└── user.dart         ← Un usuario registrado
```

Los modelos tienen dos responsabilidades:
1. Representar la estructura del dato (`name`, `price`, `available`…)
2. Convertirse a/desde Firestore (`toFirestore()` y `fromFirestore()`)

```dart
class Dish {
  String? id;
  String? name;
  double? price;
  bool? available;

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'price': price,
    'available': available,
  };

  factory Dish.fromFirestore(DocumentSnapshot doc, _) => Dish(
    id: doc.id,
    name: doc['name'],
    price: doc['price']?.toDouble(),
    available: doc['available'] ?? true,
  );
}
```

Los modelos **no saben nada** de la UI ni de cómo se obtienen los datos.

---

### 🎨 View — la pantalla

Son los widgets de Flutter que definen lo que ve el usuario. Están en `lib/ui/views/`. Las vistas **no tienen lógica de negocio**: solo muestran datos y delegan las acciones al ViewModel.

```dart
// La vista solo delega
ElevatedButton(
  onPressed: () => context.read<DishViewModel>().deleteDish(dish.id!),
  child: const Text('Eliminar'),
)
```

Las vistas usan `context.watch<ViewModel>()` para reconstruirse cuando cambian los datos.

---

### ⚙️ ViewModel — la lógica de la UI

Son clases que extienden `ChangeNotifier`. Hacen de intermediarios: reciben acciones de la vista, hablan con los servicios y notifican a la vista el resultado.

Cada ViewModel gestiona:
- **Estado de carga**: `isLoading` (mientras espera datos)
- **Errores**: `errorMessage` (si algo falla)
- **Datos**: la lista de platos, reservas, etc.
- **Acciones**: crear, editar, borrar, buscar…

```dart
class DishViewModel extends ChangeNotifier {
  final DishService _service;
  DishViewModel(this._service);

  List<Dish> _dishes = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<Dish> get dishes => _dishes;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  Future<void> addDish(Dish dish) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.createDish(dish);
    } catch (e) {
      _errorMessage = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }
}
```

---

## 🔄 Cómo fluyen los datos

```
Usuario pulsa "Eliminar plato"
    ↓
View llama a: context.read<DishViewModel>().deleteDish(id)
    ↓
ViewModel llama a: _service.deleteDish(id)
    ↓
Service llama a: _repository.delete(id)
    ↓
Repository borra el documento en Firestore
    ↓
Firestore actualiza el stream
    ↓
Repository emite la nueva lista por el stream
    ↓
ViewModel recibe la nueva lista → notifyListeners()
    ↓
View se reconstruye con la lista actualizada
```

---

## ✅ Ventajas de MVVM en este proyecto

| Sin MVVM | Con MVVM |
|---|---|
| Firestore mezclado con la UI | La UI nunca toca Firestore directamente |
| Si cambia Firestore, hay que tocar las vistas | Solo hay que tocar el servicio/repositorio |
| Difícil de testear (hay que arrancar Firebase) | Los ViewModels se testean con mocks, sin Firebase real |
| Un widget cargado de lógica y de UI | Separación clara: widget ligero, ViewModel con la lógica |

---

## 🔑 Regla para saber dónde va cada cosa

- **¿Es la estructura del dato?** → `lib/data/model/`
- **¿Es acceso directo a Firestore?** → `lib/data/repositories/`
- **¿Es lógica de negocio o manejo de errores?** → `lib/data/services/`
- **¿Es estado de una pantalla, manejo de carga o errores de UI?** → `lib/ui/viewmodels/`
- **¿Es lo que el usuario ve?** → `lib/ui/views/`