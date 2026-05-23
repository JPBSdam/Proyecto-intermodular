# 👥 Sistema de roles y control de acceso

## Los tres tipos de usuario

La app distingue entre tres estados de usuario, y la interfaz cambia significativamente según cuál sea:

| Tipo | Cómo llega | Qué puede hacer |
|---|---|---|
| **Invitado** | Sesión anónima o sin sesión | Ver carta y menús. No puede reservar ni ver perfil. |
| **Usuario** (USER) | Cuenta registrada con email o Google | Todo lo anterior + reservar mesa + ver su perfil y reservas. |
| **Administrador** (ADMIN) | Cuenta con rol ADMIN en Firestore | Todo lo anterior + gestionar platos, menús, restaurante y todas las reservas. |

---

## ¿Dónde se guarda el rol?

El rol se guarda en el campo `role` del documento del usuario en la colección `users` de Firestore:

```
Firestore
└── users/
    └── {uid}/
        ├── name: "Ana García"
        ├── email: "ana@ejemplo.com"
        ├── role: "ADMIN"         ← puede ser "USER" o "ADMIN"
        └── urlImage: "https://..."
```

Firebase Authentication no sabe nada del rol — solo gestiona si hay sesión o no. El rol es un dato de la app guardado en Firestore.

---

## ¿Cómo lo lee la app?

`HomeViewModel` escucha en tiempo real el documento del usuario en Firestore. Cuando el documento cambia (por ejemplo, si se le asigna el rol ADMIN), la app lo refleja inmediatamente sin necesidad de reiniciar sesión:

```dart
_userSubscription = _userService.watchUser(user.uid).listen((userData) {
  _actualRole = userData?.role?.toUpperCase() ?? 'USER';
  _userName = userData?.name;
  _userPhotoUrl = userData?.urlImage;
  _userGooglePhotoUrl = userData?.googlePhotoUrl;
  notifyListeners();
});
```

Los getters que expone `HomeViewModel` para que el resto de la app consulte el rol:

```dart
String get userRole    // rol efectivo — respeta el previewMode
String get actualRole  // rol real, sin filtros
bool get isGuest       // true si es anónimo o no hay sesión
```

---

## 🎭 Modo vista previa (previewMode)

Los administradores tienen un botón especial para simular la vista de un usuario normal sin cerrar sesión. Es útil para revisar cómo ve la app un cliente.

Cuando `previewMode` está activo:
- `userRole` devuelve `'USER'` en lugar de `'ADMIN'`
- La barra inferior muestra las pestañas de usuario
- Desaparecen los botones y opciones de gestión
- `actualRole` sigue siendo `'ADMIN'` — el rol real no cambia

```dart
void togglePreviewMode() {
  if (_actualRole == 'ADMIN') {
    _previewMode = !_previewMode;
    notifyListeners();
  }
}
```

Solo un admin puede activar el modo vista previa.

---

## 🧭 Cómo cambia la interfaz según el rol

### Barra de navegación inferior

La barra inferior es dinámica: sus pestañas cambian según el tipo de usuario.

```
Invitado:        [INICIO]  [CARTA]  [PERFIL]
Usuario:         [INICIO]  [CARTA]  [RESERVA]   [PERFIL]
Admin:           [INICIO]  [CARTA]  [RESERVAS]  [PERFIL]
                                    (con badge de pendientes)
```

La pestaña central es la que cambia:
- **Sin sesión / invitado**: no aparece pestaña central
- **Usuario normal**: pestaña "RESERVA" que abre el formulario de nueva reserva
- **Admin**: pestaña "RESERVAS" que abre la gestión de todas las reservas, con un badge que muestra cuántas están pendientes de confirmar

### Pantalla principal (Home)

```
Invitado:   Banner "Inicia sesión para reservar" + botón "Reservar" que pide login
Usuario:    Saludo personalizado + botón "Reservar" que va al formulario
Admin:      Igual que usuario + botón "Gestionar restaurante" en la sección del restaurante
```

### Opciones del drawer (menú lateral)

El drawer también muestra opciones diferentes:
- Los admins ven las secciones de administración (restaurante, gestión de reservas)
- Los usuarios normales pueden navegar por el menú y los platos, además de ver y gestionar su perfil
- Los invitados ven un botón para iniciar sesión y pueden navegar por el menú y los platos

---

## 🔒 Protección en el router

GoRouter protege automáticamente las rutas de perfil y reservas para que solo accedan usuarios con sesión real (no anónimos):

```dart
redirect: (context, state) {
  final user = FirebaseAuth.instance.currentUser;
  final isProtectedRoute =
      location.startsWith('/profile') || location.startsWith('/reservations');

  if (user == null && isProtectedRoute) return AppRoutes.login;
  ...
}
```

Sin embargo, el control de qué puede hacer un ADMIN dentro de esas rutas (gestionar platos, confirmar reservas…) se hace en la propia UI comprobando `homeVM.userRole == 'ADMIN'`.

---

## 🔐 Reglas de seguridad en Firestore

El control de acceso también se aplica en el servidor mediante las **Firestore Security Rules**. Aunque la UI no muestre ciertas opciones a un usuario normal, las reglas de Firestore garantizan que tampoco pueda hacer esas operaciones directamente, aunque lo intentara. Las reglas se configuran en la consola de Firebase y son independientes del código de Flutter.

---

## 📚 Recursos

- [Firebase Auth Custom Claims](https://firebase.google.com/docs/auth/admin/custom-claims)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)