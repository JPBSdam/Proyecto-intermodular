import 'package:app_restaurante/core/config/app_theme.dart';
import 'package:flutter/material.dart';

// Badge unificado para etiquetas informativas (ADMIN, ABIERTO, CATEGORÍA, etc).
class AppBadge extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final double borderRadius;
  final bool isOutline;

  const AppBadge({
    super.key,
    required this.label,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.borderRadius = 8.0,
    this.isOutline = false,
  });

  // Variante para indicar éxito o estado positivo (ej: ABIERTO).
  factory AppBadge.success({required String label, IconData? icon}) => AppBadge(
    label: label,
    icon: icon,
    backgroundColor: AppTheme.brandSuccess.withAlpha(25),
    textColor: AppTheme.brandSuccess,
    borderRadius: 12,
  );

  // Variante para errores o estados negativos (ej: CERRADO, NO DISPONIBLE).
  factory AppBadge.error({required String label, IconData? icon}) => AppBadge(
    label: label,
    icon: icon,
    backgroundColor: AppTheme.brandError.withAlpha(25),
    textColor: AppTheme.brandError,
    borderRadius: 12,
  );

  // Variante para avisos o estados pendientes (ej: PENDIENTE).
  factory AppBadge.warning({required String label, IconData? icon}) => AppBadge(
    label: label,
    icon: icon,
    backgroundColor: AppTheme.brandWarning.withAlpha(25),
    textColor: AppTheme.brandWarning,
    borderRadius: 12,
  );

  // Variante para detalles secundarios (ej: categoría, etiqueta informativa).
  factory AppBadge.detail({required String label, IconData? icon}) => AppBadge(
    label: label,
    icon: icon,
    backgroundColor: AppTheme.brandDetail.withAlpha(30),
    textColor: AppTheme.brandDetail,
    borderRadius: 12,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final bg = backgroundColor ?? colorScheme.primaryContainer;
    final textCol = textColor ?? colorScheme.onPrimaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isOutline ? Colors.transparent : bg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: isOutline ? Border.all(color: textCol.withAlpha(100)) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textCol),
            const SizedBox(width: 4),
          ],
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: textCol,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
