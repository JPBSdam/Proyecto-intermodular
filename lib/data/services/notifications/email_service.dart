// Servicio de email gratuito para SabrosApp usando EmailJS.
//
// ¿Por qué EmailJS?
//  - 100% gratuito: 200 emails/mes sin servidor ni tarjeta de crédito
//  - Funciona desde el propio cliente Flutter (llamada HTTP directa)
//  - Compatible con el plan Spark de Firebase (sin Cloud Functions)
//
// ─── SETUP (5 minutos) ──────────────────────────────────────────────────────
//  1. Ve a https://www.emailjs.com → crea cuenta gratuita
//  2. "Add New Service" → conecta tu Gmail → copia el Service ID
//  3. "Email Templates" → crea plantilla con estas variables:
//       {{to_email}}         → email del admin destinatario
//       {{client_name}}      → nombre del cliente
//       {{reservation_date}} → fecha y hora de la reserva
//       {{seats}}            → número de comensales
//       {{comments}}         → comentarios especiales
//  4. Copia el Template ID
//  5. Cuenta → "API Keys" → copia tu Public Key
//  6. Sustituye las 3 constantes de abajo con tus valores reales
// ────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'package:app_restaurante/data/model/reservation.dart';

class EmailService {
  // ─── Credenciales de EmailJS ─────────────────────────────────────────────
  // Sustituye estos valores con los de TU cuenta de EmailJS
  static const String _serviceId  = 'service_w1yyd0c';   // EmailJS Service ID
  static const String _templateId = 'template_7xonz2m';  // EmailJS Template ID
  static const String _publicKey  = 'N_djxO1LI2WPKf-Jk';   // EmailJS Public Key

  // URL del endpoint de EmailJS (no cambiar)
  static const String _apiUrl = 'https://api.emailjs.com/api/v1.0/email/send';

  // ─── Enviar email de nueva reserva a todos los admins ────────────────────

  /// Envía un email a TODOS los admins cuando un cliente hace una nueva reserva.
  /// Se llama desde ReservationViewModel.addReservation() al crear la reserva.
  static Future<void> sendNewReservationToAdmins(Reservation reservation) async {
    // Si no hay credenciales configuradas aún, salimos sin error
    if (_serviceId == 'YOUR_SERVICE_ID') return;

    // 1. Obtenemos la lista de emails de todos los admins desde Firestore
    final adminEmails = await _fetchAdminEmails();
    if (adminEmails.isEmpty) return;

    // 2. Formateamos la fecha para que sea legible en el email
    final dateStr = reservation.reservationDate != null
        ? DateFormat("dd/MM/yyyy 'a las' HH:mm").format(reservation.reservationDate!)
        : 'fecha por confirmar';

    // 3. Nombre del cliente que hizo la reserva
    final clientName = reservation.userName ?? reservation.userEmail ?? 'Cliente';

    // 4. Número de comensales
    final seats = reservation.seats?.toString() ?? '?';

    // 5. Comentarios adicionales
    final comments = reservation.comments?.isNotEmpty == true
        ? reservation.comments!
        : 'Sin comentarios adicionales';

    // 6. Enviamos un email individualmente a cada admin
    //    (EmailJS free plan no soporta múltiples destinatarios en 1 llamada)
    for (final adminEmail in adminEmails) {
      await _send(templateParams: {
        // Destinatario (campo "To Email" de la plantilla EmailJS → {{to_email}})
        'to_email':         adminEmail,
        // {{time}} → momento en que se creó la reserva (aparece en gris bajo el título)
        'time':             dateStr,
        // {{client_name}} → nombre del cliente que aparece en la lista del email
        'client_name':      clientName,
        // {{reservation_date}} → fecha y hora de la reserva solicitada
        'reservation_date': dateStr,
        // {{seats}} → número de comensales
        'seats':            seats,
        // {{comments}} → comentarios especiales del cliente
        'comments':         comments,
      });
    }
  }

  // ─── Obtener emails de los admins desde Firestore ────────────────────────

  /// Consulta Firestore para obtener los emails de todos los usuarios ADMIN.
  static Future<List<String>> _fetchAdminEmails() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'ADMIN')
          .get();

      // Extraemos el campo 'email', filtrando los nulos
      return snapshot.docs
          .map((doc) => doc.data()['email'] as String?)
          .whereType<String>()
          .toList();
    } catch (e) {
      // ignore: avoid_print
      print('[EmailService] Error al obtener emails de admins: $e');
      return [];
    }
  }

  // ─── Llamada HTTP al API de EmailJS ──────────────────────────────────────

  /// Realiza el POST al endpoint de EmailJS con los parámetros de la plantilla.
  static Future<void> _send({required Map<String, String> templateParams}) async {
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'service_id':      _serviceId,
          'template_id':     _templateId,
          'user_id':         _publicKey,
          'template_params': templateParams,
        }),
      );

      if (response.statusCode != 200) {
        // ignore: avoid_print
        print('[EmailService] Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      // ignore: avoid_print
      print('[EmailService] Excepción al enviar email: $e');
    }
  }
}





