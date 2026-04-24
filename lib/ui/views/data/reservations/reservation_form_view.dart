import 'package:app_restaurante/core/navigation/app_routes.dart';
import 'package:app_restaurante/core/widgets/app_card.dart';
import 'package:app_restaurante/core/widgets/loading_overlay.dart';
import 'package:app_restaurante/core/widgets/sabros_app_bar.dart';
import 'package:app_restaurante/core/widgets/snackbars.dart';
import 'package:app_restaurante/data/model/reservation.dart';
import 'package:app_restaurante/data/services/firestore/reservation_service.dart';
import 'package:app_restaurante/ui/viewmodels/firestore/reservation_viewmodel.dart';
import 'package:app_restaurante/data/services/firestore/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Formulario para crear o editar una reserva.
/// - Usa showDatePicker y showTimePicker nativos de Flutter (sin librerías extra).
/// - Contador +/- para el número de personas (enteros, mín 1, máx 20).
/// - Checkbox bebé/carricoche.
/// - Rellena userId, userName y userEmail desde FirebaseAuth automáticamente.
///
/// NOTA ROLES: la lógica de aceptar/cancelar desde admin va en reservation_detail_view.

class ReservationFormView extends StatefulWidget {
  final String? reservationId;
  const ReservationFormView({super.key, this.reservationId});

  @override
  State<ReservationFormView> createState() => _ReservationFormViewState();
}

class _ReservationFormViewState extends State<ReservationFormView> {
  final _formKey = GlobalKey<FormState>();
  final _commentsController = TextEditingController();

  DateTime? _selectedDate;
  int _seats = 1;
  bool _hasBaby = false;
  // feat: contador de bebés (desplegable tras marcar hasBaby)
  int _babyCount = 1;
  // fix: flag de carga para cuando se edita (carga de Firestore por ID)
  bool _loadingEdit = false;
  Reservation? _reservation;

  @override
  void initState() {
    super.initState();
    if (widget.reservationId != null) {
      _loadExisting(widget.reservationId!);
    }
  }

  // fix: carga la reserva directamente de Firestore por ID en lugar de
  // buscarla en vm.reservations (que puede estar vacío y causaba duplicados)
  Future<void> _loadExisting(String id) async {
    setState(() => _loadingEdit = true);
    try {
      final found = await ReservationService().getById(id);
      if (found != null && mounted) {
        setState(() {
          _reservation = found;
          _seats = found.seats ?? 1;
          _hasBaby = found.hasBaby ?? false;
          _babyCount = found.babyCount ?? 1;
          _commentsController.text = found.comments ?? '';
          _selectedDate = found.reservationDate;
        });
      }
    } finally {
      if (mounted) setState(() => _loadingEdit = false);
    }
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: Theme.of(context).colorScheme.primary,
          ),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate ?? now),
      initialEntryMode: TimePickerEntryMode.input, // reloj digital
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (time == null || !mounted) return;

    setState(() {
      _selectedDate = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submit(ReservationViewModel vm) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      showSnackBar(context, 'Selecciona fecha y hora', error: true);
      return;
    }

    final fbUser = FirebaseAuth.instance.currentUser;
    if (fbUser == null) {
      showSnackBar(
        context,
        'Debes estar autenticado para reservar',
        error: true,
      );
      return;
    }

    // Intentamos obtener los datos reales desde Firestore antes de guardar
    String? realName = fbUser.displayName;
    String? realPhone;
    try {
      final userDoc = await UserService().getUserById(fbUser.uid);
      if (userDoc != null) {
        if (userDoc.name != null && userDoc.name!.isNotEmpty) {
          realName = userDoc.name;
        }
        realPhone = userDoc.phoneNumber;
      }
    } catch (_) {}

    final updated = Reservation(
      id: _reservation?.id,
      userId: fbUser.uid,
      userName: (realName != null && realName.isNotEmpty)
          ? realName
          : fbUser.email,
      userEmail: fbUser.email,
      userPhone: realPhone,
      seats: _seats,
      reservationDate: _selectedDate,
      comments: _commentsController.text.trim().isEmpty
          ? null
          : _commentsController.text.trim(),
      hasBaby: _hasBaby,
      // feat: guarda babyCount solo si hasBaby está marcado
      babyCount: _hasBaby ? _babyCount : null,
      // feat: siempre se guarda como pending al crear o editar
      // (si estaba confirmed, vuelve a pending para que el admin reconfirme)
      state: ReservationStatus.pending,
      createdAt: _reservation?.createdAt ?? DateTime.now(),
    );

    if (_reservation == null) {
      await vm.addReservation(updated);
    } else {
      await vm.updateReservation(updated);
    }

    if (mounted && vm.errorMessage.isEmpty) {
      showSnackBar(
        context,
        _reservation == null
            ? '¡Reserva enviada! En breve confirmaremos tu solicitud'
            : 'Reserva actualizada correctamente',
        success: true,
      );
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.home);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReservationViewModel>();
    final isEditing = _reservation != null;
    final theme = Theme.of(context);

    return LoadingOverlay(
      isLoading: vm.isLoading || _loadingEdit,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: SabrosAppBar(
          pageTitle: isEditing ? 'EDITAR RESERVA' : 'NUEVA RESERVA',
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
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionTitle('FECHA Y HORA'),
                const SizedBox(height: 12),
                AppCard(
                  padding: EdgeInsets.zero,
                  onTap: _pickDateTime,
                  child: ListTile(
                    leading: Icon(
                      Icons.calendar_today,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(
                      _selectedDate != null
                          ? '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}'
                          : 'Seleccionar fecha',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    trailing: Text(
                      _selectedDate != null
                          ? '${_selectedDate!.hour.toString().padLeft(2, '0')}:${_selectedDate!.minute.toString().padLeft(2, '0')}'
                          : '--:--',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                _buildSectionTitle('COMENSALES'),
                const SizedBox(height: 12),
                AppCard(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _counterButton(
                        Icons.remove,
                        _seats > 1 ? () => setState(() => _seats--) : null,
                      ),
                      Text(
                        '$_seats',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      _counterButton(
                        Icons.add,
                        _seats < 20 ? () => setState(() => _seats++) : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      SwitchListTile(
                        value: _hasBaby,
                        onChanged: (v) => setState(() => _hasBaby = v),
                        title: const Text(
                          '¿Necesitas espacio para carrito?',
                          style: TextStyle(fontSize: 14),
                        ),
                        secondary: Icon(
                          Icons.child_friendly,
                          color: _hasBaby
                              ? theme.colorScheme.primary
                              : Colors.grey,
                        ),
                      ),
                      if (_hasBaby) ...[
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Número de bebés'),
                              Row(
                                children: [
                                  _counterButton(
                                    Icons.remove,
                                    _babyCount > 1
                                        ? () => setState(() => _babyCount--)
                                        : null,
                                    mini: true,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: Text(
                                      '$_babyCount',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  _counterButton(
                                    Icons.add,
                                    _babyCount < 10
                                        ? () => setState(() => _babyCount++)
                                        : null,
                                    mini: true,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                _buildSectionTitle('COMENTARIOS ADICIONALES'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _commentsController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Alergias, preferencias de mesa...',
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                FilledButton(
                  onPressed: () => _submit(vm),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    isEditing ? 'GUARDAR CAMBIOS' : 'SOLICITAR RESERVA',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary.withAlpha(200),
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _counterButton(
    IconData icon,
    VoidCallback? onPressed, {
    bool mini = false,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        backgroundColor: Theme.of(
          context,
        ).colorScheme.primaryContainer.withAlpha(100),
        foregroundColor: Theme.of(context).colorScheme.primary,
        padding: EdgeInsets.all(mini ? 4 : 12),
      ),
    );
  }

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }
}
