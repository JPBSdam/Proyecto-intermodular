import 'package:app_restaurante/core/navigation/app_routes.dart';
import 'package:app_restaurante/core/widgets/home_button.dart';
import 'package:app_restaurante/core/widgets/loading_overlay.dart';
import 'package:app_restaurante/core/widgets/snackbars.dart';
import 'package:app_restaurante/data/model/reservation.dart';
import 'package:app_restaurante/ui/viewmodels/firestore/reservation_viewmodel.dart';
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
  Reservation? _reservation;

  @override
  void initState() {
    super.initState();
    if (widget.reservationId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final vm = context.read<ReservationViewModel>();
        final found = vm.reservations.cast<Reservation?>().firstWhere(
          (r) => r?.id == widget.reservationId,
          orElse: () => null,
        );
        if (found != null && mounted) {
          setState(() {
            _reservation = found;
            _seats = found.seats ?? 1;
            _hasBaby = found.hasBaby ?? false;
            _commentsController.text = found.comments ?? '';
            _selectedDate = found.reservationDate;
          });
        }
      });
    }
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate ?? now),
      initialEntryMode: TimePickerEntryMode.input, // reloj digital
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
    final updated = Reservation(
      id: _reservation?.id,
      userId: fbUser?.uid,
      userName: fbUser?.displayName ?? fbUser?.email,
      userEmail: fbUser?.email,
      seats: _seats,
      reservationDate: _selectedDate,
      comments: _commentsController.text.trim().isEmpty
          ? null
          : _commentsController.text.trim(),
      hasBaby: _hasBaby,
      state: _reservation?.state ?? ReservationStatus.pending,
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
            ? '¡Reserva enviada! En breve confirmaremos tu solicitud 🎉'
            : 'Reserva actualizada correctamente ✅',
        success: true,
      );
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReservationViewModel>();
    final isEditing = _reservation != null;

    return LoadingOverlay(
      isLoading: vm.isLoading || _loadingEdit,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? 'Editar reserva' : 'Nueva reserva'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Volver al inicio',
            onPressed: () => context.go(AppRoutes.home),
          ),
          actions: const [HomeButton()],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Fecha y hora ──────────────────────────────────────────
                const Text(
                  'Fecha y hora',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 6),
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    _selectedDate != null
                        ? '${_selectedDate!.day.toString().padLeft(2, '0')}/'
                              '${_selectedDate!.month.toString().padLeft(2, '0')}/'
                              '${_selectedDate!.year}  '
                              '${_selectedDate!.hour.toString().padLeft(2, '0')}:'
                              '${_selectedDate!.minute.toString().padLeft(2, '0')}'
                        : 'Seleccionar fecha y hora',
                  ),
                  onPressed: _pickDateTime,
                ),
                const SizedBox(height: 24),

                // ── Número de personas (contador) ─────────────────────────
                const Text(
                  'Número de personas',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton.filled(
                      icon: const Icon(Icons.remove),
                      onPressed: _seats > 1
                          ? () => setState(() => _seats--)
                          : null,
                    ),
                    const SizedBox(width: 28),
                    Text(
                      '$_seats',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 28),
                    IconButton.filled(
                      icon: const Icon(Icons.add),
                      onPressed: _seats < 20
                          ? () => setState(() => _seats++)
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Bebé / carricoche ─────────────────────────────────────
                Card(
                  margin: EdgeInsets.zero,
                  child: Column(
                    children: [
                      CheckboxListTile(
                        value: _hasBaby,
                        onChanged: (v) =>
                            setState(() => _hasBaby = v ?? false),
                        title: const Text('Venimos con bebé'),
                        subtitle: const Text(
                          'Necesitamos espacio para carricoche',
                          style: TextStyle(fontSize: 12),
                        ),
                        secondary: const Icon(Icons.child_friendly),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      if (_hasBaby) ...[
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.baby_changing_station,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                '¿Cuántos bebés?',
                                style: TextStyle(fontSize: 14),
                              ),
                              const Spacer(),
                              IconButton.filled(
                                icon: const Icon(Icons.remove),
                                onPressed: _babyCount > 1
                                    ? () => setState(() => _babyCount--)
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Text(
                                '$_babyCount',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 16),
                              IconButton.filled(
                                icon: const Icon(Icons.add),
                                onPressed: _babyCount < 10
                                    ? () => setState(() => _babyCount++)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Comentarios ───────────────────────────────────────────
                TextFormField(
                  controller: _commentsController,
                  decoration: const InputDecoration(
                    labelText: 'Comentarios / peticiones especiales',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: () => _submit(vm),
                  child: Text(
                    isEditing ? 'Actualizar reserva' : 'Solicitar reserva',
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
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }
}
