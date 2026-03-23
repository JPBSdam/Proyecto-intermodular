import 'package:app_restaurante/core/navigation/app_routes.dart';
import 'package:app_restaurante/core/widgets/home_button.dart';
import 'package:app_restaurante/core/widgets/loading_overlay.dart';
import 'package:app_restaurante/core/widgets/confirmation_dialog.dart';
import 'package:app_restaurante/data/model/dish.dart';
import 'package:app_restaurante/ui/viewmodels/firestore/dish_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class DishDetailView extends StatefulWidget {
  final String dishId;

  const DishDetailView({super.key, required this.dishId});

  @override
  State<DishDetailView> createState() => _DishDetailViewState();
}

class _DishDetailViewState extends State<DishDetailView> {
  Dish? _dish;
  bool _isLoading = true;
  String _error = '';
  late final DishViewModel _dishViewModel;

  @override
  void initState() {
    super.initState();
    _dishViewModel = context.read<DishViewModel>();
    _loadDish();
  }

  Future<void> _loadDish() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final dish = await _dishViewModel.fetchDishById(widget.dishId);
      setState(() => _dish = dish);
    } catch (e) {
      setState(() => _error = 'Error al cargar el plato: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteDish() async {
    if (_dish == null) return;

    final confirm = await showDialogYesNo(
      context,
      "¿Estás seguro de que quieres eliminar este plato?",
    );

    if (confirm == true && context.mounted) {
      await _dishViewModel.deleteDish(_dish!.id!);
      if (mounted) context.go(AppRoutes.dishes);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget bodyContent;

    if (_error.isNotEmpty) {
      bodyContent = Center(child: Text(_error));
    } else if (_dish == null) {
      bodyContent = const Center(child: Text("Plato no encontrado"));
    } else {
      bodyContent = Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _dish!.name ?? '',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text("Categoría: ${_dish!.category ?? '-'}"),
            Text("Precio: ${_dish!.price?.toStringAsFixed(2) ?? '-'} €"),
            Text("Disponible: ${_dish!.available == true ? "Sí" : "No"}"),
            const SizedBox(height: 16),
            Text(_dish!.description ?? 'Sin descripción'),
          ],
        ),
      );
    }

    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_dish?.name ?? "Detalle del Plato"),
          actions: [
            if (_dish != null && (_dish!.id?.isNotEmpty ?? false))
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: _deleteDish,
              ),
            IconButton(
              onPressed: () {
                context.go(AppRoutes.dishFormEdit(_dish!.id!));
              },
              icon: const Icon(Icons.edit),
            ),
            const HomeButton(),
          ],
        ),
        body: bodyContent,
      ),
    );
  }
}
