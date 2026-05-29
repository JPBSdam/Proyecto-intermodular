import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:app_restaurante/data/model/reservation.dart';

// Servicio de email gratuito para SabrosApp usando EmailJS.

class EmailService {
  // ─── Credenciales de EmailJS ─────────────────────────────────────────────
  // Inyectadas en tiempo de compilación con --dart-define.
  // En CI se leen desde GitHub Secrets.
  static const String _serviceId = String.fromEnvironment('EMAILJS_SERVICE_ID');
  static const String _templateId = String.fromEnvironment(
    'EMAILJS_TEMPLATE_ADMIN',
  ); // Template: nuevo aviso a admins
  static const String _templateIdClientConfirm = String.fromEnvironment(
    'EMAILJS_TEMPLATE_CLIENT_CONFIRM',
  ); // Template: confirmación al cliente
  static const String _templateIdCancellationAdmin =
      'template_cancel_account'; // Template: reserva cancelada (plan free — sin secret)
  static const String _publicKey = String.fromEnvironment('EMAILJS_PUBLIC_KEY');
  static const String _privateKey = String.fromEnvironment(
    'EMAILJS_PRIVATE_KEY',
  );

  // URL del endpoint de EmailJS (no cambiar)
  static const String _apiUrl = 'https://api.emailjs.com/api/v1.0/email/send';

  // ─── Enviar email de nueva reserva a TODOS los admins ────────────────────

  static Future<void> sendNewReservationToAdmins(
    Reservation reservation,
  ) async {
    final adminEmails = await _fetchAdminEmails();

    if (adminEmails.isEmpty) {
      debugPrint('[EmailService] ⚠️ No se encontraron admins en Firestore');
      return;
    }

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

    // Enviamos un email a cada admin individualmente
    // (EmailJS free plan no soporta múltiples destinatarios en 1 llamada)
    for (final adminEmail in adminEmails) {
      debugPrint('[EmailService] 📧 Enviando email a admin: $adminEmail');
      await _sendClient(
        templateId: _templateId,
        templateParams: {
          'to_email': adminEmail,
          'time': dateStr,
          'client_name': clientName,
          'reservation_date': dateStr,
          'seats': seats,
          'comments': comments,
        },
      );
    }
  }

  // ─── Enviar email de cancelación por borrado de cuenta a admins ─────────
  static Future<void> sendReservationCancelledToAdmins(
    Reservation reservation,
  ) async {
    if (_templateIdCancellationAdmin.contains('template_cancel_account')) {
      // Plantilla aún no configurada en EmailJS — salta silenciosamente
      // El plan gratuito no permite más de 2 templates
      debugPrint(
        '[EmailService] ⚠️ Template de cancelación no configurado aún',
      );
      return;
    }

    final adminEmails = await _fetchAdminEmails();
    if (adminEmails.isEmpty) return;

    final dateStr = reservation.reservationDate != null
        ? DateFormat(
            "dd/MM/yyyy 'a las' HH:mm",
          ).format(reservation.reservationDate!)
        : 'fecha desconocida';
    final seats = reservation.seats?.toString() ?? '?';

    for (final adminEmail in adminEmails) {
      await _sendClient(
        templateId: _templateIdCancellationAdmin,
        templateParams: {
          'to_email': adminEmail,
          'reservation_date': dateStr,
          'seats': seats,
          'reason': 'El cliente eliminó su cuenta',
        },
      );
    }
  }

  // ─── Obtener emails de los admins desde Firestore ────────────────────────
  static Future<List<String>> _fetchAdminEmails() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'ADMIN')
          .get();

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
  static Future<void> sendReservationConfirmedToClient(
    Reservation reservation,
  ) async {
    if (_templateIdClientConfirm.contains('CAMBIAR_POR')) {
      debugPrint('[EmailService] ⚠️ Template ID para cliente no configurado');
      return;
    }

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
  static Future<void> _sendClient({
    required String templateId,
    required Map<String, String> templateParams,
  }) async {
    if (_publicKey.isEmpty || _serviceId.isEmpty || templateId.isEmpty) {
      debugPrint('[EmailService] ⚠️ Credenciales EmailJS no configuradas (--dart-define)');
      return;
    }
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
