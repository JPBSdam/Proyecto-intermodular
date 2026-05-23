# 🔔 Sistema de Notificaciones

El proyecto usa tres canales de notificación combinados: una **cola en Firestore** para enviar pushes a los usuarios, **notificaciones locales** para mostrarlas en pantalla, y **EmailJS** para emails transaccionales a admins y clientes.

---

## Arquitectura general

```
Admin confirma/cancela reserva
    ↓
FcmService.enqueueForUser()       ← escribe en notification_queue en Firestore
    ↓
FcmService.listenToNotificationQueue() (en el dispositivo del cliente)
    ↓
NotificationService.showFromQueue()   ← muestra la notificación local
    ↓
Documento marcado isRead: true        ← no vuelve a mostrarse
```

---

## FCM y la cola de Firestore

En lugar de enviar pushes directamente con Firebase Cloud Messaging (lo que requeriría una Cloud Function o un servidor), el proyecto usa **Firestore como buzón**:

- El admin (o la lógica de negocio) escribe un documento en la colección `notification_queue`.
- El dispositivo del cliente escucha esa colección en tiempo real y muestra la notificación localmente cuando llega un documento nuevo.
- Esto funciona tanto con la app en primer plano como en background (Firestore mantiene el stream activo).

### Ciclo de vida del token FCM

El token FCM identifica un dispositivo para push directo. Se guarda en Firestore para un posible futuro uso con Cloud Functions:

```
Usuario inicia sesión
    ↓
FcmService.saveUserToken(uid)
    ↓
Escribe fcmToken + fcmTokenUpdatedAt en users/{uid}
    ↓
Se suscribe a onTokenRefresh para actualizar si FCM renueva el token
```

```
Usuario cierra sesión / elimina cuenta
    ↓
FcmService.stopListening()
    ↓
Cancela suscripción a notification_queue y a onTokenRefresh
    ↓
anonymize() borra fcmToken del documento en Firestore
```

### Estructura de un documento en `notification_queue`

```
{
  toUserId:      "uid del destinatario",
  title:         "✅ Reserva Confirmada",
  body:          "Tu reserva para el 15/05 ha sido confirmada.",
  type:          "reservation_confirmed" | "reservation_cancelled" | ...,
  reservationId: "id_de_la_reserva"  (opcional, para deep linking)
  isRead:        false,
  createdAt:     Timestamp
}
```

### Métodos principales de `FcmService`

| Método | Cuándo llamarlo |
|---|---|
| `init()` | En `main.dart` antes de `runApp()` |
| `saveUserToken(uid)` | Al iniciar sesión (desde `HomeViewModel`) |
| `listenToNotificationQueue(uid)` | Al iniciar sesión (desde `HomeViewModel`) |
| `stopListening()` | Al cerrar sesión (desde `HomeViewModel`) |
| `enqueueForUser(...)` | Para notificar a un usuario concreto |
| `enqueueForAllAdmins(...)` | Al crear reserva nueva (notifica a todos los admins) |

---

## Notificaciones locales (`NotificationService`)

`NotificationService` usa `flutter_local_notifications` para mostrar notificaciones en pantalla cuando la app está en primer plano (FCM no las muestra automáticamente en ese caso).

Dos puntos de entrada:

- `showFromFcm(title, body)` — llamado desde el listener `FirebaseMessaging.onMessage` cuando llega un push con la app abierta.
- `showFromQueue(title, body, type, reservationId)` — llamado desde `FcmService.listenToNotificationQueue` cuando llega un documento nuevo en la cola. Soporta **deep linking**: si `reservationId` está presente, pulsar la notificación lleva directamente al detalle de esa reserva.

### Configuración por plataforma

Las notificaciones locales requieren configuración nativa mínima:

- **Android**: canal de notificaciones creado con importancia `high` en `NotificationService.init()`.
- **iOS / macOS**: permisos gestionados por `FcmService.init()` con `requestPermission()`.
- **Web / Windows / Linux**: `flutter_local_notifications` no soporta estas plataformas — las notificaciones locales solo funcionan en iOS, Android y macOS.

---

## EmailJS — emails transaccionales

`EmailService` envía emails usando la API HTTP de EmailJS (sin servidor propio). Las credenciales están en constantes privadas de la clase.

### Plantillas configuradas

| Constante | Template ID | Destinatario | Cuándo se envía |
|---|---|---|---|
| `_templateId` | `template_7xonz2m` | Todos los admins | Nueva reserva creada |
| `_templateIdClientConfirm` | `template_6ruvyqk` | Cliente | Reserva confirmada por admin |
| `_templateIdCancellationAdmin` | `template_cancel_account` | Todos los admins | Reserva cancelada por borrado de cuenta |

> La plantilla `template_cancel_account` aún no está creada en EmailJS. Mientras no exista, `sendReservationCancelledToAdmins` detecta el placeholder y omite el envío silenciosamente.

### Parámetros por plantilla

**Nueva reserva (`template_7xonz2m`)**
`to_email`, `time`, `client_name`, `reservation_date`, `seats`, `comments`

**Confirmación al cliente (`template_6ruvyqk`)**
`to_email`, `client_name`, `reservation_date`, `seats`

**Cancelación por borrado de cuenta (`template_cancel_account`)**
`to_email`, `reservation_date`, `seats`, `reason`

### Cómo funciona internamente

`EmailService` consulta Firestore para obtener los emails de todos los admins (`role == 'ADMIN'`), y envía una llamada HTTP individual a EmailJS por cada destinatario (el plan gratuito no admite múltiples destinatarios por llamada).

---

## Flujos completos

### Cliente crea una reserva

```
ReservationViewModel.addReservation()
    ↓
EmailService.sendNewReservationToAdmins()   ← email a cada admin
FcmService.enqueueForAllAdmins()            ← push a cada admin (fire-and-forget)
```

### Admin confirma una reserva

```
ReservationViewModel.confirmReservation()
    ↓
FcmService.enqueueForUser(toUserId: clienteId, type: 'reservation_confirmed')
EmailService.sendReservationConfirmedToClient()   ← email al cliente
```

### Usuario elimina su cuenta

```
UserViewModel.deleteAccount()
    ↓
_cancelActiveReservations()
    ↓ (por cada reserva activa, fire-and-forget)
FcmService.enqueueForAllAdmins(type: 'reservation_cancelled')
EmailService.sendReservationCancelledToAdmins()
```