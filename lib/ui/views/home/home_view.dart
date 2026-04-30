import 'package:app_restaurante/core/navigation/app_routes.dart';
import 'package:app_restaurante/core/widgets/app_badge.dart';
import 'package:app_restaurante/core/widgets/app_card.dart';
import 'package:app_restaurante/core/widgets/app_bottom_nav.dart';
import 'package:app_restaurante/core/widgets/app_drawer.dart';
import 'package:app_restaurante/core/widgets/app_logo_title.dart';
import 'package:app_restaurante/core/widgets/app_user_avatar.dart';
import 'package:app_restaurante/ui/viewmodels/firestore/dish_viewmodel.dart';
import 'package:app_restaurante/ui/viewmodels/firestore/restaurant_viewmodel.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:app_restaurante/ui/viewmodels/firestore/reservation_viewmodel.dart';
import 'package:app_restaurante/ui/viewmodels/home/home_viewmodel.dart';
import '../../../core/widgets/verification_banner.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key, this.title = 'SabrosApp'});
  final String title;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DishViewModel>().watchDishes();

      // Si el usuario ya está logueado como ADMIN, activamos la escucha de reservas
      final homeVM = context.read<HomeViewModel>();
      if (homeVM.userRole == 'ADMIN') {
        context.read<ReservationViewModel>().watchAll();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<HomeViewModel>().checkEmailVerification();
    }
  }

  // ── Lógica de autenticación ──────────────────────────────

  /// Muestra un diálogo informativo si el usuario intenta acceder a funciones
  /// que requieren autenticación (reservas, perfil), pero está en estado de invitado.
  void _showLoginRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Inicia sesión para continuar'),
          content: const Text(
            'Necesitas iniciar sesión para acceder a esta función. ¿Deseas hacerlo ahora?',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go(AppRoutes.login);
              },
              child: const Text('Iniciar Sesión'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Más tarde'),
            ),
          ],
        );
      },
    );
  }

  // ── UI ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<HomeViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: colorScheme.surface,
            elevation: 0,
            title: const AppLogoTitle(),
            // AppUserAvatar sustituido por el botón de perfil con lógica de autenticación
            actions: const [AppUserAvatar()],
          ),
          drawer: const AppDrawer(),
          body: Column(
            children: [
              const VerificationBanner(),
              Expanded(child: _buildBody(viewModel)),
            ],
          ),
          bottomNavigationBar: const AppBottomNav(),
        );
      },
    );
  }

  Widget _buildBody(HomeViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Mostrar error si existe
    if (viewModel.errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(viewModel.errorMessage),
          ],
        ),
      );
    }

    final dishViewModel = context.watch<DishViewModel>();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroSection(viewModel),
          _buildSuggestionsSection(dishViewModel),
          _buildRestaurantSection(context, viewModel),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeroSection(HomeViewModel viewModel) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 380,
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        image: const DecorationImage(
          image: NetworkImage(
            'https://images.unsplash.com/photo-1514362545857-3bc16c4c7d1b?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [colorScheme.scrim.withAlpha(220), Colors.transparent],
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Saludo personalizado para usuario autenticado
            if (!viewModel.isGuest) ...[
              Text(
                '¡Hola, ${viewModel.displayName}!',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onPrimary.withAlpha(220),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              'Experiencia\nGastronómica',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineLarge?.copyWith(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Sabor y elegancia en tu mesa',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onPrimary.withAlpha(200),
              ),
            ),
            // Banner informativo para invitados
            if (viewModel.isGuest) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha(180),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Explora nuestra carta sin cuenta. ¡Inicia sesión para reservar!',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.login),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Entrar',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => context.go(AppRoutes.dishes),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.surface,
                      foregroundColor: colorScheme.onSurface,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Ver carta',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: colorScheme.onPrimary.withAlpha(51),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colorScheme.onPrimary.withAlpha(77),
                            width: 1.5,
                          ),
                        ),
                        child: TextButton(
                          // Si es invitado, muestra el diálogo de login; si está autenticado, va a reservar
                          onPressed: () {
                            if (viewModel.isGuest) {
                              _showLoginRequiredDialog(context);
                            } else {
                              context.go(AppRoutes.reservationFormCreate());
                            }
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            foregroundColor: colorScheme.onPrimary,
                          ),
                          child: Text(
                            'Reservar',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsSection(DishViewModel dishVM) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (dishVM.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (dishVM.errorMessage.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'No se pudieron cargar las sugerencias: ${dishVM.errorMessage}',
          style: TextStyle(color: colorScheme.error),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (dishVM.dishes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(
          child: Text('No hay platos disponibles en este momento.'),
        ),
      );
    }

    final randomDishes = List.of(dishVM.dishes)..shuffle();
    final suggestions = randomDishes.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sugerencias',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              TextButton(
                onPressed: () => context.go(AppRoutes.dishes),
                child: Text(
                  'EXPLORAR',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: suggestions.length,
          itemBuilder: (context, index) {
            final dish = suggestions[index];
            return AppCard(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              borderRadius: 22,
              onTap: () => context.push(AppRoutes.dishDetail(dish.id!)),
              child: Row(
                children: [
                  Hero(
                    tag: 'dish_${dish.id}',
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadow.withAlpha(20),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child:
                            (dish.urlImage != null && dish.urlImage!.isNotEmpty)
                            ? Image.network(
                                dish.urlImage!,
                                width: 95,
                                height: 95,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 95,
                                height: 95,
                                color: colorScheme.surfaceContainerHighest,
                                child: Icon(
                                  Icons.restaurant,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dish.name ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          dish.category ?? 'Especialidad',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${dish.price?.toStringAsFixed(2)}€',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRestaurantSection(BuildContext context, HomeViewModel homeVM) {
    final restaurantVM = context.watch<RestaurantViewModel>();
    final restaurant = restaurantVM.restaurant;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (restaurantVM.isLoading || restaurant == null) {
      return const SizedBox.shrink();
    }

    final isOpen = restaurant.open == true;
    final bool isAdmin = homeVM.userRole == 'ADMIN';

    return AppCard(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  restaurant.name ?? 'Nuestro Restaurante',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              isOpen
                  ? AppBadge.success(label: "Abierto")
                  : AppBadge.error(label: "Cerrado"),
            ],
          ),
          if (restaurant.description != null) ...[
            const SizedBox(height: 12),
            Text(
              restaurant.description!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(height: 1),
          ),
          _buildInfoRow(
            Icons.location_on_outlined,
            restaurant.address ?? 'Sin dirección',
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.phone_outlined,
            restaurant.phoneNumber ?? 'Sin teléfono',
          ),
          // Solo mostrar botón de gestión si es ADMIN
          if (isAdmin) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.push(AppRoutes.restaurantForm),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text("Gestionar restaurante"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                  side: BorderSide(color: colorScheme.primary.withAlpha(50)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: colorScheme.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
