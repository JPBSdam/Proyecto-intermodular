import 'package:flutter/material.dart';

// Overlay reutilizable para bloquear la UI y mostrar una carga centrada.
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final Color barrierColor;
  final Widget? loader;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.barrierColor = const Color(0x40000000),
    this.loader,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return child;

    return Stack(
      children: [
        child,
        Positioned.fill(
          child: AbsorbPointer(child: ColoredBox(color: barrierColor)),
        ),
        Positioned.fill(
          child: Center(child: loader ?? const CircularProgressIndicator()),
        ),
      ],
    );
  }
}
