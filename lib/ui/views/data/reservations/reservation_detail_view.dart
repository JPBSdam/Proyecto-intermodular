import 'package:app_restaurante/core/widgets/app_bottom_nav.dart';
import 'package:app_restaurante/core/widgets/confirmation_dialog.dart';
import 'package:app_restaurante/core/widgets/sabros_app_bar.dart';
import 'package:app_restaurante/core/widgets/app_badge.dart';
import 'package:app_restaurante/core/widgets/app_card.dart';
import 'package:app_restaurante/core/widgets/loading_overlay.dart';
import 'package:app_restaurante/core/widgets/snackbars.dart';
import 'package:app_restaurante/data/model/reservation.dart';
import 'package:app_restaurante/data/services/firestore/reservation_service.dart';
import 'package:app_restaurante/ui/viewmodels/firestore/reservation_viewmodel.dart';
import 'package:app_restaurante/ui/viewmodels/home/home_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/navigation/app_routes.dart';

class ReservationDetailView extends StatefulWidget {
  final String reservationId;
  const ReservationDetailView({super.key, required this.reservationId});

  @override
  State<ReservationDetailView> createState() => _ReservationDetailViewState();
}

class _ReservationDetailViewState extends State<ReservationDetailView> {
  Reservation? _reservation;
  bool _loading = true;
  String _error = '';

  // Getters para acceso centralizado a estilos
  ThemeData get theme => Theme.of(context);
  ColorScheme get colorScheme => theme.colorScheme;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await ReservationService().getById(widget.reservationId);
      if (mounted) {
        setState(() {
          _reservation = r;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReservationViewModel>();
    final homeVM = context.watch<HomeViewModel>();
    final isAdmin = homeVM.userRole == 'ADMIN';

    return LoadingOverlay(
      isLoading: _loading || vm.isLoading,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: SabrosAppBar(
          pageTitle: 'DETALLE RESERVA',
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => context.pop(),
          ),
        ),
        body: _buildBody(vm, isAdmin),
        bottomNavigationBar: const AppBottomNav(),
      ),
    );
  }

  Widget _buildBody(ReservationViewModel vm, bool isAdmin) {
    if (_error.isNotEmpty) return Center(child: Text(_error));

    final r = _reservation!;
    final date = r.reservationDate;
    final dayFormat = DateFormat('EEEE, d MMMM yyyy', 'es');
    final hourFormat = DateFormat('HH:mm');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con Estado
          Center(
            child: Column(
              children: [
                _buildStatusBadge(r.state),
                const SizedBox(height: 16),
                Text(
                  date != null
                      ? dayFormat.format(date).toUpperCase()
                      : 'SIN FECHA',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                Text(
                  date != null ? '${hourFormat.format(date)} Horas' : '--:--',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Card de Información del Cliente/Mesa
          AppCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow(
                  Icons.person_outline,
                  'Nombre Cliente',
                  r.userName ?? 'No especificado',
                ),
                const Divider(height: 32),
                _infoRow(
                  Icons.email_outlined,
                  'Email Contacto',
                  r.userEmail ?? 'No especificado',
                ),
                const Divider(height: 32),
                _infoRow(
                  Icons.phone_outlined,
                  'Teléfono',
                  r.userPhone ?? 'No especificado',
                ),
                const Divider(height: 32),
                _infoRow(
                  Icons.people_outline,
                  'Comensales',
                  '${r.seats} personas',
                ),
                if (r.hasBaby ?? false) ...[
                  const Divider(height: 32),
                  _infoRow(
                    Icons.child_care_outlined,
                    'Bebés/Carritos',
                    '${r.babyCount ?? 1}',
                  ),
                ],
                if (r.comments != null && r.comments!.isNotEmpty) ...[
                  const Divider(height: 32),
                  _infoRow(
                    Icons.chat_bubble_outline,
                    'Observaciones',
                    r.comments!,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildActions(r, vm, isAdmin),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String? status) {
    switch (status) {
      case ReservationStatus.confirmed:
        return AppBadge.success(label: 'CONFIRMADA', icon: Icons.check_circle);
      case ReservationStatus.completed:
        return const AppBadge(
          label: 'RESERVA COMPLETADA',
          icon: Icons.done_all,
          backgroundColor: Colors.blueGrey,
          textColor: Colors.white,
          borderRadius: 12,
        );
      case ReservationStatus.cancelled:
        return AppBadge.error(label: 'CANCELADA', icon: Icons.cancel);
      default:
        return AppBadge.warning(
          label: 'PENDIENTE DE CONFIRMACIÓN',
          icon: Icons.timer_outlined,
        );
    }
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurfaceVariant.withAlpha(180),
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActions(Reservation r, ReservationViewModel vm, bool isAdmin) {
    return Column(
      children: [
        if (isAdmin && r.state == ReservationStatus.pending) ...[
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('CONFIRMAR RESERVA'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.tertiary,
                foregroundColor: colorScheme.onTertiary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () async {
                await vm.confirmReservation(r.id!);
                if (mounted) {
                  showSnackBar(context, 'Reserva confirmada', success: true);
                  _load();
                }
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (isAdmin && r.state == ReservationStatus.confirmed) ...[
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.done_all),
              label: const Text('MARCAR COMO COMPLETADA'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () async {
                await vm.completeReservation(r.id!);
                if (mounted) {
                  showSnackBar(
                    context,
                    'Reserva marcada como completada',
                    success: true,
                  );
                  _load();
                }
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (r.state != ReservationStatus.cancelled &&
            r.state != ReservationStatus.completed) ...[
          SizedBox(
            width: double.infinity,
            height: 55,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.edit_outlined),
              label: const Text('MODIFICAR DATOS'),
              onPressed: () =>
                  context.push(AppRoutes.reservationFormEdit(r.id!)),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        // Cancelar / Eliminar
        SizedBox(
          width: double.infinity,
          height: 55,
          child: TextButton.icon(
            icon: Icon(Icons.delete_outline, color: colorScheme.error),
            label: Text(
              'CANCELAR RESERVA',
              style: TextStyle(color: colorScheme.error),
            ),
            onPressed: () => _confirmDelete(r, vm),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(Reservation r, ReservationViewModel vm) async {
    final confirm = await showDialogYesNo(
      context,
      title: '¿Cancelar reserva?',
      cuestion: 'Esta acción no se puede deshacer.',
    );

    if (confirm == true && mounted) {
      await vm.cancelReservation(r.id!);
      if (mounted) {
        showSnackBar(context, 'Reserva cancelada');
        _load();
      }
    }
  }
}
