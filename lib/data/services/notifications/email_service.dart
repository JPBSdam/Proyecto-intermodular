// Servicio de email gratuito para SabrosApp usando EmailJS.
//
// El destinatario se obtiene dinámicamente de Firestore (todos los usuarios ADMIN).
// En la plantilla de EmailJS, el campo "To Email" debe ser {{to_email}}.
// ────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:app_restaurante/data/model/reservation.dart';

class EmailService {
  // ─── Credenciales de EmailJS ─────────────────────────────────────────────
  static const String _serviceId = 'service_5y9zjld'; // EmailJS Service ID
  static const String _templateId =
      'template_7xonz2m'; // Template: nuevo aviso a admins
  static const String _templateIdClientConfirm =
      'template_6ruvyqk'; // Template: confirmación al cliente
  static const String _publicKey = 'N_djxO1LI2WPKf-Jk'; // EmailJS Public Key
  static const String _privateKey =
      'JxxlroAkO5CYOb_M74yqF'; // EmailJS Private Key (modo no-browser)

  // URL del endpoint de EmailJS (no cambiar)
  static const String _apiUrl = 'https://api.emailjs.com/api/v1.0/email/send';

  // ─── Enviar email de nueva reserva a TODOS los admins ────────────────────

  /// Obtiene los emails de todos los admins desde Firestore y envía un email
  /// a cada uno. El campo "To Email" de la plantilla de EmailJS debe ser {{to_email}}.
  static Future<void> sendNewReservationToAdmins(
    Reservation reservation,
  ) async {
    // 1. Buscamos todos los usuarios con role == 'ADMIN' en Firestore
    final adminEmails = await _fetchAdminEmails();

    if (adminEmails.isEmpty) {
      debugPrint('[EmailService] ⚠️ No se encontraron admins en Firestore');
      return;
    }

    // 2. Formateamos la fecha para que sea legible en el email
    final dateStr = reservation.reservationDate != null
        ? DateFormat(
            "dd/MM/yyyy 'a las' HH:mm",
          ).format(reservation.reservationDate!)
        : 'fecha por confirmar';

    final clientName =
        reservation.userName ?? reservation.userEmail ?? 'Cliente';
    final seats = reservation.seats?.toString() ?? '?';
    final comments = reservation.comments?.isNotEmpty == true
        ? reservation.comments!
        : 'Sin comentarios adicionales';

    // 3. Enviamos un email a cada admin individualmente
    //    (EmailJS free plan no soporta múltiples destinatarios en 1 llamada)
    for (final adminEmail in adminEmails) {
      debugPrint('[EmailService] 📧 Enviando email a admin: $adminEmail');
      await _sendClient(
        templateId: _templateId,
        templateParams: {
          // {{to_email}} → destinatario dinámico (campo "To Email" de la plantilla)
          'to_email': adminEmail,
          // {{time}} → aparece en gris bajo "SabrosApp" en el email
          'time': dateStr,
          // {{client_name}} → nombre del cliente en el cuerpo del email
          'client_name': clientName,
          // {{reservation_date}} → fecha y hora de la reserva
          'reservation_date': dateStr,
          // {{seats}} → número de comensales
          'seats': seats,
          // {{comments}} → peticiones especiales del cliente
          'comments': comments,
        },
      );
    }
  }

  // ─── Obtener emails de los admins desde Firestore ────────────────────────

  /// Consulta la colección 'users' buscando documentos con role == 'ADMIN'.
  static Future<List<String>> _fetchAdminEmails() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'ADMIN')
          .get();

      // Extraemos el campo 'email', descartando nulos o vacíos
      return snapshot.docs
          .map((doc) => doc.data()['email'] as String?)
          .whereType<String>()
          .where((e) => e.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('[EmailService] Error al obtener admins: $e');
      return [];
    }
  }

  // ─── Enviar email de confirmación de reserva al CLIENTE ───────────────────

  /// Envía un email al cliente notificándole que su reserva ha sido confirmada
  /// por un admin. Se llama desde ReservationViewModel.confirmReservation().
  static Future<void> sendReservationConfirmedToClient(
    Reservation reservation,
  ) async {
    // Si el Template ID no está configurado, salimos
    if (_templateIdClientConfirm.contains('CAMBIAR_POR')) {
      debugPrint('[EmailService] ⚠️ Template ID para cliente no configurado');
      return;
    }

    // Obtenemos el email del cliente
    final clientEmail = reservation.userEmail;
    if (clientEmail == null || clientEmail.isEmpty) {
      debugPrint('[EmailService] ⚠️ Email del cliente no disponible');
      return;
    }

    final clientName = reservation.userName ?? 'Cliente';
    final dateStr = reservation.reservationDate != null
        ? DateFormat(
            "dd/MM/yyyy 'a las' HH:mm",
          ).format(reservation.reservationDate!)
        : 'fecha por confirmar';
    final seats = reservation.seats?.toString() ?? '?';

    debugPrint(
      '[EmailService] 📧 Enviando confirmación a cliente: $clientEmail',
    );
    await _sendClient(
      templateId: _templateIdClientConfirm,
      templateParams: {
        'to_email': clientEmail,
        'client_name': clientName,
        'reservation_date': dateStr,
        'seats': seats,
      },
    );
  }

  // ─── Llamada HTTP genérica para templates ────────────────────────────────

  /// POST genérico a EmailJS con template customizado.
  static Future<void> _sendClient({
    required String templateId,
    required Map<String, String> templateParams,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'service_id': _serviceId,
          'template_id': templateId,
          'user_id': _publicKey,
          'accessToken': _privateKey,
          'template_params': templateParams,
        }),
      );

      if (response.statusCode != 200) {
        debugPrint(
          '[EmailService] ❌ Error ${response.statusCode}: ${response.body}',
        );
      } else {
        debugPrint(
          '[EmailService] ✅ Email enviado a ${templateParams['to_email']}',
        );
      }
    } catch (e) {
      debugPrint('[EmailService] Excepción al enviar email: $e');
    }
  }
}
