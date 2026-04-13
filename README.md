# 🍽️ SabrosApp - Aplicación de Restaurante

Una aplicación Flutter moderna para gestionar menús, reservas y autenticación de usuarios en restaurantes.

## 📋 Descripción del proyecto

**SabrosApp** es una aplicación multiplataforma desarrollada en Flutter que permite:

- 🔐 **Autenticación de usuarios** con Firebase
- 📱 **Gestión de menús** con platos disponibles
- 📅 **Sistema de reservas** para clientes
- 👥 **Perfiles de usuario** personalizados
- 🏠 **Interfaz intuitiva** y responsiva

## 🏗️ Arquitectura

El proyecto sigue el patrón **Clean Architecture** con las siguientes capas:

### Estructura de Carpetas
(En desarrollo)
```
lib/
├── data/                    # Capa de datos
│   ├── model/               # Modelos de datos (Dish, Menu, User, Reservation)
│   ├── repositories/        # DAOs para acceso a datos
│   └── services/            # Servicios de Firebase
│       ├── auth/            # Autenticación (AuthService)
│       └── firestore/       # Firestore (DishService, MenuService)
├── ui/                      # Capa de presentación
│   ├── views/               # Pantallas organizadas por feature
│   │   ├── auth/            # Login y Registro
│   │   └── home/            # Pantalla principal (HomeView)
│   ├── viewmodels/          # ViewModels (gestión de estado)
│   │   ├── auth/            # LoginViewModel, RegisterViewModel
│   │   └── home/            # HomeViewModel
│   └── widgets/             # Componentes reutilizables
├── core/                    # Utilidades y configuración
│   ├── navigation/          # Rutas y router (GoRouter)
│   │   ├── app_router.dart
│   │   ├── app_routes.dart
│   │   └── auth_wrapper.dart
│   └── config/              # Tema y configuración Firebase
└── main.dart                # Punto de entrada
```

## 🚀 Empezando

### Requisitos Previos

- Flutter 3.41.0 o superior
- Dart 3.11.0 o superior
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

## 📦 Dependencias Principales
(En desarrollo)
- **firebase_core** (^4.3.0): Inicialización de Firebase
- **firebase_auth** (^6.1.4): Autenticación de usuarios (Email, Google, Anónimo)
- **cloud_firestore** (^6.1.2): Base de datos en tiempo real
- **go_router** (^17.0.1): Navegación declarativa con rutas
- **provider** (^6.1.5+1): Gestión de estado reactivo
- **google_sign_in** (^6.2.2): Login con Google
- **json_annotation** (^4.9.0): Serialización JSON
- **cupertino_icons** (^1.0.8): Iconos de iOS
- **fake_cloud_firestore** (^4.0.0): Mock de Firestore para pruebas
---
## 🔄 GitHub Actions

El proyecto incluye un workflow automático que:

- ✅ Analiza el código con `flutter analyze`
- ✅ Ejecuta tests con `flutter test --coverage`
- ✅ Verifica la calidad del código

## 📱 Plataformas Soportadas

- ✅ **iOS** 
- ✅ **Android** 
- ✅ **Web** 
- ✅ **macOS** 
- ✅ **Windows** 
- ✅ **Linux**

## 📚 Documentación

Consulta la carpeta `docs/` para documentación detallada:

- **[Provider](docs/provider.md)**: Explicación del patrón Provider para el equipo
- **[Autenticación](docs/autenticacion.md)**: Sistema de autenticación con Firebase
- **[Navegación](docs/navegacion.md)**: Sistema de rutas con GoRouter
- **[Tests](test/README.md)**: Guía completa de testing y cobertura

## 👨‍💻 Autores

- **Jesús Pablo Bermejo Salar** - [2949625@alu.murciaeduca.es](mailto:2949625@alu.murciaeduca.es)
- **Antonia María García Collado** - [3063940@alu.murciaeduca.es](mailto:3063940@alu.murciaeduca.es)
- **Raquel Sánchez Guirado** - [3592917@alu.murciaeduca.es](mailto:3592917@alu.murciaeduca.es)
