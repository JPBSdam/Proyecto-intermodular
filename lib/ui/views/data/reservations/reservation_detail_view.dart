import 'package:app_restaurante/core/navigation/app_routes.dart';
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LoadingOverlay(
      isLoading: _loading || vm.isLoading,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: colorScheme.surface,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'DETALLE RESERVA',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        body: _buildBody(theme, colorScheme, vm, isAdmin),
      ),
    );
  }

  Widget _buildBody(
    ThemeData theme,
    ColorScheme colorScheme,
    ReservationViewModel vm,
    bool isAdmin,
  ) {
    if (_error.isNotEmpty) return Center(child: Text(_error));
    if (_reservation == null)
      return const Center(child: CircularProgressIndicator());

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
                  'Cliente',
                  r.userName ?? r.userEmail ?? 'Anónimo',
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

          // Botones de Acción
          _buildActions(r, vm, isAdmin),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String? status) {
    switch (status) {
      case ReservationStatus.confirmed:
        return AppBadge.success(label: 'CONFIRMADA', icon: Icons.check_circle);
      case ReservationStatus.cancelled:
        return AppBadge.error(label: 'CANCELADA', icon: Icons.cancel);
      default:
        return const AppBadge(
          label: 'PENDIENTE DE CONFIRMACIÓN',
          icon: Icons.timer_outlined,
          backgroundColor: Colors.orange,
          textColor: Colors.white,
          borderRadius: 12,
        );
    }
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
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
                  color: Colors.grey.shade600,
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
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Si es Admin y está pendiente, botón Confirmar
        if (isAdmin && r.state == ReservationStatus.pending) ...[
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('CONFIRMAR RESERVA'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () async {
                await vm.confirmReservation(r.id!);
                if (mounted) {
                  showSnackBar(context, 'Reserva confirmada', success: true);
                  _load(); // Recargar datos locales
                }
              },
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Editar (disponible para dueño o admin si no está cancelada)
        if (r.state != ReservationStatus.cancelled) ...[
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cancelar reserva?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('VOLVER'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'SÍ, CANCELAR',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await vm.deleteReservation(r.id!);
      if (mounted) {
        showSnackBar(context, 'Reserva eliminada');
        context.pop();
      }
    }
  }
}
