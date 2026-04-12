import 'package:app_restaurante/core/navigation/app_routes.dart';
import 'package:app_restaurante/core/widgets/loading_overlay.dart';
import 'package:app_restaurante/ui/viewmodels/auth/login_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Pantalla de Login
/// Muestra el formulario de inicio de sesión con email, Google o modo anónimo.
/// Gestiona la validación de campos, interacción con LoginViewModel y
/// muestra errores mediante SnackBar. La lógica de negocio está en el ViewModel.

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
    if (!success && mounted) _showError(viewModel.errorMessage);
  }

  Future<void> _handleGoogleLogin(LoginViewModel viewModel) async {
    final success = await viewModel.signInWithGoogle();
    if (!success && mounted && viewModel.errorMessage != null) {
      _showError(viewModel.errorMessage);
    }
  }

  Future<void> _handleAnonymousLogin(LoginViewModel viewModel) async {
    final success = await viewModel.signInAnonymously();
    if (!success && mounted) _showError(viewModel.errorMessage);
  }

  void _showError(String? message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message ?? 'Error desconocido'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _goToRegister() {
    context.go(AppRoutes.register);
  }

  // ─── Widgets del formulario ───────────────────────────────────────────────────

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: const InputDecoration(
        labelText: 'Email',
        border: OutlineInputBorder(),
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
    return ElevatedButton(
      onPressed: viewModel.isLoading
          ? null
          : () => _handleEmailLogin(viewModel),
      child: const Text('Iniciar Sesión'),
    );
  }

  Widget _buildGoogleButton(LoginViewModel viewModel) {
    return ElevatedButton(
      onPressed: viewModel.isLoading
          ? null
          : () => _handleGoogleLogin(viewModel),
      child: const Text('Iniciar con Google'),
    );
  }

  Widget _buildAnonymousButton(LoginViewModel viewModel) {
    return ElevatedButton(
      onPressed: viewModel.isLoading
          ? null
          : () => _handleAnonymousLogin(viewModel),
      child: const Text('Continuar como invitado'),
    );
  }

  Widget _buildRegisterLink(LoginViewModel viewModel) {
    return TextButton(
      onPressed: viewModel.isLoading ? null : _goToRegister,
      child: const Text('¿No tienes cuenta? Únete a SabrosApp!'),
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
          const SizedBox(height: 16),
          _buildGoogleButton(viewModel),
          const SizedBox(height: 16),
          _buildAnonymousButton(viewModel),
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
        appBar: AppBar(title: const Text('Iniciar Sesión')),
        body: LoadingOverlay(
          isLoading: viewModel.isLoading,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildForm(viewModel),
          ),
        ),
      ),
    );
  }
}
