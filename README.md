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
│   ├── models/              # Modelos de datos (Plato, Menú, Reserva, Usuario)
│   ├── repositories/        # DAOs para acceso a datos
│   └── services/            # Servicios (Firebase, Autenticación)
├── domain/                  # Capa de dominio
│   └── usecases/            # Casos de uso (funcionalidades)
├── ui/                      # Capa de presentación
│   ├── views/               # Pantallas (HomeScreen, LoginScreen, etc.)
│   ├── viewmodels/          # ViewModels (gestión de estado)
│   └── widgets/             # Componentes reutilizables
├── core/                    # Utilidades y configuración
│   ├── navigation/          # Rutas y router (GoRouter)
│   ├── config/              # Tema y configuración
│   └── constants/           # Constantes globales
└── main.dart               # Punto de entrada
```

## 🚀 Empezando

### Requisitos Previos

- Flutter 3.9.2 o superior
- Dart 3.9.2 o superior
- macOS, Linux o Windows
- Xcode (para iOS)
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
- **firebase_core**: Inicialización de Firebase
- **cloud_firestore**: Base de datos en tiempo real
- **go_router**: Navegación con rutas
- **provider**: Gestión de estado
- **json_serializable**: Serialización JSON

## 🧪 Testing

Ejecutar los tests:

```bash
flutter test
```

Ejecutar tests con cobertura:

```bash
flutter test --coverage
```

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

## 👨‍💻 Autores

**Jesús Pablo Bermejo Salar** - [2949625@alu.murciaeduca.es](mailto:2949625@alu.murciaeduca.es)

**Antonia María García Collado** - [3063940@alu.murciaeduca.es](mailto:3063940@alu.murciaeduca.es)

**Raquel Sánchez Guirado** - [3592917@alu.murciaeduca.es](mailto:3592917@alu.murciaeduca.es)
