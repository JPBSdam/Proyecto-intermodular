import 'package:app_restaurante/core/navigation/app_routes.dart';
import 'package:app_restaurante/core/widgets/home_button.dart';
import 'package:app_restaurante/core/widgets/loading_overlay.dart';
import 'package:app_restaurante/core/widgets/snackbars.dart';
import 'package:app_restaurante/data/model/reservation.dart';
import 'package:app_restaurante/data/services/firestore/reservation_service.dart';
import 'package:app_restaurante/ui/viewmodels/firestore/reservation_viewmodel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Detalle de una reserva.
/// Carga la reserva directamente de Firestore por ID al iniciar,
/// evitando depender de la lista del ViewModel (que puede estar vacía).
///
/// NOTA ROLES: botón "Confirmar" visible para todos hasta que roles estén implantados.

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
      if (mounted)
        setState(() {
          _reservation = r;
          _loading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _error = '$e';
          _loading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReservationViewModel>();

    return LoadingOverlay(
      isLoading: _loading || vm.isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Detalle de reserva'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Volver a mis reservas',
            onPressed: () => context.go(AppRoutes.reservations),
          ),
          actions: const [HomeButton()],
        ),
        body: _error.isNotEmpty
            ? Center(child: Text(_error))
            : _reservation == null
            ? const Center(child: CircularProgressIndicator())
            : _buildDetail(context, vm, _reservation!),
      ),
    );
  }

  Widget _buildDetail(
    BuildContext context,
    ReservationViewModel vm,
    Reservation r,
  ) {
    final date = r.reservationDate;
    final dateStr = date != null
        ? '${date.day.toString().padLeft(2, '0')}/'
              '${date.month.toString().padLeft(2, '0')}/'
              '${date.year}  '
              '${date.hour.toString().padLeft(2, '0')}:'
              '${date.minute.toString().padLeft(2, '0')}'
        : 'Sin fecha';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Row('Fecha y hora', dateStr),
          _Row('Personas', '${r.seats ?? '-'}'),
          if (r.userName != null) _Row('Nombre', r.userName!),
          if (r.userEmail != null) _Row('Email', r.userEmail!),
          _Row('Bebé / carricoche', (r.hasBaby ?? false) ? 'Sí 🍼' : 'No'),
          if (r.comments != null && r.comments!.isNotEmpty)
            _Row('Comentarios', r.comments!),
          _Row('Estado', _stateLabel(r.state)),
          const SizedBox(height: 24),

          // ── Editar (solo si está pendiente) ────────────────────────
          if (r.state == ReservationStatus.pending) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.edit),
                label: const Text('Editar reserva'),
                onPressed: () =>
                    context.go(AppRoutes.reservationFormEdit(r.id!)),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // ── Confirmar (solo admin) — oculto para el propio usuario ──
          if (r.state == ReservationStatus.pending &&
              FirebaseAuth.instance.currentUser?.uid != r.userId) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Confirmar reserva'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () async {
                  await vm.confirmReservation(r.id!);
                  if (context.mounted) context.go(AppRoutes.reservations);
                },
              ),
            ),
            const SizedBox(height: 8),
          ],

          // ── Cancelar (si no está ya cancelada) ─────────────────────
          if (r.state != ReservationStatus.cancelled) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                label: const Text(
                  'Cancelar reserva',
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: () async {
                  await vm.cancelReservation(r.id!);
                  if (context.mounted) {
                    showSnackBar(context, 'Reserva cancelada');
                    context.go(AppRoutes.reservations);
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
          ],

          // ── Eliminar (siempre disponible) ──────────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              label: const Text(
                'Eliminar reserva',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () => _confirmDelete(context, vm, r.id!),
            ),
          ),

          if (vm.errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                vm.errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    ReservationViewModel vm,
    String id,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar reserva'),
        content: const Text(
          '¿Seguro que quieres eliminar esta reserva? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await vm.deleteReservation(id);
              if (context.mounted) {
                showSnackBar(context, 'Reserva eliminada');
                context.go(AppRoutes.reservations);
              }
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  String _stateLabel(String? s) {
    if (s == ReservationStatus.confirmed) return 'Confirmada ✅';
    if (s == ReservationStatus.cancelled) return 'Cancelada ❌';
    return 'Pendiente ⏳';
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
