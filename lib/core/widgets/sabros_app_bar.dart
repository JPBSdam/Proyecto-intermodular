import 'package:flutter/material.dart';

/// AppBar reutilizable que muestra la marca "SabrosApp" en todas las pantallas.
///
/// - Si se pasa [pageTitle], muestra "SabrosApp" en pequeño arriba
///   y el título de la pantalla en grande debajo.
/// - Si no se pasa [pageTitle], muestra únicamente "SabrosApp" como título principal.
///
/// USO:
///   appBar: SabrosAppBar(pageTitle: 'Iniciar Sesión')
///   appBar: SabrosAppBar(pageTitle: 'Menús', actions: [HomeButton()])
///   appBar: SabrosAppBar()  // solo muestra "SabrosApp"
class SabrosAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SabrosAppBar({
    super.key,
    this.pageTitle,
    this.actions,
    this.leading,
    this.backgroundColor,
  });

  /// Título de la pantalla actual (ej: 'Iniciar Sesión', 'Menús', ...).
  /// Si es null, solo se muestra la marca "SabrosApp".
  final String? pageTitle;

  /// Botones o iconos que aparecen a la derecha.
  final List<Widget>? actions;

  /// Widget personalizado para el botón/icono izquierdo (ej: flecha atrás).
  final Widget? leading;

  /// Color de fondo del AppBar. Si es null, usa el tema de la app.
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final hasPageTitle = pageTitle != null && pageTitle!.isNotEmpty;

    return AppBar(
      backgroundColor: backgroundColor,
      leading: leading,
      title: hasPageTitle
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'SabrosApp',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.55),
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  pageTitle!,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
          : const Text('SabrosApp'),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
