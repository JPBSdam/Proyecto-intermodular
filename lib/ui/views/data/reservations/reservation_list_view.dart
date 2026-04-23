import 'package:app_restaurante/core/navigation/app_routes.dart';
import 'package:app_restaurante/core/widgets/app_badge.dart';
import 'package:app_restaurante/core/widgets/app_bottom_nav.dart';
import 'package:app_restaurante/core/widgets/app_card.dart';
import 'package:app_restaurante/core/widgets/loading_overlay.dart';
import 'package:app_restaurante/core/widgets/sabros_app_bar.dart';
import 'package:app_restaurante/data/model/reservation.dart';
import 'package:app_restaurante/ui/viewmodels/firestore/reservation_viewmodel.dart';
import 'package:app_restaurante/ui/viewmodels/home/home_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ReservationListView extends StatefulWidget {
  final String? userId;
  const ReservationListView({super.key, this.userId});

  @override
  State<ReservationListView> createState() => _ReservationListViewState();
}

class _ReservationListViewState extends State<ReservationListView> {
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<ReservationViewModel>();
      final homeVM = context.read<HomeViewModel>();

      if (homeVM.userRole == 'ADMIN') {
        vm.watchAll();
      } else if (widget.userId != null) {
        vm.watchByUser(widget.userId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReservationViewModel>();
    final homeVM = context.watch<HomeViewModel>();
    final isAdmin = homeVM.userRole == 'ADMIN';
    final theme = Theme.of(context);

    // Filtrar lista localmente
    final filteredList = vm.reservations.where((r) {
      if (_filterStatus == 'all') return true;
      return r.state == _filterStatus;
    }).toList();

    return LoadingOverlay(
      isLoading: vm.isLoading,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: SabrosAppBar(
          pageTitle: isAdmin ? 'GESTIÓN RESERVAS' : 'MIS RESERVAS',
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.home);
              }
            },
          ),
        ),
        body: Column(
          children: [
            _buildFilters(),
            Expanded(child: _buildBody(filteredList, vm.errorMessage, isAdmin)),
          ],
        ),
        floatingActionButton: !isAdmin
            ? FloatingActionButton.extended(
                onPressed: () =>
                    context.push(AppRoutes.reservationFormCreate()),
                icon: const Icon(Icons.add),
                label: const Text('RESERVAR'),
              )
            : null,
        bottomNavigationBar: AppBottomNav(currentIndex: isAdmin ? 2 : 2),
      ),
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          _filterChip('TODAS', 'all'),
          _filterChip('PENDIENTES', ReservationStatus.pending),
          _filterChip('CONFIRMADAS', ReservationStatus.confirmed),
          _filterChip('CANCELADAS', ReservationStatus.cancelled),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String status) {
    final isSelected = _filterStatus == status;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
          ),
        ),
        selected: isSelected,
        onSelected: (val) => setState(() => _filterStatus = status),
        backgroundColor: colorScheme.surface,
        selectedColor: colorScheme.primary,
        checkmarkColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outlineVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildBody(List<Reservation> list, String error, bool isAdmin) {
    if (error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(error),
          ],
        ),
      );
    }

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: Colors.grey.withAlpha(50),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay reservas que mostrar',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      itemCount: list.length,
      itemBuilder: (context, i) => _ReservationCard(
        reservation: list[i],
        isAdmin: isAdmin,
        onTap: () => context.push(AppRoutes.reservationDetail(list[i].id!)),
      ),
    );
  }
}

class _ReservationCard extends StatelessWidget {
  final Reservation reservation;
  final bool isAdmin;
  final VoidCallback onTap;

  const _ReservationCard({
    required this.reservation,
    required this.isAdmin,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final date = reservation.reservationDate;

    final dayFormat = DateFormat('dd MMM', 'es');
    final hourFormat = DateFormat('HH:mm');

    return AppCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Row(
        children: [
          // Lado Izquierdo: Fecha
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withAlpha(100),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  date != null ? dayFormat.format(date).toUpperCase() : '??',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  date != null ? hourFormat.format(date) : '--:--',
                  style: TextStyle(
                    color: colorScheme.primary.withAlpha(180),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Centro: Información
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAdmin
                      ? (reservation.userName ?? 'Cliente Desconocido')
                      : 'Mesa para ${reservation.seats} personas',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isAdmin
                          ? '${reservation.seats} comensales'
                          : 'ID: ${reservation.id?.substring(0, 8).toUpperCase()}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Lado Derecho: Estado
          _buildStatusBadge(reservation.state),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String? status) {
    switch (status) {
      case ReservationStatus.confirmed:
        return AppBadge.success(label: 'CONFIRMADA');
      case ReservationStatus.cancelled:
        return AppBadge.error(label: 'CANCELADA');
      default:
        return const AppBadge(
          label: 'PENDIENTE',
          backgroundColor: Colors.orange,
          textColor: Colors.white,
        );
    }
  }
}
