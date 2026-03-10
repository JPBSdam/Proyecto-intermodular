# 🧪 Guía de tests del proyecto

## 📊 Estado actual: **20 tests pasando ✅**

```bash
flutter test
# Output: 00:01 +20: All tests passed!
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
│   └── models/                   # Tests de modelos de datos
│       ├── dish_test.dart        
│       ├── menu_test.dart        
│       ├── user_test.dart        
│       └── reservation_test.dart
│
└── ui/
    └── viewmodels/               # Tests de ViewModels
        └── home_viewmodel_test.dart
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

## 🔧 Configuración para Mocks (Próximos Pasos)

Para probar servicios que dependen de Firebase, necesitarás agregar estas dependencias:

```yaml
dev_dependencies:
  mockito: ^5.4.0
  build_runner: ^2.4.0
```

Luego generar los mocks:
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
