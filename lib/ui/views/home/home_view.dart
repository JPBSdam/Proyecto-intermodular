import 'package:app_restaurante/core/config/app_theme.dart';
import 'package:app_restaurante/core/navigation/app_routes.dart';
import 'package:app_restaurante/core/widgets/app_badge.dart';
import 'package:app_restaurante/core/widgets/app_card.dart';
import 'package:app_restaurante/core/widgets/confirmation_dialog.dart';
import 'package:app_restaurante/core/widgets/app_bottom_nav.dart';
import 'package:app_restaurante/core/widgets/app_drawer.dart';
import 'package:app_restaurante/core/widgets/app_logo_title.dart';
import 'package:app_restaurante/core/widgets/app_user_avatar.dart';
import 'package:app_restaurante/core/widgets/loading_overlay.dart';
import 'package:app_restaurante/core/widgets/snackbars.dart';
import 'package:app_restaurante/ui/viewmodels/firestore/dish_viewmodel.dart';
import 'package:app_restaurante/ui/viewmodels/firestore/restaurant_viewmodel.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
      context.read<RestaurantViewModel>().watchRestaurant();

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

  void _showLoginRequiredDialog(BuildContext context) async {
    final confirmed = await showDialogYesNo(
      context,
      title: 'Inicia sesión para continuar',
      cuestion:
          'Necesitas iniciar sesión para acceder a esta función. ¿Deseas hacerlo ahora?',
    );
    if (confirmed == true && context.mounted) {
      context.go(AppRoutes.login);
    }
  }

  // ── UI ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<HomeViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            title: const AppLogoTitle(),
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
      return const LoadingOverlay(isLoading: true, child: SizedBox.shrink());
    }

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

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppTheme.kContentMaxWidth),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroSection(viewModel),
              _buildSuggestionsSection(dishViewModel),
              _buildRestaurantSection(viewModel),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(HomeViewModel viewModel) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final restaurantVM = context.watch<RestaurantViewModel>();
    final restaurantImage = restaurantVM.restaurant?.urlImage;
    final heroImage = (restaurantImage != null && restaurantImage.isNotEmpty)
        ? restaurantImage
        : 'https://images.unsplash.com/photo-1514362545857-3bc16c4c7d1b?auto=format&fit=crop&w=1350&q=80';

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
        image: DecorationImage(
          image: CachedNetworkImageProvider(heroImage),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            stops: [0.0, 0.45, 1.0],
            colors: [Color(0xE0000000), Color(0x80000000), Color(0x00000000)],
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (!viewModel.isGuest) ...[
              Text(
                '¡Hola, ${viewModel.displayName}!',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white.withAlpha(220),
                  fontWeight: FontWeight.w500,
                  shadows: const [
                    Shadow(color: Color(0xCC000000), blurRadius: 6),
                  ],
                ),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              'Experiencia\nGastronómica',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                height: 1.1,
                shadows: const [
                  Shadow(color: Color(0xCC000000), blurRadius: 8),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Sabor y elegancia en tu mesa',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.white.withAlpha(200),
                shadows: const [
                  Shadow(color: Color(0xAA000000), blurRadius: 6),
                ],
              ),
            ),
            if (viewModel.isGuest) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: Container(
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
                          onPressed: () {
                            if (viewModel.isGuest) {
                              _showLoginRequiredDialog(context);
                              return;
                            }

                            if (!viewModel.isEmailVerified) {
                              showSnackBar(
                                context,
                                'Verifica tu correo electrónico para poder hacer reservas',
                                error: true,
                              );
                              return;
                            }

                            context.go(AppRoutes.reservationFormCreate());
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
      return const SizedBox(
        height: 120,
        child: LoadingOverlay(isLoading: true, child: SizedBox.expand()),
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
                                webHtmlElementStrategy:
                                    WebHtmlElementStrategy.fallback,
                                loadingBuilder: (_, child, progress) =>
                                    progress == null
                                    ? child
                                    : LoadingOverlay(
                                        isLoading: true,
                                        child: Container(
                                          width: 95,
                                          height: 95,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary.withAlpha(20),
                                        ),
                                      ),
                                errorBuilder: (_, __, ___) => Container(
                                  width: 95,
                                  height: 95,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withAlpha(20),
                                  child: const Icon(Icons.restaurant, size: 32),
                                ),
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

  Widget _buildRestaurantSection(HomeViewModel homeVM) {
    final restaurantVM = context.watch<RestaurantViewModel>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (restaurantVM.isLoading) {
      return const SizedBox(
        height: 120,
        child: LoadingOverlay(isLoading: true, child: SizedBox.expand()),
      );
    }

    final isOpen = restaurantVM.restaurant?.open == true;
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
                  restaurantVM.restaurant?.name ?? '',
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
          if (restaurantVM.restaurant?.description != null) ...[
            Text(
              restaurantVM.restaurant!.description!,
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
            restaurantVM.restaurant?.address ?? 'Sin dirección',
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.phone_outlined,
            restaurantVM.restaurant?.phoneNumber ?? 'Sin teléfono',
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.mail,
            restaurantVM.restaurant?.email ?? 'Sin email',
          ),

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
