# 🍽️ SabrosApp - Aplicación de Restaurante

Una aplicación Flutter moderna para gestionar menús, reservas y autenticación de usuarios en restaurantes.

## 📋 Descripción del proyecto

**SabrosApp** es una aplicación multiplataforma desarrollada en Flutter que permite:

- 🔐 **Autenticación de usuarios** con Firebase (Email, Google) — sesión anónima automática para usuarios sin cuenta
- 📱 **Gestión de menús y platos** con disponibilidad, listado, detalle y búsqueda
- 📅 **Sistema de reservas** para clientes con confirmación y notificaciones
- 🏪 **Gestión de restaurante** con información y configuración
- 👥 **Perfiles de usuario** personalizados con foto y datos editables
- 🔔 **Notificaciones push** (FCM) y locales para reservas y novedades
- 🏠 **Interfaz intuitiva**, responsiva y adaptada a web, móvil y escritorio

## 🏗️ Arquitectura

El proyecto sigue el patrón **MVVM (Model-View-ViewModel)** con arquitectura limpia en capas:

### Estructura de carpetas

```
lib/
├── core/                        # Utilidades y configuración global
│   ├── config/
│   │   └── app_theme.dart       # Tema visual, colores y constantes responsive
│   ├── navigation/
│   │   ├── app_router.dart      # Configuración de GoRouter con guards de auth
│   │   └── app_routes.dart      # Definición de rutas
│   └── widgets/                 # Componentes reutilizables
│       ├── app_badge.dart
│       ├── app_bottom_nav.dart
│       ├── app_card.dart
│       ├── app_drawer.dart
│       ├── app_inputs.dart
│       ├── app_logo_title.dart
│       ├── app_user_avatar.dart
│       ├── confirmation_dialog.dart
│       ├── fcm_init_wrapper.dart
│       ├── home_button.dart
│       ├── image_selector_card.dart
│       ├── image_source_sheet.dart
│       ├── loading_overlay.dart
│       ├── sabros_app_bar.dart
│       ├── snackbars.dart
│       └── verification_banner.dart
├── data/                        # Capa de datos
│   ├── model/                   # Modelos de dominio
│   │   ├── dish.dart
│   │   ├── menu.dart
│   │   ├── reservation.dart
│   │   ├── restaurant.dart
│   │   └── user.dart
│   ├── repositories/            # Repositorios (acceso a datos)
│   │   ├── dish_repository.dart
│   │   ├── menu_repository.dart
│   │   ├── reservation_repository.dart
│   │   ├── restaurant_repository.dart
│   │   └── user_repository.dart
│   └── services/                # Servicios externos
│       ├── auth/
│       │   └── auth_service.dart
│       ├── firestore/
│       │   ├── dish_service.dart
│       │   ├── menu_service.dart
│       │   ├── reservation_service.dart
│       │   ├── restaurant_service.dart
│       │   └── user_service.dart
│       ├── notifications/
│       │   ├── email_service.dart         # Emails transaccionales (EmailJS)
│       │   ├── fcm_service.dart           # Firebase Cloud Messaging
│       │   └── notification_service.dart  # Notificaciones locales
│       └── storage/
│           ├── image_picker_service.dart
│           └── storage_service.dart   # Firebase Storage
├── ui/                          # Capa de presentación
│   ├── viewmodels/              # Gestión de estado por feature
│   │   ├── auth/
│   │   │   ├── login_viewmodel.dart
│   │   │   └── register_viewmodel.dart
│   │   ├── firestore/
│   │   │   ├── dish_viewmodel.dart
│   │   │   ├── menu_viewmodel.dart
│   │   │   ├── reservation_viewmodel.dart
│   │   │   ├── restaurant_viewmodel.dart
│   │   │   └── user_viewmodel.dart
│   │   └── home/
│   │       └── home_viewmodel.dart
│   └── views/                   # Pantallas organizadas por feature
│       ├── auth/
│       │   ├── login_view.dart
│       │   └── register_view.dart
│       ├── data/
│       │   ├── dishes/
│       │   │   ├── dish_details_view.dart
│       │   │   ├── dish_form_view.dart
│       │   │   └── dish_list_view.dart
│       │   ├── menus/
│       │   │   ├── menu_details_view.dart
│       │   │   ├── menu_form_view.dart
│       │   │   └── menu_list_view.dart
│       │   ├── notifications/
│       │   │   └── admin_notifications_view.dart
│       │   ├── profile/
│       │   │   ├── user_form_view.dart
│       │   │   └── user_profile_view.dart
│       │   ├── reservations/
│       │   │   ├── reservation_detail_view.dart
│       │   │   ├── reservation_form_view.dart
│       │   │   └── reservation_list_view.dart
│       │   └── restaurant/
│       │       └── restaurant_form_view.dart
│       └── home/
│           └── home_view.dart
├── firebase_options.dart
├── main.dart
└── my_app.dart
```

## 🚀 Empezando

### Requisitos previos

- Flutter 3.41.0 o superior
- Dart 3.9.2 o superior
- macOS, Linux o Windows
- Xcode (para iOS, solo en macOS)
- Android Studio (para Android)

### Instalación

1. **Clonar el repositorio**
   ```bash
   git clone https://github.com/JPBSdam/Proyecto-intermodular.git
   cd Proyecto-intermodular
   ```

2. **Instalar dependencias**
   ```bash
   flutter pub get
   ```

3. **Ejecutar la aplicación**
   ```bash
   flutter run
   ```

## 📦 Dependencias

### Producción

| Dependencia | Versión | Propósito |
|---|---|---|
| **firebase_core** | ^4.3.0 | Inicialización de Firebase |
| **firebase_auth** | ^6.1.4 | Autenticación (Email, Google, anónima automática) |
| **cloud_firestore** | ^6.1.2 | Base de datos en tiempo real |
| **firebase_storage** | ^13.3.0 | Almacenamiento de imágenes |
| **firebase_messaging** | ^16.1.1 | Notificaciones push (FCM) |
| **provider** | ^6.1.5+1 | Gestión de estado reactiva |
| **go_router** | ^17.0.1 | Navegación declarativa con guards |
| **google_sign_in** | ^6.2.2 | Login con Google |
| **cached_network_image** | ^3.2.3 | Imágenes de red con caché en disco |
| **image_picker** | ^1.1.0 | Selección de imágenes desde galería/cámara |
| **permission_handler** | ^11.4.0 | Gestión de permisos nativos |
| **flutter_local_notifications** | ^18.0.1 | Notificaciones locales (reservas, recordatorios) |
| **flutter_timezone** | ^5.0.2 | Zona horaria local del dispositivo |
| **timezone** | ^0.9.4 | Soporte de zonas horarias para notificaciones |
| **flutter_svg** | ^2.0.17 | Renderizado de imágenes SVG |
| **flutter_localizations** | SDK | Localización (español) |
| **intl** | ^0.20.2 | Internacionalización y formato de fechas |
| **http** | ^1.2.2 | Peticiones HTTP |
| **json_annotation** | ^4.9.0 | Serialización JSON |
| **cupertino_icons** | ^1.0.8 | Iconos nativos de iOS |

### Desarrollo y testing

| Dependencia | Versión | Propósito |
|---|---|---|
| **flutter_lints** | ^5.0.0 | Análisis estático de código |
| **build_runner** | ^2.15.0 | Generador de código |
| **json_serializable** | ^6.11.1 | Generación de serialización JSON |
| **fake_cloud_firestore** | ^4.0.0 | Mock de Firestore para tests |
| **firebase_auth_mocks** | ^0.15.1 | Mock de Firebase Auth para tests |
| **mockito** | ^5.6.4 | Generación de mocks |
| **mock_exceptions** | ^0.8.2 | Excepciones simuladas en tests |
| **flutter_launcher_icons** | ^0.14.3 | Generación de iconos de la app |

## 🔄 GitHub Actions

El proyecto incluye un workflow automático que:

- ✅ Analiza el código con `flutter analyze`
- ✅ Ejecuta tests con `flutter test --coverage`
- ✅ Verifica la calidad del código

## 📱 Plataformas soportadas

- ✅ **iOS**
- ✅ **Android**
- ✅ **Web**
- ✅ **macOS**
- ✅ **Windows**
- ✅ **Linux**

## 📚 Documentación

Consulta la carpeta `docs/` para documentación detallada:

- **[MVVM](docs/mvvm.md)**: Arquitectura del proyecto — qué hace cada capa y por qué
- **[Provider](docs/provider.md)**: Gestión de estado con Provider y ViewModels
- **[Autenticación](docs/autenticacion.md)**: Sistema de autenticación con Firebase
- **[Navegación](docs/navegacion.md)**: Sistema de rutas con GoRouter
- **[UI y sistema de diseño](docs/ui_sistema_diseno.md)**: Guía de componentes y estilo visual
- **[Firestore](docs/firestore.md)**: Capa de datos — repositorios, servicios y streams en tiempo real
- **[Notificaciones](docs/notificaciones.md)**: FCM, cola de Firestore, notificaciones locales y EmailJS
- **[Storage](docs/storage.md)**: Firebase Storage — subida y gestión de imágenes
- **[Roles](docs/roles.md)**: Sistema de roles ADMIN/USER y cómo cambia la interfaz
- **[Tests](test/README.md)**: Guía completa de testing y cobertura

## 👨‍💻 Autores

- **Jesús Pablo Bermejo Salar** - [2949625@alu.murciaeduca.es](mailto:2949625@alu.murciaeduca.es)
- **Antonia María García Collado** - [3063940@alu.murciaeduca.es](mailto:3063940@alu.murciaeduca.es)
- **Raquel Sánchez Guirado** - [3592917@alu.murciaeduca.es](mailto:3592917@alu.murciaeduca.es)