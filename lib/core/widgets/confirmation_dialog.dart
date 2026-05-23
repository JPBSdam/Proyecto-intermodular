import 'package:flutter/material.dart';

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
        ElevatedButton(
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
