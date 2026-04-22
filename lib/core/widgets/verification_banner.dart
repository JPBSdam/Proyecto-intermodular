import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../ui/viewmodels/home/home_viewmodel.dart';

/// Banner que se muestra en la parte superior de la Home si el usuario no ha verificado su email.
/// Se actualiza automáticamente cuando el usuario vuelve a la app (onResume) o manualmente con el icono de refresco.
class VerificationBanner extends StatelessWidget {
  const VerificationBanner({super.key});

  @override
  Widget build(BuildContext context) {
    // Escuchamos el HomeViewModel para reaccionar a cambios en emailVerified
    final viewModel = context.watch<HomeViewModel>();

    // No mostrar nada si:
    // - Es un invitado (sin login o anónimo)
    // - El email ya está verificado
    if (viewModel.isGuest || viewModel.isEmailVerified) {
      return const SizedBox.shrink();
    }

    return Material(
      elevation: 2,
      child: Container(
        width: double.infinity,
        color: Colors.amber.shade50,
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.mark_email_unread_outlined,
                  color: Colors.amber,
                  size: 20,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Verifica tu cuenta para activar todas las funciones.',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                // Botón para forzar el refresco manualmente si el auto-refresco falla o si se verifica desde otro dispositivo
                IconButton(
                  icon: const Icon(
                    Icons.refresh,
                    size: 20,
                    color: Colors.amber,
                  ),
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
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Correo de verificación reenviado'),
                        ),
                      );
                    }
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
