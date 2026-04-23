import 'package:app_restaurante/core/navigation/app_routes.dart';
import 'package:app_restaurante/core/widgets/home_button.dart';
import 'package:app_restaurante/core/widgets/loading_overlay.dart';
import 'package:app_restaurante/data/model/reservation.dart';
import 'package:app_restaurante/ui/viewmodels/firestore/reservation_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Lista de reservas.
/// - userId != null → customer (ve solo las suyas)
/// - userId == null → admin (ve todas)
///
/// NOTA ROLES: el app_router pasará userId según el rol cuando esté implantado.

class ReservationListView extends StatelessWidget {
  final String? userId;
  const ReservationListView({super.key, this.userId});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReservationViewModel>();

    if (!vm.isWatching) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (userId != null) {
          vm.watchByUser(userId!);
        } else {
          vm.watchAll();
        }
      });
    }

    return LoadingOverlay(
      isLoading: vm.isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: Text(userId != null ? 'Mis reservas' : 'Todas las reservas'),
          actions: const [HomeButton()],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.go(AppRoutes.reservationFormCreate()),
          tooltip: 'Nueva reserva',
          child: const Icon(Icons.add),
        ),
        body: _buildBody(vm, context),
      ),
    );
  }

  Widget _buildBody(ReservationViewModel vm, BuildContext context) {
    if (vm.errorMessage.isNotEmpty) {
      return Center(child: Text(vm.errorMessage));
    }
    if (vm.reservations.isEmpty) {
      return const Center(child: Text('No hay reservas'));
    }
    return ListView.builder(
      itemCount: vm.reservations.length,
      itemBuilder: (context, i) {
        final r = vm.reservations[i];
        return _ReservationTile(
          reservation: r,
          isAdmin: userId == null,
          onTap: () => context.go(AppRoutes.reservationDetail(r.id!)),
        );
      },
    );
  }
}

class _ReservationTile extends StatelessWidget {
  final Reservation reservation;
  final bool isAdmin;
  final VoidCallback onTap;
  const _ReservationTile({
    required this.reservation,
    required this.isAdmin,
    required this.onTap,
  });

  Color _color(String? s) {
    if (s == ReservationStatus.confirmed) return Colors.green;
    if (s == ReservationStatus.cancelled) return Colors.red;
    return Colors.orange;
  }

  String _label(String? s) {
    if (s == ReservationStatus.confirmed) return 'Confirmada';
    if (s == ReservationStatus.cancelled) return 'Cancelada';
    return 'Pendiente';
  }

  @override
  Widget build(BuildContext context) {
    final date = reservation.reservationDate;
    final dateStr = date != null
        ? '${date.day.toString().padLeft(2, '0')}/'
              '${date.month.toString().padLeft(2, '0')}/'
              '${date.year}  '
              '${date.hour.toString().padLeft(2, '0')}:'
              '${date.minute.toString().padLeft(2, '0')}'
        : 'Sin fecha';

    return ListTile(
      onTap: onTap,
      title: Text(
        isAdmin
            ? (reservation.userName ?? reservation.userEmail ?? 'Usuario')
            : dateStr,
      ),
      subtitle: Text(
        isAdmin ? dateStr : '${reservation.seats ?? '-'} personas',
      ),
      trailing: Chip(
        label: Text(
          _label(reservation.state),
          style: const TextStyle(color: Colors.white, fontSize: 11),
        ),
        backgroundColor: _color(reservation.state),
        padding: EdgeInsets.zero,
      ),
    );
  }
}
