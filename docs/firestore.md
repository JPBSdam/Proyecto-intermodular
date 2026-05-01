# 🔥 Firestore y la capa de datos

## ¿Qué es Firestore?

**Cloud Firestore** es la base de datos del proyecto. Es una base de datos en la nube de Firebase que:
- Guarda datos en documentos organizados en colecciones (parecido a JSON)
- Permite **escuchar cambios en tiempo real**: si un dato cambia en la base de datos, todos los dispositivos conectados lo reciben automáticamente sin tener que pedir los datos de nuevo

---

## 📂 Colecciones de la app

| Colección | Descripción |
|---|---|
| `dishes` | Platos del menú con nombre, precio, categoría, imagen… |
| `menus` | Menús que agrupan platos |
| `reservations` | Reservas de mesa con usuario, fecha, personas, estado |
| `restaurants` | Información del restaurante (nombre, dirección, teléfono…) |
| `users` | Perfiles de usuario con nombre, foto y rol (USER/ADMIN) |

---

## 🏗️ Las tres capas de datos

Para acceder a Firestore, el proyecto usa **tres capas** bien separadas:

```
ViewModel
    ↓ llama a
Service
    ↓ delega en
Repository
    ↓ habla con
Firestore
```

### Por qué tres capas y no una

Podría parecer excesivo, pero cada capa tiene una responsabilidad distinta:

| Capa | Responsabilidad | Ejemplo |
|---|---|---|
| **Repository** | Acceso directo a Firestore. Solo sabe cómo leer/escribir documentos. | `_collection.doc(id).delete()` |
| **Service** | Lógica de negocio y manejo de errores. Traduce excepciones de Firebase a mensajes legibles. | Convierte `FirebaseException(code: 'permission-denied')` en `"No tienes permisos..."` |
| **ViewModel** | Estado de la UI. Gestiona `isLoading`, `errorMessage`, notifica cambios. | Activa `isLoading = true` antes de llamar al service |

---

## Repository — acceso a Firestore

El repositorio contiene el código que habla directamente con Firestore. Implementa las operaciones básicas (CRUD): crear, leer, actualizar, borrar.

```dart
class DishRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _collection => _firestore.collection('dishes');

  // Escucha cambios en tiempo real — emite la lista cada vez que algo cambia
  Stream<List<Dish>> watchAll() {
    return _collection.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => Dish.fromFirestore(doc, null)).toList(),
    );
  }

  // Obtiene todos los documentos una sola vez
  Future<List<Dish>> getAll() async {
    final snapshot = await _collection.get();
    return snapshot.docs.map((doc) => Dish.fromFirestore(doc, null)).toList();
  }

  Future<Dish?> getById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return Dish.fromFirestore(doc, null);
  }

  Future<void> create(Dish dish) async {
    final doc = await _collection.add(dish.toFirestore());
    dish.id = doc.id;  // Firestore genera el id automáticamente
  }

  Future<void> update(Dish dish) async {
    await _collection.doc(dish.id).update(dish.toFirestore());
  }

  Future<void> delete(String id) async {
    await _collection.doc(id).delete();
  }
}
```

---

## Service — lógica de negocio y errores

El servicio recibe las llamadas del ViewModel y las delega al repositorio. Su valor añadido es el manejo centralizado de errores: todos los errores de Firestore pasan por `_handleErrors`, que los traduce a mensajes en español.

```dart
class DishService {
  final DishRepository _repository = DishRepository();

  // Expone el stream del repositorio directamente
  Stream<List<Dish>> watchDishes() => _repository.watchAll();

  Future<void> createDish(Dish dish) async =>
      _handleErrors(() => _repository.create(dish));

  Future<void> updateDish(Dish dish) async =>
      _handleErrors(() => _repository.update(dish));

  Future<void> deleteDish(String id) async =>
      _handleErrors(() => _repository.delete(id));

  // Todos los métodos pasan por aquí — si hay error, lanza un String legible
  Future<T> _handleErrors<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseException catch (e) {
      throw _mapFirebaseException(e);
    } catch (e) {
      throw 'Error inesperado: $e';
    }
  }

  String _mapFirebaseException(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied': return 'No tienes permisos para realizar esta operación.';
      case 'not-found':         return 'El documento no existe.';
      case 'unavailable':       return 'El servicio no está disponible actualmente.';
      default:                  return 'Error de base de datos: ${e.message}';
    }
  }
}
```

---

## 🌊 Streams — datos en tiempo real

La característica más importante de Firestore para este proyecto es que permite **escuchar datos en tiempo real**. En lugar de pedir los datos una vez, se abre un "canal" que emite la lista actualizada cada vez que algo cambia.

```dart
// En el repositorio: un stream que emite cada vez que cambia la colección
Stream<List<Dish>> watchAll() {
  return _collection.snapshots().map(
    (snapshot) => snapshot.docs.map((doc) => Dish.fromFirestore(doc, null)).toList(),
  );
}
```

```dart
// En el ViewModel: se suscribe al stream y actualiza el estado
StreamSubscription? _subscription;

void watchDishes() {
  if (_isWatching) return;  // no resuscribir si ya escucha
  _isWatching = true;

  _subscription = _service.watchDishes().listen(
    (dishes) {
      _dishes = dishes;
      notifyListeners();  // ← avisa a la UI con los nuevos datos
    },
    onError: (e) {
      _errorMessage = e.toString();
      notifyListeners();
    },
  );
}
```

**¿Por qué esto es útil?**
Si el admin añade un plato nuevo, todos los dispositivos que tienen abierta la pantalla de platos lo ven aparecer automáticamente, sin recargar.

---

## 🗺️ Flujo completo de ejemplo: borrar un plato

```
Usuario pulsa "Eliminar" en la vista
    ↓
View: context.read<DishViewModel>().deleteDish(dish.id!)
    ↓
DishViewModel: await _service.deleteDish(id)
  → isLoading = true, notifyListeners()
    ↓
DishService: _handleErrors(() => _repository.delete(id))
    ↓
DishRepository: _collection.doc(id).delete()
    ↓
Firestore: borra el documento
    ↓
Firestore actualiza el stream automáticamente
    ↓
DishRepository.watchAll() emite la lista sin el plato borrado
    ↓
DishViewModel recibe la nueva lista
  → _dishes = nuevaLista, notifyListeners()
    ↓
DishesListView se reconstruye sin ese plato
```

---

## ❌ Errores de Firestore más comunes

| Código Firebase | Mensaje al usuario |
|---|---|
| `permission-denied` | No tienes permisos para realizar esta operación. |
| `not-found` | El documento no existe. |
| `already-exists` | El documento ya existe. |
| `unavailable` | El servicio no está disponible actualmente. |
| `cancelled` | La operación fue cancelada. |
| `invalid-argument` | Los datos proporcionados no son válidos. |
| `deadline-exceeded` | La operación tardó demasiado en completarse. |

---

## 📚 Recursos

- [Cloud Firestore Docs](https://firebase.google.com/docs/firestore)
- [Firestore con Flutter](https://firebase.google.com/docs/firestore/quickstart#dart)
- [cloud_firestore package](https://pub.dev/packages/cloud_firestore)