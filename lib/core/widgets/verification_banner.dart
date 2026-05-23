import 'package:app_restaurante/core/config/app_theme.dart';
import 'package:app_restaurante/core/widgets/snackbars.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../ui/viewmodels/home/home_viewmodel.dart';

// Banner que se muestra en la parte superior de la Home si el usuario no ha verificado su email.
// Se actualiza automáticamente cuando el usuario vuelve a la app (onResume) o manualmente con el icono de refresco.
class VerificationBanner extends StatelessWidget {
  const VerificationBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();

    if (viewModel.isGuest || viewModel.isEmailVerified) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final warningColor = AppTheme.brandWarning;

    return Material(
      elevation: 2,
      child: Container(
        width: double.infinity,
        color: warningColor.withAlpha(20),
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.mark_email_unread_outlined,
                  color: warningColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Verifica tu cuenta para activar todas las funciones.',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.refresh, size: 20, color: warningColor),
                  tooltip: 'Comprobar ahora',
                  onPressed: () => viewModel.checkEmailVerification(),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () async {
                    await viewModel.resendVerificationEmail();

                    if (!context.mounted) return;

                    showSnackBar(
                      context,
                      'Correo de verificación reenviado',
                      success: true,
                    );
                  },
                  child: const Text(
                    'Reenviar correo.',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
