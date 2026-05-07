# 🧪 Guía de tests del proyecto

## 📊 Estado actual: **107 tests pasando ✅**

```bash
flutter test
# Output: 00:00 +107: All tests passed!
```
---
**Nota**: los tests deben facilitar y mejorar la lógica de nuestro programa, si esto nos supone  un bloqueo o problema, los tests pueden omitirse de forma sencilla para evitar que rompan el workflow:
- Omitir un solo test:
```
test('Descripción del test que quiero omitir', () {
  // Código del test
}, skip: true); // <--- El test se omitirá
```
- Omitir un grupo completo de tests:
```
group('Grupo de tests a omitir', () {
  test('Test 1', () {...});
  test('Test 2', () {...});
}, skip: true); // <--- Todo el grupo se omitirá
```

## 📂 Estructura de Tests

Los tests deben seguir una estructura espejo respecto al código implementado, es por ello que se crean las carpetas acorde a la arquitectura del proyecto:

```
test/
├── README.md                     
├── widget_test.dart              # Test básico del framework
│
├── data/
│   ├── models/                   # Tests de modelos de datos
│   │   ├── dish_test.dart        
│   │   ├── menu_test.dart        
│   │   ├── user_test.dart        
│   │   └── reservation_test.dart
│   │
│   └── services/                 # Tests de servicios
│       ├── auth_service_test.dart
│       └── auth_service_test.mocks.dart  # Generado automáticamente
│
└── ui/
    └── viewmodels/               # Tests de ViewModels
        ├── login_viewmodel_test.dart
        ├── login_viewmodel_test.mocks.dart       # Generado automáticamente
        ├── register_viewmodel_test.dart
        ├── register_viewmodel_test.mocks.dart    # Generado automáticamente
        ├── dish_viewmodel_test.dart
        ├── dish_viewmodel_test.mocks.dart        # Generado automáticamente
        ├── reservation_viewmodel_test.dart
        └── reservation_viewmodel_test.mocks.dart # Generado automáticamente
```

---

## 🎯 Tipos de tests implementados
Los tests siguen el patrón **AAA** (Arrange-Act-Assert): 
- **Arrange**: Preparar datos y estado inicial
- **Act**: Ejecutar la acción a probar
- **Assert**: Verificar el resultado

### 🚨 Es importante tener en cuenta que los tests deben revisarse/actualizarse constantemente si modificamos cualquier parte del código.

---

### 1. **Tests de Modelos** (`test/data/models/`)

Verifican que los modelos de datos funcionen correctamente:
- ✅ Creación de objetos con el constructor
- ✅ Conversión a Firestore (`toFirestore()`)
- ✅ Conversión desde Firestore (`fromFirestore()`)
- ✅ Manejo de campos nulos
- ✅ Método `toString()`
- ✅ Validaciones de datos

**Ejemplo:**
```dart
test('toFirestore convierte correctamente a Map', () {
  // Arrange
  final dish = Dish(name: 'Paella', price: 15.50);
  
  // Act
  final map = dish.toFirestore();
  
  // Assert
  expect(map['name'], 'Paella');
  expect(map['price'], 15.50);
});
```
### 👀 Uso de la dependencia `fake_cloud_firestore`

`fake_cloud_firestore` es una dependencia de desarrollo que proporciona una implementación simulada de Firebase Firestore en memoria. Es esencial para testear modelos y servicios sin depender de una base de datos real:

**¿Por qué es necesaria en este proyecto?**
- **Tests aislados**: Evita conexiones a Firebase durante los tests y por ende, evitamos trastocar datos reales en la base de datos.
- **Velocidad**: Los tests se ejecutan sin latencia de red.
- **Consistencia**: Resultados predecibles y reproducibles.
- **CI/CD**: Permite ejecutar tests en pipelines sin credenciales de Firebase (como nuestro workflow de github actions).
- **Desarrollo local**: No requiere configuración de Firebase real.

---

### 2. **Tests de Servicios** (`test/data/services/`)

Verifican la lógica de negocio de los servicios de datos, aislando las dependencias externas (Firebase, Google Sign-In) mediante mocks:

**`auth_service_test.dart` — 31 tests**
- ✅ `signUpWithEmail`: registro exitoso + errores (contraseña débil, email en uso, email inválido)
- ✅ `signInWithEmail`: login exitoso + errores (usuario no encontrado, contraseña incorrecta, cuenta deshabilitada, demasiados intentos)
- ✅ `signInAnonymously`: sesión anónima
- ✅ `signInWithGoogle`: cancela, PlatformException cancelada (x2), PlatformException otro, éxito, FirebaseAuthException
- ✅ `signOut`: con/sin sesión Google activa + cierre de Firebase
- ✅ `currentUser`: sin sesión / con sesión
- ✅ `isAnonymous`: sin usuario / usuario normal / anónimo
- ✅ `isEmailVerified`: sin usuario / verificado / no verificado
- ✅ `authStateChanges`: emite usuario al login, emite null al logout
- ✅ `resetPassword`: éxito + error usuario no encontrado

#### Herramientas de mocking para servicios

| Dependencia | Rol |
|---|---|
| `firebase_auth_mocks` | Implementación falsa de `FirebaseAuth` que simula el comportamiento real sin conexión |
| `mock_exceptions` | Permite configurar qué excepciones lanza `MockFirebaseAuth` en cada test |
| `mockito` + `@GenerateMocks` | Genera mocks para `GoogleSignIn`, `GoogleSignInAccount` y `GoogleSignInAuthentication` |

#### Patrón para testear errores de Firebase

```dart
// Configura MockFirebaseAuth para que lance un error concreto
whenCalling(Invocation.method(#signInWithEmailAndPassword, null, {}))
    .on(mockAuth)
    .thenThrow(FirebaseAuthException(code: 'wrong-password'));

// Verifica que el servicio traduce el error al mensaje en español
await expectLater(
  authService.signInWithEmail(email: 'user@test.com', password: 'mal'),
  throwsA('Contraseña incorrecta.'),
);
```

#### Inyección de dependencias

Para poder inyectar los mocks, `AuthService` acepta dependencias opcionales en el constructor. El código de producción no cambia (`AuthService()` sigue funcionando igual):

```dart
// Producción — usa las instancias reales
final service = AuthService();

// Tests — inyecta los mocks
final service = AuthService(auth: mockAuth, googleSignIn: mockGoogleSignIn);
```

#### Regenerar los mocks tras cambios en las clases mockeadas

```bash
dart run build_runner build
```

---

### 3. **Tests de ViewModels** (`test/ui/viewmodels/`)

Verifican la lógica de presentación: estado inicial, ciclo de carga, propagación de errores y notificaciones a la UI mediante `notifyListeners()`.

**`login_viewmodel_test.dart` — 16 tests**
- ✅ Estado inicial (`isLoading`, `errorMessage`)
- ✅ `signInWithEmail`: éxito, error, `isLoading` al terminar, limpieza del error previo, `notifyListeners`
- ✅ `signInWithGoogle`: éxito, cancelación (retorna `null`), error
- ✅ `signInAnonymously`: éxito, error
- ✅ `resetPassword`: éxito, error

**`register_viewmodel_test.dart` — 7 tests**
- ✅ Estado inicial
- ✅ `signUpWithEmail`: éxito + envío de verificación, error en registro, fallo en verificación sigue devolviendo `true`, `isLoading` al terminar, `notifyListeners`

**`dish_viewmodel_test.dart` — 16 tests**
- ✅ Estado inicial (`dishes`, `isLoading`, `errorMessage`, `isWatchingDishes`)
- ✅ `watchDishes`: recibe datos, no re-suscribe, lista vacía, `notifyListeners`
- ✅ `addDish`: delega al servicio, `errorMessage` en fallo, `isLoading` al terminar
- ✅ `updateDish`: delega al servicio, `errorMessage` en fallo
- ✅ `deleteDish`: delega al servicio, `errorMessage` en fallo
- ✅ `fetchDishById`: retorna plato, retorna `null` en fallo

**`reservation_viewmodel_test.dart` — 20 tests**
- ✅ Estado inicial (`reservations`, `isLoading`, `errorMessage`, `isWatching`, `pendingCount`)
- ✅ `watchAll`: recibe lista, no re-suscribe, `isWatching` activo
- ✅ `watchByUser`: recibe lista filtrada, no re-suscribe mismo userId, re-suscribe al cambiar userId
- ✅ `pendingCount`: cuenta solo las `pending`, cero sin pendientes
- ✅ `confirmReservation`: delega con estado `confirmed`, `errorMessage` en fallo
- ✅ `cancelReservation`: delega con estado `cancelled`
- ✅ `completeReservation`: delega con estado `completed`
- ✅ `completeMultipleReservations`: delega con lista de ids
- ✅ `addReservation`: delega al servicio, `errorMessage` en fallo
- ✅ `deleteReservation`: delega al servicio

#### Herramientas de mocking para ViewModels

| Dependencia | Rol |
|---|---|
| `mockito` + `@GenerateMocks` | Genera mocks estrictos para `AuthService`, `DishService` y `ReservationService` |
| `_FakeUserCredential extends Fake` | Tipo mínimo que implementa `UserCredential` sin métodos reales, necesario para stubear retornos de login |
| `StreamController.broadcast()` | Simula los streams de Firestore en tiempo real dentro de los tests |

#### Patrón para tests de streams

```dart
setUp(() {
  streamController = StreamController<List<Dish>>.broadcast();
  when(mockService.watchDishes()).thenAnswer((_) => streamController.stream);
  dishVM = DishViewModel(mockService);
});

test('actualiza dishes cuando el stream emite datos', () async {
  dishVM.watchDishes();
  streamController.add([testDish]);
  await Future.microtask(() {}); // deja que el evento se procese

  expect(dishVM.dishes, hasLength(1));
});
```

---

## 🚀 Comandos para ejecutar Tests

### Ejecutar todos los tests
```bash
flutter test
```

### Ejecutar tests con cobertura
```bash
flutter test --coverage
```

### Ejecutar un archivo específico
```bash
flutter test test/data/models/dish_test.dart
```

### Ejecutar tests de una carpeta
```bash
flutter test test/data/models/
```

### Ver output detallado
```bash
flutter test --reporter expanded
```

---
## 🔧 Instalación de lcov
### ¿Qué es lcov?
LCOV en Flutter es una herramienta utilizada para medir, analizar y visualizar la cobertura de código (qué partes del código Dart son ejecutadas por los tests). Genera reportes detallados, usualmente en formato HTML, a partir del archivo lcov.info. De esta forma, nos será más fácil identificar aquellas partes del código desarrollado que no han sido testeadas.

### Instalación y visualización del reporte de cobertura en HTML

**macOS:**
```bash
# 1. Generar cobertura
flutter test --coverage

# 2. Instalar lcov (si no lo tienes)
brew install lcov

# 3. Generar reporte HTML
genhtml coverage/lcov.info -o coverage/html

# 4. Abrir reporte en navegador
open coverage/html/index.html
```

**Windows:**
```powershell
# 1. Generar cobertura
flutter test --coverage

# 2. Instalar Perl (requerido para lcov, solo primera vez)
# Descargar desde: https://strawberryperl.com/

# 3. Instalar lcov usando Chocolatey (solo primera vez)
choco install lcov

# 4. Generar reporte HTML
perl C:\ProgramData\chocolatey\lib\lcov\tools\bin\genhtml coverage\lcov.info -o coverage\html

# 5. Abrir reporte en navegador
start coverage\html\index.html
```

**Linux:**
```bash
# 1. Generar cobertura
flutter test --coverage

# 2. Instalar lcov (si no lo tienes)
sudo apt-get install lcov

# 3. Generar reporte HTML
genhtml coverage/lcov.info -o coverage/html

# 4. Abrir reporte en navegador
xdg-open coverage/html/index.html
```

---

### Interpretar el reporte
- **Verde**: Código cubierto por tests ✅
- **Rojo**: Código NO cubierto ❌
- **Porcentaje**: % de líneas cubiertas
---

## 🎓 Tipos de Matchers Usados

```dart
expect(value, equals(10));           // Igualdad
expect(value, isNotNull);            // No nulo
expect(list, isEmpty);               // Lista vacía
expect(list, isNotEmpty);            // Lista con elementos
expect(list, hasLength(3));          // Longitud específica
expect(list, contains('item'));      // Contiene elemento
expect(string, contains('texto'));   // Substring
expect(value, isA<String>());        // Tipo específico
expect(value, greaterThan(5));       // Mayor que
expect(map.containsKey('key'), true); // Contiene clave
```

---

## 🔧 Dependencias de testing activas

Las siguientes dependencias de desarrollo están configuradas en `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.6.4           # Generación de mocks con @GenerateMocks
  build_runner: ^2.15.0     # Ejecuta la generación de código
  fake_cloud_firestore: ^4.0.0   # Firestore en memoria para tests
  firebase_auth_mocks: ^0.15.1   # Implementación falsa de FirebaseAuth
  mock_exceptions: ^0.8.2        # Configura excepciones en firebase_auth_mocks
```

Para regenerar los mocks tras modificar alguna clase mockeada:
```bash
dart run build_runner build
```
---

## 💡 Tips para seguir buenas prácticas en la creación de tests

1. **Ejecuta tests frecuentemente**: Cada vez que hagas un cambio. Nos aseguramos que no se ha roto nada y si hay cambio de lógica que rompe tests, implica revisar y corregir.
2. **Escribe el test antes**: TDD (Test-Driven Development) cuando sea posible.
3. **Tests pequeños y específicos**: Un test, una responsabilidad.
4. **Nombres claros**: El nombre del test debe explicar qué falla si no pasa.
5. **Revisa la cobertura**: Usa lcov para ver qué falta testear.

---

## 🐛 Debugging tests

Si un test falla:
```bash
# Ver output detallado
flutter test --reporter expanded

# Ejecutar solo un test específico
flutter test --name "nombre del test"

# Ver stack trace completo
flutter test --verbose

# Usa la función debug para ver paso a paso el código
```

---

## 📚 Recursos adicionales

- [Flutter Testing](https://docs.flutter.dev/testing)
- [Effective Dart: Testing](https://dart.dev/guides/language/effective-dart/testing)
- [Mockito Documentation](https://pub.dev/packages/mockito)
- [LCOV Documentation](https://github.com/linux-test-project/lcov)
