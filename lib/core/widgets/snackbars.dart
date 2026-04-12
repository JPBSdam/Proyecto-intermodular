import 'package:flutter/material.dart';

void showSnackBar(
  BuildContext context,
  String message, {
  bool error = false,
  bool success = false,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: success
          ? Colors.green
          : error
          ? Colors.red
          : null,
    ),
  );
}
