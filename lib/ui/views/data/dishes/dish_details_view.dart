import 'package:app_restaurante/core/widgets/app_badge.dart';
import 'package:app_restaurante/core/navigation/app_routes.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewmodel = context.read<DishViewModel>();
      _loadDish(viewmodel);
    });
  }

  Future<void> _loadDish(DishViewModel viewmodel) async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final dish = await viewmodel.fetchDishById(widget.dishId);
      setState(() => _dish = dish);
    } catch (e) {
      setState(() => _error = 'Error al cargar el plato: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteDish(DishViewModel viewmodel) async {
    if (_dish == null) return;

    final confirm = await showDialogYesNo(
      context,
      title: 'Eliminar ${_dish!.name}',
      cuestion: "¿Estás seguro de que quieres eliminar este plato?",
    );

    if (confirm == true && context.mounted) {
      await viewmodel.deleteDish(_dish!.id!);
      if (mounted) context.go(AppRoutes.dishes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final viewmodel = context.watch<DishViewModel>();

    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: _error.isNotEmpty
            ? Center(child: Text(_error, style: theme.textTheme.bodyLarge))
            : _dish == null
            ? Center(
                child: Text(
                  "Plato no encontrado",
                  style: theme.textTheme.bodyLarge,
                ),
              )
            : CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Cabecera
                  SliverAppBar(
                    expandedHeight: 350,
                    pinned: true,
                    stretch: true,
                    backgroundColor: colorScheme.surface,
                    leading: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withAlpha(200),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                        onPressed: () => context.pop(),
                      ),
                    ),
                    actions: [
                      _buildActionCircle(
                        icon: Icons.edit_outlined,
                        color: colorScheme.primary,
                        onPressed: () =>
                            context.push(AppRoutes.dishFormEdit(_dish!.id!)),
                      ),
                      _buildActionCircle(
                        icon: Icons.delete_outline,
                        color: colorScheme.error,
                        onPressed: () => _deleteDish(viewmodel),
                      ),
                      const SizedBox(width: 8),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      stretchModes: const [
                        StretchMode.zoomBackground,
                        StretchMode.blurBackground,
                      ],
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (_dish!.urlImage != null &&
                              _dish!.urlImage!.isNotEmpty)
                            Image.network(_dish!.urlImage!, fit: BoxFit.cover)
                          else
                            Container(
                              color: colorScheme.primaryContainer,
                              child: Icon(
                                Icons.restaurant,
                                color: colorScheme.onPrimaryContainer.withAlpha(
                                  100,
                                ),
                                size: 100,
                              ),
                            ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  colorScheme.scrim.withAlpha(0),
                                  colorScheme.scrim.withAlpha(115),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Contenido con bordes redondeados superpuestos
                  SliverToBoxAdapter(
                    child: Transform.translate(
                      offset: const Offset(0, -30),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(32, 40, 32, 32),
                        decoration: BoxDecoration(
                          color: theme.scaffoldBackgroundColor,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(32),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.shadow.withAlpha(20),
                              blurRadius: 15,
                              offset: const Offset(0, -5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                AppBadge(
                                  label: _dish!.category ?? 'GENERAL',
                                  borderRadius: 12,
                                ),
                                if (_dish!.available == false)
                                  AppBadge.error(label: 'NO DISPONIBLE'),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Text(
                              _dish!.name ?? 'Sin nombre',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${_dish!.price?.toStringAsFixed(2) ?? "0.00"}€',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 32),
                              child: Divider(),
                            ),
                            Text(
                              'Descripción',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _dish!.description ?? '',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                height: 1.6,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 120),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildActionCircle({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface.withAlpha(200),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 20),
        onPressed: onPressed,
      ),
    );
  }
}
