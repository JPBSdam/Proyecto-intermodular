# 🧪 Estrategia de Testing - SabrosApp

## 📊 Estado Actual

### ✅ Implementado (20 tests)
```
test/data/models/
├── dish_test.dart          (~6 tests)
├── menu_test.dart          (~4 tests)
├── reservation_test.dart   (~5 tests)
└── user_test.dart          (~5 tests)
```

### ❌ Pendiente (Prioridades)
```
test/data/
├── services/               [Nivel 1: CRÍTICO]
│   ├── firestore_service_test.dart
│   ├── auth_service_test.dart
│   └── storage_service_test.dart
│
├── repositories/           [Nivel 2: ALTO]
│   ├── dish_repository_test.dart
│   ├── menu_repository_test.dart
│   ├── reservation_repository_test.dart
│   └── user_repository_test.dart
│
test/ui/
├── viewmodels/            [Nivel 3: MEDIO]
│   ├── dish_viewmodel_test.dart
│   ├── menu_viewmodel_test.dart
│   ├── reservation_viewmodel_test.dart
│   ├── user_viewmodel_test.dart
│   └── home_viewmodel_test.dart
│
└── views/                  [Nivel 4: BAJO - Widget tests]
    ├── login_view_test.dart
    ├── home_view_test.dart
    └── menu_list_view_test.dart
```

---

## 🎯 Cobertura Esperada

| Capa | Cobertura Actual | Cobertura Meta | Tests Necesarios |
|------|-----------------|---------------|----|
| **Models** | ✅ 100% | ✅ 100% | 0 (DONE) |
| **Services** | ❌ 0% | 🎯 90% | ~15 tests |
| **Repositories** | ❌ 0% | 🎯 85% | ~20 tests |
| **ViewModels** | ❌ 0% | 🎯 80% | ~25 tests |
| **Views** | ❌ 0% | 🎯 70% | ~15 tests |
| **TOTAL** | **20/95** | **~75 tests** | **75 tests** |

---

## 📋 Arquitectura de Tests por Capa

### Nivel 1: Servicios (CRÍTICO) 🔴

**Responsabilidad**: Gestionar conexión con Firebase, manejo de errores centralizado

#### `firestore_service_test.dart` (~8 tests)
```dart
- ✅ Crear documento
- ✅ Leer documento
- ✅ Actualizar documento
- ✅ Eliminar documento
- ✅ Escuchar colección (streams)
- ✅ Manejo de errores (permission-denied, not-found, unavailable)
- ✅ Conversión de datos (toFirestore ↔ fromFirestore)
- ✅ Caché local
```

#### `auth_service_test.dart` (~5 tests)
```dart
- ✅ Registro con email/password
- ✅ Login anónimo
- ✅ Logout
- ✅ Verificar sesión
- ✅ Manejo de errores (usuario existente, credenciales inválidas)
```

#### `storage_service_test.dart` (~2 tests)
```dart
- ✅ Upload de archivos
- ✅ Obtener URL con mock
```

**Herramientas**:
- `fake_cloud_firestore` ✅ (ya está instalado)
- `firebase_auth_mocks` (necesario instalar)
- `mockito` (necesario instalar)

---

### Nivel 2: Repositories (ALTO) 🟠

**Responsabilidad**: Abstracción sobre servicios, operaciones CRUD específicas del dominio

#### `dish_repository_test.dart` (~5 tests)
```dart
- ✅ create(Dish): Crear plato
- ✅ getById(id): Obtener por ID
- ✅ update(Dish): Actualizar plato
- ✅ delete(id): Eliminar plato
- ✅ watchAll(): Stream de todos los platos
```

#### `reservation_repository_test.dart` (~5 tests)
```dart
- ✅ create(Reservation)
- ✅ updateStatus(id, status): Cambiar estado
- ✅ watchByUser(userId): Filtrar por usuario
- ✅ watchAll()
- ✅ delete(id)
```

#### Similar para Menu y User Repositories (10 tests más)

**Patrón**: Mock del servicio, testear lógica repo

```dart
test('getById retorna plato con ID correcto', () async {
  // Arrange
  final fakeFirestore = FakeFirebaseFirestore();
  final repo = DishRepository(); // Inyectar mock del servicio
  
  // Act
  final dish = await repo.getById('123');
  
  // Assert
  expect(dish.id, '123');
});
```

---

### Nivel 3: ViewModels (MEDIO) 🟡

**Responsabilidad**: Lógica de UI, estado, notificaciones

#### `menu_viewmodel_test.dart` (~6 tests)
```dart
- ✅ Inicialización (menus = [])
- ✅ watchMenus() carga datos del repositorio
- ✅ createMenu() agrega a lista y notifica
- ✅ updateMenu() actualiza en lista
- ✅ deleteMenu() elimina y notifica
- ✅ Manejo de errores (try-catch con mensaje)
```

#### `home_viewmodel_test.dart` (~5 tests)
```dart
- ✅ Estado inicial: isGuest = true
- ✅ setUserRole(role) cambia el rol
- ✅ togglePreviewMode() alterna modo admin/cliente
- ✅ isAdmin getter funciona correctamente
- ✅ notifyListeners() se llama en cambios
```

**Patrón**: Mock del repositorio, testear cambios de estado

```dart
test('createMenu agrega item y notifica', () async {
  // Arrange
  final vm = MenuViewModel(mockRepo);
  
  // Act
  await vm.createMenu(testMenu);
  
  // Assert
  expect(vm.menus, contains(testMenu));
  // verify que notifyListeners fue llamado
});
```

**Dependencias necesarias**: `mockito` para mocear repositorios

---

### Nivel 4: Views (BAJO) 🟢

**Responsabilidad**: Tests de widgets, interacción UI

#### `home_view_test.dart` (~3 tests)
```dart
- ✅ Renderiza AppBottomNav correctamente
- ✅ Botón "Nueva reserva" navega a /reservations/form
- ✅ Muestra nombre de usuario desde HomeViewModel
```

#### `login_view_test.dart` (~4 tests)
```dart
- ✅ Campos email/password renderizados
- ✅ Botón login deshabilitado si email vacío
- ✅ Login con email/password navega a home
- ✅ Error en login muestra SnackBar
```

**Patrón**: `WidgetTester`, mocks de servicios

```dart
testWidgets('Login button navigates to home on success', (WidgetTester tester) async {
  // Arrange
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => mockLoginVM),
      ],
      child: const MyApp(),
    ),
  );
  
  // Act
  await tester.enterText(find.byType(TextField).first, 'test@example.com');
  await tester.tap(find.byType(ElevatedButton));
  await tester.pumpAndSettle();
  
  // Assert
  expect(find.byType(HomeView), findsOneWidget);
});
```

---

## 🚀 Cronograma Recomendado

### Semana 1: Servicios
- Lunes-Martes: `firestore_service_test` 
- Miércoles: Instalar `mockito` + `firebase_auth_mocks`
- Jueves-Viernes: `auth_service_test` + `storage_service_test`

### Semana 2: Repositories
- Lunes-Miércoles: Tests de cada repositorio
- Jueves-Viernes: Coverage review con lcov

### Semana 3: ViewModels
- Lunes-Miércoles: ViewModels básicos (menú, usuario)
- Jueves-Viernes: ViewModels complejos (reservas, home)

### Semana 4: Views + Revisión
- Lunes-Miércoles: Widget tests críticos
- Jueves-Viernes: Refactor de tests débiles + meta 75%

---

## 📦 Dependencias Necesarias

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  
  # ✅ Ya instaladas
  fake_cloud_firestore: ^1.5.0
  
  # 🔴 CRÍTICAS - Instalar ahora
  mockito: ^5.4.0
  build_runner: ^2.4.0
  firebase_auth_mocks: ^0.11.0
  
  # 🟡 Opcionales - Después
  integration_test:
    sdk: flutter
  test: ^1.24.0
```

**Instalación inmediata:**
```bash
flutter pub add --dev mockito build_runner firebase_auth_mocks
dart run build_runner build
```

---

## ♿ Inclusividad en Tests

- Todos los textos en español (como el código)
- Tests nombrados claramente (no `test1`, `test2`)
- Comentarios explicativos en código complejo
- Error messages descriptivos

---

## 🔧 Herramientas & Comandos

```bash
# Ejecutar todo
flutter test

# Ejecutar por capa
flutter test test/data/services/
flutter test test/ui/viewmodels/

# Cobertura
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html

# Debug
flutter test --reporter expanded test/data/
```

---

## ✅ Checklist Implementación

```markdown
## Servicios
- [ ] firestore_service_test.dart
- [ ] auth_service_test.dart
- [ ] storage_service_test.dart

## Repositories
- [ ] dish_repository_test.dart
- [ ] menu_repository_test.dart
- [ ] reservation_repository_test.dart
- [ ] user_repository_test.dart

## ViewModels
- [ ] dish_viewmodel_test.dart
- [ ] menu_viewmodel_test.dart
- [ ] reservation_viewmodel_test.dart
- [ ] user_viewmodel_test.dart
- [ ] home_viewmodel_test.dart

## Views
- [ ] home_view_test.dart
- [ ] login_view_test.dart
- [ ] menu_list_view_test.dart

## Meta
- [ ] Cobertura ≥ 75%
- [ ] Todos los tests pasando
- [ ] CI/CD configurado
```

---

## 📚 Referencias

- [Flutter Testing Docs](https://flutter.dev/docs/testing)
- [Mockito Guide](https://pub.dev/packages/mockito)
- [Fake Cloud Firestore](https://pub.dev/packages/fake_cloud_firestore)
- [Test Best Practices](https://dart.dev/guides/language/effective-dart/testing)


