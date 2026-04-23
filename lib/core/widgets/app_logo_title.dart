import 'package:flutter/material.dart';

/// Widget de branding unificado que muestra el logo y el nombre de la app.
///
/// Se utiliza principalmente en las AppBars de las pantallas principales.
class AppLogoTitle extends StatelessWidget {
  /// Tamaño del icono del logo.
  final double iconSize;

  /// Tamaño de la fuente del texto.
  final double fontSize;

  /// Color opcional para el branding (por defecto usa el color primario del tema).
  final Color? color;

  const AppLogoTitle({
    super.key,
    this.iconSize = 20,
    this.fontSize = 18,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = color ?? Theme.of(context).colorScheme.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: primaryColor.withAlpha(20),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.restaurant_menu,
            color: primaryColor,
            size: iconSize,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'SabrosApp',
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: fontSize,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}
