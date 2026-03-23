import 'package:flutter/material.dart';

Future<bool?> showDialogYesNo(BuildContext context, String content) {
  return showDialog<bool?>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('Confirmación'),
      content: Text(content),
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
