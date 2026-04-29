import 'package:flutter/material.dart';
import 'package:app_restaurante/core/widgets/app_logo_title.dart';

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
/// Utiliza [AppLogoTitle] para mantener la consistencia visual.

class SabrosAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SabrosAppBar({
    super.key,
    this.pageTitle,
    this.actions,
    this.leading,
    this.backgroundColor,
    this.centerTitle = false,
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
  final bool centerTitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasPageTitle = pageTitle != null && pageTitle!.isNotEmpty;

    return AppBar(
      backgroundColor: backgroundColor ?? colorScheme.surface,
      elevation: 0,
      centerTitle: centerTitle,
      leading: leading,
      title: hasPageTitle
          ? Column(
              crossAxisAlignment: centerTitle
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppLogoTitle(fontSize: 14, iconSize: 16),
                const SizedBox(height: 2),
                Text(
                  pageTitle!,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            )
          : const AppLogoTitle(),
      actions: actions,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(
          height: 1,
          thickness: 1,
          color: colorScheme.outlineVariant.withAlpha(50),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);
}
