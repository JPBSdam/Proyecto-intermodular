import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Widget de branding unificado que muestra el logo y el nombre de la app.
///
/// Se utiliza principalmente en las AppBars de las pantallas principales.
class AppLogoTitle extends StatelessWidget {
  final double iconSize;
  final double fontSize;

  /// Color opcional para el branding (por defecto usa el color primario del tema).
  final Color? color;

  const AppLogoTitle({
    super.key,
    this.iconSize = 28,
    this.fontSize = 18,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = color ?? Theme.of(context).colorScheme.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          'assets/cubiertos.svg',
          width: iconSize,
          height: iconSize,
          colorFilter: color != null
              ? ColorFilter.mode(color!, BlendMode.srcIn)
              : null,
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
