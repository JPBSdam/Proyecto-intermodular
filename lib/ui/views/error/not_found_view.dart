import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:app_restaurante/core/navigation/app_routes.dart';
import 'package:app_restaurante/core/widgets/sabros_app_bar.dart';

/// Pantalla personalizada para errores 404 (Ruta no encontrada).
class NotFoundView extends StatelessWidget {
  final String? exception;

  const NotFoundView({super.key, this.exception});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const SabrosAppBar(
        pageTitle: 'PÁGINA NO ENCONTRADA',
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.restaurant_menu_rounded,
                size: 80,
                color: colorScheme.primary.withAlpha(50),
              ),
              const SizedBox(height: 16),
              Text(
                '404',
                style: theme.textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '¡Vaya!',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'La página que buscas no existe o ha sido movida.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 48),
              
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: () => context.go(AppRoutes.home),
                  icon: const Icon(Icons.home_rounded),
                  label: const Text(
                    'VOLVER AL INICIO',
                    style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                ),
              ),
              
              // Debug info (solo visible en desarrollo)
              if (exception != null) ...[
                const SizedBox(height: 32),
                Text(
                  'Error técnico:',
                  style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.outline),
                ),
                Text(
                  exception!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.outline,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
