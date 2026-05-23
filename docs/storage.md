# 🗄️ Firebase Storage — gestión de imágenes

El proyecto usa **Firebase Storage** para almacenar imágenes de platos, restaurantes y avatares de usuario. Toda la lógica de acceso al storage está encapsulada en dos clases: `StorageRepository` (acceso directo) y `StorageService` (validaciones y manejo de errores).

---

## Arquitectura

```
ViewModel
    ↓
StorageService          ← valida el archivo, construye la ruta, maneja errores
    ↓
StorageRepository       ← sube/borra/obtiene URL en Firebase Storage
    ↓
Firebase Storage
```

`StorageService` es un **singleton**: siempre se trabaja con la misma instancia (`StorageService()`).

---

## Rutas en Firebase Storage

Cada tipo de entidad tiene su propio directorio. Usar un nombre de archivo fijo (`image.jpg`, `avatar.jpg`) significa que subir una imagen nueva **sobrescribe la anterior automáticamente**, sin necesidad de borrar primero.

| Entidad | Ruta |
|---|---|
| Plato | `sabrosaapp/dishes/{dishId}/image.jpg` |
| Restaurante | `sabrosaapp/restaurants/{restaurantId}/image.jpg` |
| Avatar de usuario | `sabrosaapp/users/{userId}/avatar.jpg` |

---

## Validación de imágenes

Antes de subir cualquier archivo, `StorageService` valida:

- **Existencia**: el archivo debe existir en disco.
- **Tamaño**: máximo **2 MB**.
- **Extensión**: solo `jpg`, `jpeg`, `png`, `webp`.

Si la validación falla, se lanza un `ArgumentError` con un mensaje legible que llega al ViewModel como string y se muestra en la UI.

---

## Métodos de `StorageService`

| Método | Qué hace |
|---|---|
| `uploadDishImage(file, dishId)` | Valida, sube y devuelve la URL de descarga |
| `deleteDishImage(urlImage)` | Borra la imagen por su URL de descarga |
| `uploadRestaurantImage(file, restaurantId)` | Igual que dish, para restaurantes |
| `deleteRestaurantImage(urlImage)` | Borra imagen del restaurante |
| `uploadUserAvatar(file, userId)` | Sube avatar y devuelve URL |
| `deleteUserAvatar(urlImage)` | Borra el avatar |

Todos los métodos de subida devuelven `Future<String>` (la URL de descarga pública). Los de borrado devuelven `Future<void>`.

---

## Manejo de errores

`StorageService._handleErrors()` centraliza el tratamiento de excepciones:

| Código Firebase | Mensaje al usuario |
|---|---|
| `object-not-found` | La imagen no existe o ya fue eliminada |
| `unauthorized` | No tienes permisos para acceder a esta imagen |
| `quota-exceeded` | Se ha excedido el límite de almacenamiento |
| `invalid-argument` | Los datos de la imagen no son válidos |
| `cancelled` | La subida de imagen fue cancelada |

---

## Flujo típico: actualizar foto de perfil

```
Usuario selecciona imagen (ImagePickerService)
    ↓
UserViewModel.saveUser(user, imageFile)
    ↓
StorageService.uploadUserAvatar(imageFile, userId)
    ├── _validateImageFile()          ← tamaño, extensión
    ├── StorageRepository.uploadFile() ← sube a sabrosaapp/users/{id}/avatar.jpg
    └── StorageRepository.getDownloadUrl() ← obtiene URL pública
    ↓
user.urlImage = url
StorageService.updateUser(user)       ← guarda la URL en Firestore
```