# Sistema de diseño — SabrosApp

Referencia del sistema visual de la app. Antes de añadir colores, estilos o componentes nuevos, consulta este documento para mantener la coherencia.

---

## Paleta de colores

Todos los colores están centralizados en `lib/core/config/app_theme.dart`. **No uses `Color(0xFF...)` directamente en las vistas** — usa siempre las constantes de `AppTheme`.

| Constante | Hex | Uso |
|---|---|---|
| `brandPrimary` | `#494E2C` | Color principal: botones, iconos, textos de acción |
| `brandSecondary` | `#F1B35D` | Acentos: FAB foreground, detalles cálidos |
| `brandBackground` | `#FDEADF` | Fondo general de la app |
| `brandSurface` | `#FFFFFF` | Fondo de tarjetas y superficies elevadas |
| `brandDetail` | `#C88181` | Etiquetas secundarias: categorías, badge ADMIN |
| `brandSuccess` | `#2E7D32` | Estado positivo: ABIERTO, disponible |
| `brandError` | `#B00020` | Estado negativo: CERRADO, NO DISPONIBLE, errores |
| `brandWarning` | `#ED6C02` | Avisos y estados pendientes |
| `brandInfo` | `#0288D1` | Información neutral |

---

## AppTheme — configuración global

### Tema del material

El tema global se aplica en el `MaterialApp` con `AppTheme.lightTheme`. Incluye configuración predefinida para:

- **AppBar**: fondo `brandBackground`, sin elevación, sin cambio de color al hacer scroll
- **ElevatedButton**: fondo `brandPrimary`, texto blanco, `borderRadius` de 15, elevación 2
- **Card**: fondo `brandSurface`, sin elevación
- **FAB**: fondo `brandPrimary`, icono `brandSecondary`, elevación 3

### Ancho máximo de contenido (responsive)

Para que la app se vea bien en web y tablets, usa estas constantes en lugar de dejar que el contenido se estire a pantalla completa:

```dart
AppTheme.kFormMaxWidth    // 480px — formularios (login, registro)
AppTheme.kContentMaxWidth // 800px — contenido principal (home, listas)
```

**Patrón de uso en vistas:**
```dart
// Para formularios
Center(
  child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: AppTheme.kFormMaxWidth),
    child: ...,
  ),
)

// Para listas con padding lateral calculado
Padding(
  padding: EdgeInsets.symmetric(horizontal: AppTheme.webHPad(context)),
  child: ...,
)
```

`webHPad(context)` devuelve el padding necesario para centrar el contenido a `kContentMaxWidth`. Si la pantalla es más pequeña que el máximo, devuelve `0`.

---

## Componentes reutilizables

### AppBadge

**Ruta:** `lib/core/widgets/app_badge.dart`

Badge de texto para etiquetas de estado, categorías y roles. Siempre usa las variantes predefinidas — solo usa el constructor base si necesitas un color completamente personalizado.

| Variante | Cuándo usarla |
|---|---|
| `AppBadge.success(label: '')` | Estado positivo: ABIERTO, DISPONIBLE |
| `AppBadge.error(label: '')` | Estado negativo: CERRADO, NO DISPONIBLE |
| `AppBadge.warning(label: '')` | Estado pendiente o aviso |
| `AppBadge.detail(label: '')` | Categorías, etiquetas informativas, ADMIN |

Todas las variantes aceptan un `icon` opcional:
```dart
AppBadge.success(label: 'Abierto', icon: Icons.check_circle_outline)
AppBadge.detail(label: 'Italiana')
AppBadge.error(label: 'No disponible')
```

---

### AppLogoTitle

**Ruta:** `lib/core/widgets/app_logo_title.dart`

Logo + nombre de la app. Usa el SVG `assets/cubiertos.svg` coloreado dinámicamente.

```dart
// Uso estándar (toma el color primario del tema)
const AppLogoTitle()

// En drawer u otros fondos oscuros
AppLogoTitle(color: AppTheme.brandSecondary, iconSize: 30)

// En AppBar secundaria (más pequeño)
const AppLogoTitle(fontSize: 14, iconSize: 16)
```

---

### SabrosAppBar

**Ruta:** `lib/core/widgets/sabros_app_bar.dart`

AppBar estándar de la app con dos modos:

```dart
// Solo logo (pantallas principales)
appBar: SabrosAppBar()

// Logo + título de sección (pantallas secundarias)
appBar: SabrosAppBar(pageTitle: 'Iniciar Sesión')

// Con acciones personalizadas
appBar: SabrosAppBar(pageTitle: 'Menús', actions: [IconButton(...)])
```

Incluye una línea divisoria inferior (`outlineVariant` al 50% de opacidad) para separar visualmente el contenido.

---

### LoadingOverlay

**Ruta:** `lib/core/widgets/loading_overlay.dart`

Widget que bloquea la pantalla con un indicador de carga mientras se ejecuta una operación asíncrona. Es el patrón estándar de carga en la app — úsalo en lugar de `CircularProgressIndicator` directamente en el `build`.

```dart
LoadingOverlay(
  isLoading: viewmodel.isLoading,
  child: Scaffold(
    // contenido normal de la pantalla
  ),
)
```

`isLoading` se conecta directamente al getter del ViewModel. Cuando es `true`, superpone un overlay semitransparente que impide interacciones mientras la operación está en curso.

---

## Imágenes de red

Usa siempre `CachedNetworkImage` (paquete `cached_network_image`) en lugar de `Image.network`. Cachea automáticamente las imágenes en disco, reduce peticiones repetidas y proporciona placeholders integrados.

```dart
CachedNetworkImage(
  imageUrl: url,
  width: 60,
  height: 60,
  fit: BoxFit.cover,
  placeholder: (_, __) => Container(
    color: AppTheme.brandPrimary.withAlpha(20),
  ),
  errorWidget: (_, __, ___) => Container(
    color: AppTheme.brandPrimary.withAlpha(20),
    child: const Icon(Icons.restaurant, size: 24),
  ),
)
```

Usa `Image.network` únicamente cuando necesites `webHtmlElementStrategy: WebHtmlElementStrategy.fallback` (imágenes estáticas en web que no se cachean). En esos casos mantén `loadingBuilder` y `errorBuilder`:

```dart
Image.network(
  url,
  fit: BoxFit.cover,
  webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
  loadingBuilder: (_, child, progress) => progress == null
      ? child
      : Container(color: AppTheme.brandPrimary.withAlpha(20)),
  errorBuilder: (_, __, ___) => Container(
    color: AppTheme.brandPrimary.withAlpha(20),
    child: const Icon(Icons.restaurant, size: 32),
  ),
)
```

---

## Botones en formularios

Los botones de acción principal en formularios deben tener ancho completo y altura fija de 50px:

```dart
// Botón principal
SizedBox(
  width: double.infinity,
  height: 50,
  child: ElevatedButton(
    onPressed: ...,
    child: const Text('Acción'),
  ),
)

// Botón secundario (Google, invitado, etc.)
SizedBox(
  width: double.infinity,
  height: 50,
  child: OutlinedButton(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppTheme.brandPrimary,
      side: BorderSide(color: AppTheme.brandPrimary.withAlpha(100)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    ),
    onPressed: ...,
    child: const Text('Acción secundaria'),
  ),
)
```