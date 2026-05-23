// Vista de Avisos para administradores en SabrosApp.
//
// Muestra todas las reservas PENDIENTES ordenadas de más reciente a más antigua.
// Al entrar, llama a markAllAsSeen() para resetear el badge de la campana.
// El admin puede confirmar o cancelar cada reserva directamente desde aquí
// sin necesidad de entrar al detalle de la reserva.

import 'package:app_restaurante/core/navigation/app_routes.dart';
import 'package:app_restaurante/core/widgets/app_badge.dart';
import 'package:app_restaurante/core/widgets/confirmation_dialog.dart';
import 'package:app_restaurante/core/widgets/app_bottom_nav.dart';
import 'package:app_restaurante/core/widgets/app_card.dart';
import 'package:app_restaurante/core/widgets/loading_overlay.dart';
import 'package:app_restaurante/core/widgets/sabros_app_bar.dart';
import 'package:app_restaurante/core/widgets/snackbars.dart';
import 'package:app_restaurante/data/model/reservation.dart';
import 'package:app_restaurante/ui/viewmodels/firestore/reservation_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AdminNotificationsView extends StatefulWidget {
  const AdminNotificationsView({super.key});

  @override
  State<AdminNotificationsView> createState() => _AdminNotificationsViewState();
}

class _AdminNotificationsViewState extends State<AdminNotificationsView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final resVM = context.watch<ReservationViewModel>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final pendingReservations = resVM.pendingReservations;

    return LoadingOverlay(
      isLoading: resVM.isLoading,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: SabrosAppBar(pageTitle: 'AVISOS', centerTitle: true),
        bottomNavigationBar: const AppBottomNav(),
        body: pendingReservations.isEmpty
            ? _buildEmptyState(colorScheme)
            : _buildList(pendingReservations, resVM),
      ),
    );
  }

  // ─── Estado vacío (ninguna reserva pendiente) ─────────────────────────────

  Widget _buildEmptyState(ColorScheme colorScheme) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ReservationViewModel>().markAllAsSeen();
      }
    });

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withAlpha(80),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none_outlined,
              size: 56,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '¡Todo al día!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No hay reservas pendientes de confirmar',
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ─── Lista de reservas pendientes ─────────────────────────────────────────

  Widget _buildList(List<Reservation> list, ReservationViewModel resVM) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabecera con el contador de pendientes
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Icon(
                Icons.pending_actions_outlined,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '${list.length} reserva${list.length == 1 ? '' : 's'} pendiente${list.length == 1 ? '' : 's'}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            physics: const BouncingScrollPhysics(),
            itemCount: list.length,
            itemBuilder: (context, i) => _NotificationCard(
              reservation: list[i],
              onConfirm: () => _confirm(list[i], resVM),
              onCancel: () => _cancel(list[i], resVM),
              onTap: () =>
                  context.push(AppRoutes.reservationDetail(list[i].id!)),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Acciones rápidas ─────────────────────────────────────────────────────

  Future<void> _confirm(
    Reservation reservation,
    ReservationViewModel vm,
  ) async {
    final ok = await showDialogYesNo(
      context,
      title: 'Confirmar reserva',
      cuestion:
          '¿Confirmas la reserva de ${reservation.userName ?? 'este cliente'}?',
    );

    if (ok == true && mounted) {
      await vm.confirmReservation(reservation.id!);
      if (mounted) {
        showSnackBar(context, '✅ Reserva confirmada', success: true);
      }
    }
  }

  Future<void> _cancel(Reservation reservation, ReservationViewModel vm) async {
    final ok = await showDialogYesNo(
      context,
      title: 'Cancelar reserva',
      cuestion:
          '¿Quieres cancelar la reserva de ${reservation.userName ?? 'este cliente'}?',
    );

    if (ok == true && mounted) {
      await vm.cancelReservation(reservation.id!);
      if (mounted) {
        showSnackBar(context, 'Reserva cancelada', success: false);
      }
    }
  }
}

// ─── Tarjeta de notificación individual ──────────────────────────────────────

class _NotificationCard extends StatelessWidget {
  final Reservation reservation;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.reservation,
    required this.onConfirm,
    required this.onCancel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final date = reservation.reservationDate;

    final dayFormat = DateFormat('dd MMM', 'es');
    final hourFormat = DateFormat('HH:mm');
    final timeAgo = _timeAgo(reservation.createdAt);

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withAlpha(80),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_outline,
                  color: colorScheme.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reservation.userName ??
                          reservation.userEmail ??
                          'Cliente',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (timeAgo != null)
                      Text(
                        timeAgo,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              AppBadge.warning(label: 'PENDIENTE'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _InfoChip(
                icon: Icons.calendar_today_outlined,
                label: date != null
                    ? '${dayFormat.format(date).toUpperCase()} · ${hourFormat.format(date)}'
                    : 'Sin fecha',
                colorScheme: colorScheme,
              ),
              const SizedBox(width: 8),
              // Número de personas
              _InfoChip(
                icon: Icons.people_outline,
                label: '${reservation.seats ?? '?'} pers.',
                colorScheme: colorScheme,
              ),
            ],
          ),

          if (reservation.comments != null &&
              reservation.comments!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withAlpha(80),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      reservation.comments!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // ── Botones de acción rápida ──
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onConfirm,
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('CONFIRMAR'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCancel,
                  icon: Icon(Icons.close, size: 16, color: colorScheme.error),
                  label: Text(
                    'CANCELAR',
                    style: TextStyle(color: colorScheme.error),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: BorderSide(color: colorScheme.error.withAlpha(120)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Helper: texto relativo de tiempo ─────────────────────────────────────

  // Devuelve cuánto tiempo hace que se creó la reserva (ej: "hace 3 horas")
  String? _timeAgo(DateTime? createdAt) {
    if (createdAt == null) return null;
    final diff = DateTime.now().difference(createdAt);

    if (diff.inMinutes < 1) return 'Ahora mismo';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    if (diff.inDays == 1) return 'Ayer';
    return 'Hace ${diff.inDays} días';
  }
}

// ─── Widget pequeño de info dentro de la tarjeta ─────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme colorScheme;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colorScheme.primary.withAlpha(15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: colorScheme.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
