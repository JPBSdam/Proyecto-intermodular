# Guía de configuración — SabrosApp

Todo lo que necesitas para poner el proyecto a funcionar en tu máquina.

## Requisitos previos

- Flutter 3.44.0 o superior
- Dart 3.9.2 o superior
- Android Studio (para emulador Android o build APK)
- Xcode (solo macOS, para iOS)

## 1. Clonar e instalar dependencias

```bash
git clone https://github.com/JPBSdam/Proyecto-intermodular.git
cd Proyecto-intermodular
flutter pub get
```

## 2. Archivos secretos

Estos archivos **no están en el repo** (están en `.gitignore`). Pídelos a un compañero con acceso por un canal seguro (Drive, no por el chat del proyecto).

| Archivo | Dónde colocarlo |
|---------|-----------------|
| `google-services.json` | `android/app/google-services.json` |
| `sabrosapp.jks` | `android/sabrosapp.jks` |
| `key.properties` | `android/key.properties` |

Contenido de `android/key.properties`:
```properties
storePassword=CONTRASEÑA
keyPassword=CONTRASEÑA
keyAlias=upload
storeFile=../sabrosapp.jks
```

> **Importante:** todos los compañeros deben usar el mismo `sabrosapp.jks`. Si cada uno genera uno distinto, el APK firmado no será compatible y no se podrá publicar ni actualizar.

## 3. Variables de entorno (EmailJS)

Las credenciales de EmailJS no están en el código fuente, se inyectan en tiempo de compilación. Pídelas a un compañero con acceso a los GitHub Secrets.

La forma más cómoda es crear `.vscode/launch.json` (ya está en `.gitignore`, no se sube):

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "SabrosApp (local)",
      "request": "launch",
      "type": "dart",
      "args": [
        "--dart-define=EMAILJS_SERVICE_ID=TU_SERVICE_ID",
        "--dart-define=EMAILJS_PUBLIC_KEY=TU_PUBLIC_KEY",
        "--dart-define=EMAILJS_PRIVATE_KEY=TU_PRIVATE_KEY",
        "--dart-define=EMAILJS_TEMPLATE_ADMIN=TU_TEMPLATE_ADMIN",
        "--dart-define=EMAILJS_TEMPLATE_CLIENT_CONFIRM=TU_TEMPLATE_CLIENT_CONFIRM"
      ]
    }
  ]
}
```

O directamente desde terminal:
```bash
flutter run \
  --dart-define=EMAILJS_SERVICE_ID=TU_SERVICE_ID \
  --dart-define=EMAILJS_PUBLIC_KEY=TU_PUBLIC_KEY \
  --dart-define=EMAILJS_PRIVATE_KEY=TU_PRIVATE_KEY \
  --dart-define=EMAILJS_TEMPLATE_ADMIN=TU_TEMPLATE_ADMIN \
  --dart-define=EMAILJS_TEMPLATE_CLIENT_CONFIRM=TU_TEMPLATE_CLIENT_CONFIRM
```

## 4. Ejecutar la aplicación

```bash
flutter run
```

## Publicar una nueva versión del APK

El APK **no se genera automáticamente** con cada push. Solo se publica cuando creas un tag manualmente. Los cambios de código o documentación que subas a `main` no generan ninguna release por sí solos.

Para publicar, crea un tag siguiendo **versionado semántico** (`vMAYOR.MENOR.PARCHE`):

| Tipo | Cuándo usarlo | Ejemplo |
|------|--------------|---------|
| **PARCHE** | Corrección de un bug | `v1.0.0` → `v1.0.1` |
| **MENOR** | Nueva funcionalidad sin romper nada | `v1.0.1` → `v1.1.0` |
| **MAYOR** | Cambio que rompe compatibilidad con versiones anteriores | `v1.1.0` → `v2.0.0` |

```bash
git tag v1.1.0
git push origin v1.1.0
```

En unos minutos aparece en la pestaña **Releases** del repo con el APK listo para descargar.

## Firebase — huella digital del keystore

Si necesitas añadir o verificar la huella del keystore en Firebase Console:

```bash
keytool -list -keystore android/sabrosapp.jks -alias upload -storepass 'CONTRASEÑA'
```

Ve a **Firebase Console → Configuración del proyecto → tu app Android → Huellas digitales del certificado SHA** y comprueba que el SHA-256 y SHA-1 están añadidos.

> **Importante:** cada vez que añadas una huella nueva en Firebase Console, el `google-services.json` del proyecto queda desactualizado. Tienes que descargarlo manualmente y sustituirlo:
> 1. Firebase Console → Configuración del proyecto → tu app Android → botón **Descargar google-services.json**
> 2. Sustituye `android/app/google-services.json` con el archivo descargado
> 3. Comparte el nuevo archivo con los compañeros (no está en git)
>
> Si no haces esto, las funcionalidades que dependen de Firebase (Google Sign-In, notificaciones push) pueden dejar de funcionar.