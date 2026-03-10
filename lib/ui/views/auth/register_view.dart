import 'package:app_restaurante/core/widgets/loading_overlay.dart';
import 'package:app_restaurante/ui/viewmodels/auth/register_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Vista de Registro - UI pura sin lógica de negocio
class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ─── Handlers ────────────────────────────────────────────────────────────────

  Future<void> _handleRegister(RegisterViewModel viewModel) async {
    if (!_formKey.currentState!.validate()) return;

    final success = await viewModel.signUpWithEmail(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (!success) {
      _showError(viewModel.errorMessage);
      return;
    }

    // El AuthWrapper redirigirá automáticamente
    _goBackToLogin();
  }

  void _showError(String? message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message ?? 'Error desconocido'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _goBackToLogin() {
    Navigator.of(context).pop();
  }

  void _togglePasswordVisibility() {
    setState(() => _obscurePassword = !_obscurePassword);
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
        if (value == null || value.isEmpty) {
          return 'Por favor ingresa tu email';
        }
        if (!value.contains('@')) {
          return 'Email inválido';
        }
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
          onPressed: _togglePasswordVisibility,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingresa una contraseña';
        }
        if (value.length < 6) {
          return 'La contraseña debe tener al menos 6 caracteres';
        }
        return null;
      },
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: _obscurePassword,
      decoration: const InputDecoration(
        labelText: 'Confirmar contraseña',
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor confirma tu contraseña';
        }
        if (value != _passwordController.text) {
          return 'Las contraseñas no coinciden';
        }
        return null;
      },
    );
  }

  Widget _buildRegisterButton(RegisterViewModel viewModel) {
    return ElevatedButton(
      onPressed: viewModel.isLoading ? null : () => _handleRegister(viewModel),
      child: const Text('Registrarse'),
    );
  }

  Widget _buildLoginLink(RegisterViewModel viewModel) {
    return TextButton(
      onPressed: viewModel.isLoading ? null : _goBackToLogin,
      child: const Text('¿Ya tienes cuenta? Inicia sesión'),
    );
  }

  Widget _buildForm(RegisterViewModel viewModel) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildEmailField(),
          const SizedBox(height: 16),
          _buildPasswordField(),
          const SizedBox(height: 16),
          _buildConfirmPasswordField(),
          const SizedBox(height: 24),
          _buildRegisterButton(viewModel),
          const SizedBox(height: 16),
          _buildLoginLink(viewModel),
        ],
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RegisterViewModel(),
      child: Consumer<RegisterViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            appBar: AppBar(title: const Text('Registro')),
            body: LoadingOverlay(
              isLoading: viewModel.isLoading,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildForm(viewModel),
              ),
            ),
          );
        },
      ),
    );
  }
}
