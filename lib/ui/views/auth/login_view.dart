import 'package:app_restaurante/core/config/app_theme.dart';
import 'package:app_restaurante/core/navigation/app_routes.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:app_restaurante/core/widgets/loading_overlay.dart';
import 'package:app_restaurante/core/widgets/sabros_app_bar.dart';
import 'package:app_restaurante/core/widgets/snackbars.dart';
import 'package:app_restaurante/ui/viewmodels/auth/login_viewmodel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ─── Handlers ────────────────────────────────────────────────────────────────

  Future<void> _handleEmailLogin(LoginViewModel viewModel) async {
    if (!_formKey.currentState!.validate()) return;

    final success = await viewModel.signInWithEmail(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (success) {
      if (mounted) context.go(AppRoutes.home);
    } else if (mounted) {
      _showError(viewModel.errorMessage);
    }
  }

  Future<void> _handleGoogleLogin(LoginViewModel viewModel) async {
    final success = await viewModel.signInWithGoogle();
    if (success) {
      if (mounted) context.go(AppRoutes.home);
    } else if (mounted && viewModel.errorMessage != null) {
      _showError(viewModel.errorMessage);
    }
  }

  void _showError(String? message) {
    showSnackBar(context, message ?? 'Error desconocido', error: true);
  }

  void _goToRegister() {
    context.go(AppRoutes.register);
  }

  Future<void> _showForgotPasswordDialog(LoginViewModel viewModel) async {
    final emailController = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Recuperar contraseña'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Introduce tu email para recuperar la contraseña.',
              style: TextStyle(
                color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                hintText: 'tu@email.com',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (emailController.text.isEmpty) {
                Navigator.pop(dialogContext);
                _showError('Por favor ingresa tu email.');
                emailController.dispose();
                return;
              }

              Navigator.pop(dialogContext);
              final success = await viewModel.resetPassword(
                email: emailController.text,
              );

              if (mounted) {
                if (success) {
                  showSnackBar(
                    context,
                    'Email de recuperación enviado. Revisa tu bandeja.',
                    success: true,
                  );
                } else {
                  _showError(viewModel.errorMessage ?? 'Error al enviar email');
                }
              }
              emailController.dispose();
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  // ─── Widgets del formulario ───────────────────────────────────────────────────

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      autocorrect: false,
      enableSuggestions: false,
      textCapitalization: TextCapitalization.none,
      decoration: const InputDecoration(
        labelText: 'Email',
        border: OutlineInputBorder(),
        hintText: 'ejemplo@correo.com',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Por favor ingresa tu email';
        if (!value.contains('@')) return 'Email inválido';
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: 'Contraseña',
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingresa tu contraseña';
        }
        return null;
      },
    );
  }

  Widget _buildLoginButton(LoginViewModel viewModel) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: viewModel.isLoading
            ? null
            : () => _handleEmailLogin(viewModel),
        child: const Text('Iniciar Sesión'),
      ),
    );
  }

  Widget _buildGoogleButton(LoginViewModel viewModel) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: viewModel.isLoading
            ? null
            : () => _handleGoogleLogin(viewModel),
        style: OutlinedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset('assets/google_logo.svg', width: 20, height: 20),
            const SizedBox(width: 12),
            const Text('Iniciar con Google'),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterLink(LoginViewModel viewModel) {
    return Column(
      children: [
        TextButton(
          onPressed: viewModel.isLoading ? null : _goToRegister,
          child: const Text('¿No tienes cuenta? Únete a SabrosApp!'),
        ),
        TextButton(
          onPressed: viewModel.isLoading
              ? null
              : () => _showForgotPasswordDialog(viewModel),
          child: const Text(
            '¿Olvidaste tu contraseña?',
            style: TextStyle(color: Colors.deepOrange),
          ),
        ),
      ],
    );
  }

  Widget _buildForm(LoginViewModel viewModel) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildEmailField(),
          const SizedBox(height: 16),
          _buildPasswordField(),
          const SizedBox(height: 24),
          _buildLoginButton(viewModel),
          if (kIsWeb || defaultTargetPlatform != TargetPlatform.macOS) ...[
            const SizedBox(height: 16),
            _buildGoogleButton(viewModel),
          ],
          const SizedBox(height: 16),
          _buildRegisterLink(viewModel),
        ],
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    //se ha movido la creación del viewmodel al router
    final viewModel = context.watch<LoginViewModel>();

    return LoadingOverlay(
      isLoading: viewModel.isLoading,
      child: Scaffold(
        appBar: SabrosAppBar(
          pageTitle: 'Iniciar Sesión',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Volver al inicio',
            onPressed: () => context.go(AppRoutes.home),
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppTheme.kFormMaxWidth),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildForm(viewModel),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
