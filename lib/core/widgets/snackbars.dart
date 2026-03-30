import 'package:flutter/material.dart';

void showSnackBar(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: error ? Colors.red : null,
    ),
  );
}
