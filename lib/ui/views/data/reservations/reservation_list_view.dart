import 'package:app_restaurante/core/navigation/app_routes.dart';
import 'package:app_restaurante/core/widgets/app_badge.dart';
import 'package:app_restaurante/core/widgets/app_bottom_nav.dart';
import 'package:app_restaurante/core/widgets/app_card.dart';
import 'package:app_restaurante/core/widgets/app_drawer.dart';
import 'package:app_restaurante/core/widgets/loading_overlay.dart';
import 'package:app_restaurante/core/widgets/sabros_app_bar.dart';
import 'package:app_restaurante/core/widgets/snackbars.dart';
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
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  String? _lastRole;

  bool _didAutoNavigateToForm = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _handleSubscription();
  }

  /// Inicializa o actualiza el stream de datos solo si el rol ha cambiado.
  void _handleSubscription() {
    final homeVM = context.watch<HomeViewModel>();
    final currentRole = homeVM.userRole;

    if (_lastRole != currentRole) {
      _lastRole = currentRole;

      final resVM = context.read<ReservationViewModel>();
      final uid = widget.userId ?? homeVM.currentUser?.uid;

      // Usamos postFrameCallback para que la carga no interfiera con el pintado actual
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (currentRole == 'ADMIN') {
          resVM.watchAll();
        } else if (uid != null) {
          resVM.watchByUser(uid);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final resVM = context.watch<ReservationViewModel>();
    final homeVM = context.read<HomeViewModel>();
    final isAdmin = homeVM.userRole == 'ADMIN';
    final theme = Theme.of(context);

    // Filtrado local según el chip seleccionado
    final filteredList = resVM.reservations.where((r) {
      if (_filterStatus == 'all') return true;
      return r.state == _filterStatus;
    }).toList();

    if (!isAdmin &&
        resVM.isWatching &&
        !resVM.isLoading &&
        resVM.reservations.isEmpty &&
        _filterStatus == 'all' &&
        !_didAutoNavigateToForm) {
      // Marcamos que ya redirigimos antes de programar la navegación,
      // para que no se dispare varias veces en rebuilds del mismo frame
      _didAutoNavigateToForm = true;
      // Se ejecuta después del frame actual para no interrumpir el build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Navegamos al formulario de nueva reserva.
          // Usamos push (no go) para que el usuario pueda volver atrás con
          // el botón "back" y quedarse en la lista (ya con _didAutoNavigate = true)
          context.push(AppRoutes.reservationFormCreate());
        }
      });
    }

    return LoadingOverlay(
      isLoading: resVM.isLoading,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: SabrosAppBar(
          pageTitle: _isSelectionMode
              ? '${_selectedIds.length} SELECCIONADAS'
              : (isAdmin ? 'GESTIÓN RESERVAS' : 'MIS RESERVAS'),
          centerTitle: true,
          leading: _isSelectionMode
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() {
                    _isSelectionMode = false;
                    _selectedIds.clear();
                  }),
                )
              : null,
        ),
        drawer: AppDrawer(),
        body: Column(
          children: [
            if (!_isSelectionMode) _buildFilters(),

            if (isAdmin && !_isSelectionMode) _buildQuickActionTrigger(),

            if (_isSelectionMode) _buildSelectionHeader(resVM),

            Expanded(
              child: _buildBody(filteredList, resVM.errorMessage, isAdmin),
            ),
          ],
        ),
        bottomNavigationBar: AppBottomNav(),
        floatingActionButton: !isAdmin
            ? FloatingActionButton.extended(
                onPressed: () =>
                    context.push(AppRoutes.reservationFormCreate()),
                icon: const Icon(Icons.add),
                label: const Text('RESERVAR'),
              )
            : null,
      ),
    );
  }

  Widget _buildQuickActionTrigger() {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: InkWell(
        onTap: () => setState(() => _isSelectionMode = true),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: colorScheme.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.primary.withAlpha(50)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.fact_check_outlined,
                color: colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'MARCAR RESERVAS COMO COMPLETADAS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: colorScheme.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionHeader(ReservationViewModel vm) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasSelection = _selectedIds.isNotEmpty;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, size: 18, color: Colors.blueGrey),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Selecciona las reservas a completar:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
              TextButton(
                onPressed: () => setState(() {
                  _isSelectionMode = false;
                  _selectedIds.clear();
                }),
                child: const Text('CANCELAR', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: hasSelection ? () => _confirmBulkComplete(vm) : null,
              icon: const Icon(Icons.done_all, size: 18),
              label: Text('COMPLETAR ${_selectedIds.length} RESERVAS'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmBulkComplete(ReservationViewModel vm) async {
    final count = _selectedIds.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Completar reservas?'),
        content: Text(
          'Vas a marcar como COMPLETADAS $count reservas. ¿Deseas continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('SÍ, COMPLETAR'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await vm.completeMultipleReservations(_selectedIds.toList());
      if (mounted) {
        showSnackBar(context, '$count reservas completadas', success: true);
        setState(() {
          _isSelectionMode = false;
          _selectedIds.clear();
        });
      }
    }
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          _filterChip('TODAS', 'all'),
          _filterChip('PENDIENTES', ReservationStatus.pending),
          _filterChip('CONFIRMADAS', ReservationStatus.confirmed),
          _filterChip('COMPLETADAS', ReservationStatus.completed),
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
        label: Text(label, style: const TextStyle(fontSize: 11)),
        selected: isSelected,
        onSelected: (val) => setState(() => _filterStatus = status),
        backgroundColor: colorScheme.surface,
        selectedColor: colorScheme.primaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildBody(List<Reservation> list, String error, bool isAdmin) {
    if (error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text(error, textAlign: TextAlign.center),
        ),
      );
    }

    if (list.isEmpty) {
      // Estado vacío diferente según si es admin o cliente
      if (isAdmin) {
        // El admin ve un mensaje neutro
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
              const Text(
                'No hay reservas que mostrar',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        );
      }

      // El cliente ve una pantalla que invita a reservar
      // (llega aquí si volvió atrás del formulario sin reservar)
      final colorScheme = Theme.of(context).colorScheme;
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icono decorativo grande
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withAlpha(80),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.restaurant_outlined,
                  size: 56,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              // Título
              Text(
                '¡Aún no tienes reservas!',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              // Subtítulo
              Text(
                'Reserva tu mesa ahora y disfruta de una experiencia única.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Botón de acción
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      context.push(AppRoutes.reservationFormCreate()),
                  icon: const Icon(Icons.add),
                  label: const Text('RESERVAR AHORA'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      physics: const BouncingScrollPhysics(),
      itemCount: list.length,
      itemBuilder: (context, i) {
        final reservation = list[i];
        final isSelectable = reservation.state == ReservationStatus.confirmed;
        final isSelected = _selectedIds.contains(reservation.id);

        return _ReservationCard(
          reservation: reservation,
          isAdmin: isAdmin,
          isSelectionMode: _isSelectionMode,
          isSelected: isSelected,
          isSelectable: isSelectable,
          onTap: _isSelectionMode
              ? (isSelectable
                    ? () => setState(() {
                        if (isSelected) {
                          _selectedIds.remove(reservation.id);
                        } else {
                          _selectedIds.add(reservation.id!);
                        }
                      })
                    : null)
              : () =>
                    context.push(AppRoutes.reservationDetail(reservation.id!)),
        );
      },
    );
  }
}

class _ReservationCard extends StatelessWidget {
  final Reservation reservation;
  final bool isAdmin;
  final bool isSelectionMode;
  final bool isSelected;
  final bool isSelectable;
  final VoidCallback? onTap;

  const _ReservationCard({
    required this.reservation,
    required this.isAdmin,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.isSelectable = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final date = reservation.reservationDate;

    final dayFormat = DateFormat('dd MMM', 'es');
    final hourFormat = DateFormat('HH:mm');

    // Prioridad de visualización de nombre: Firestore Name > Auth DisplayName > Auth Email
    final String displayName =
        reservation.userName ?? reservation.userEmail ?? 'Cliente';

    return Opacity(
      opacity: isSelectionMode && !isSelectable ? 0.4 : 1.0,
      child: AppCard(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        onTap: onTap,
        child: Row(
          children: [
            if (isSelectionMode) ...[
              Checkbox(
                value: isSelected,
                onChanged: isSelectable ? (_) => onTap?.call() : null,
                activeColor: colorScheme.primary,
              ),
              const SizedBox(width: 8),
            ],
            // Fecha
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withAlpha(80),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(
                    date != null ? dayFormat.format(date).toUpperCase() : '??',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    date != null ? hourFormat.format(date) : '--:--',
                    style: TextStyle(
                      color: colorScheme.primary.withAlpha(180),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAdmin
                        ? displayName
                        : 'Mesa para ${reservation.seats} personas',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${reservation.seats} comensales',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Estado
            _buildStatusBadge(reservation.state),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String? status) {
    switch (status) {
      case ReservationStatus.confirmed:
        return AppBadge.success(label: 'CONFIRMADA');
      case ReservationStatus.completed:
        return const AppBadge(
          label: 'COMPLETADA',
          backgroundColor: Colors.blueGrey,
          textColor: Colors.white,
        );
      case ReservationStatus.cancelled:
        return AppBadge.error(label: 'CANCELADA');
      default:
        return AppBadge.warning(label: 'PENDIENTE');
    }
  }
}
