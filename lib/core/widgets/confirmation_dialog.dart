import 'package:flutter/material.dart';

/// Muestra un diálogo de confirmación con opciones "Sí" y "No".
///
/// - Recibe:
///   • context: contexto de la UI
///   • title: título del diálogo
///   • cuestion: mensaje a mostrar
///
/// - Devuelve:
///   • true → el usuario confirma (Sí)
///   • null → el usuario cancela o pulsa "No"
///
/// Se utiliza para pedir confirmación antes de realizar acciones críticas
/// como eliminar o modificar datos.

Future<bool?> showDialogYesNo(
  BuildContext context, {
  required String title,
  required String cuestion,
}) {
  return showDialog<bool?>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Text(cuestion),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('No'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Sí'),
        ),
      ],
    ),
  );
}
