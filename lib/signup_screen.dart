
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:provider/provider.dart';

import 'auth_service.dart';
import 'widgets/driver_form.dart'; // Import the new reusable widget

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  // Basic Info Controllers
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _dobController = TextEditingController();
  final _nationalityController = TextEditingController();

  // Driver Specific Controllers
  final _vehicleTypeController = TextEditingController();
  final _vehicleMakeController = TextEditingController();
  final _vehicleModelController = TextEditingController();
  final _vehicleYearController = TextEditingController();
  final _vehiclePlateController = TextEditingController();
  final _vehicleColorController = TextEditingController();
  final _driverLicenseController = TextEditingController();

  DateTime? _selectedDate;
  bool _isDriver = false;
  bool _isLoading = false;
  bool _isPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;
  bool _termsAccepted = false;

  @override
  void dispose() {
    // Dispose all controllers
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _dobController.dispose();
    _nationalityController.dispose();
    _vehicleTypeController.dispose();
    _vehicleMakeController.dispose();
    _vehicleModelController.dispose();
    _vehicleYearController.dispose();
    _vehiclePlateController.dispose();
    _vehicleColorController.dispose();
    _driverLicenseController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _signUp() async {
    FocusScope.of(context).unfocus();
    final isFormValid = _formKey.currentState!.validate();

    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Por favor, aceite os Termos e a Política de Privacidade.'),
            backgroundColor: Colors.orange),
      );
      if (!isFormValid) _formKey.currentState!.validate();
      return;
    }

    if (!isFormValid) return;

    setState(() => _isLoading = true);

    final authService = context.read<AuthService>();
    final result = await authService.signUp(
      // ... (pass user data as before)
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      password: _passwordController.text.trim(),
      dateOfBirth: _selectedDate,
      nationality: _nationalityController.text.trim(),
       // Pass driver info only if _isDriver is true
      vehicleType: _isDriver ? _vehicleTypeController.text.trim() : null,
      vehicleMake: _isDriver ? _vehicleMakeController.text.trim() : null,
      vehicleModel: _isDriver ? _vehicleModelController.text.trim() : null,
      vehicleYear: _isDriver && _vehicleYearController.text.isNotEmpty ? int.tryParse(_vehicleYearController.text.trim()) : null,
      vehiclePlate: _isDriver ? _vehiclePlateController.text.trim() : null,
      vehicleColor: _isDriver ? _vehicleColorController.text.trim() : null,
      driverLicenseNumber: _isDriver ? _driverLicenseController.text.trim() : null,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result == 'Success') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Conta criada com sucesso! Verifique seu e-mail.'),
            backgroundColor: Colors.green),
      );
      context.go('/login');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result ?? 'Erro no registro.'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
         title: const Text('Criar Conta', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green, Colors.blue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Insira os seus dados', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              _buildTextFormField(controller: _fullNameController, label: 'Nome Completo', icon: Icons.person_outline),
              const SizedBox(height: 16),
              _buildTextFormField(controller: _emailController, label: 'Email', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              _buildTextFormField(controller: _phoneController, label: 'Nº de Telemóvel', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dobController,
                decoration: const InputDecoration(labelText: 'Data de Nascimento', prefixIcon: Icon(Icons.calendar_today_outlined), border: OutlineInputBorder()),
                readOnly: true,
                onTap: () => _selectDate(context),
                validator: (value) => value!.isEmpty ? 'Selecione a data de nascimento' : null,
              ),
              const SizedBox(height: 16),
              _buildTextFormField(controller: _nationalityController, label: 'Nacionalidade', icon: Icons.flag_outlined),
              const SizedBox(height: 16),
              _buildPasswordFormField(controller: _passwordController, label: 'Password'),
              const SizedBox(height: 16),
              _buildConfirmPasswordFormField(),
              const SizedBox(height: 24),
              SwitchListTile(
                title: const Text('Registar como motorista?'),
                value: _isDriver,
                onChanged: (bool value) => setState(() => _isDriver = value),
                secondary: Icon(_isDriver ? Icons.local_shipping : Icons.person),
              ),
              if (_isDriver)
                DriverForm(
                  vehicleTypeController: _vehicleTypeController,
                  vehicleMakeController: _vehicleMakeController,
                  vehicleModelController: _vehicleModelController,
                  vehicleYearController: _vehicleYearController,
                  vehiclePlateController: _vehiclePlateController,
                  vehicleColorController: _vehicleColorController,
                  driverLicenseController: _driverLicenseController,
                ),
              const SizedBox(height: 24),
              _buildTermsAndConditions(),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
                      label: const Text('Criar Conta'),
                      onPressed: _signUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _termsAccepted ? Colors.blue : Colors.grey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
              const SizedBox(height: 24),
              Divider(color: Colors.grey[300]),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Já tem uma conta?'),
                  TextButton(onPressed: () => context.go('/login'), child: const Text('Faça Login')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({required TextEditingController controller, required String label, required IconData icon, TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), border: const OutlineInputBorder()),
      keyboardType: keyboardType,
      validator: (value) => (value?.isEmpty ?? true) ? 'Este campo não pode estar vazio' : null,
    );
  }

  Widget _buildPasswordFormField({required TextEditingController controller, required String label}) {
    return TextFormField(
      controller: controller,
      obscureText: _isPasswordObscured,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(icon: Icon(_isPasswordObscured ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _isPasswordObscured = !_isPasswordObscured)),
      ),
      validator: (value) => (value?.length ?? 0) < 6 ? 'A senha deve ter no mínimo 6 caracteres' : null,
    );
  }

  Widget _buildConfirmPasswordFormField() {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: _isConfirmPasswordObscured,
      decoration: InputDecoration(
        labelText: 'Confirmar Password',
        prefixIcon: const Icon(Icons.lock_outline),
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(icon: Icon(_isConfirmPasswordObscured ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _isConfirmPasswordObscured = !_isConfirmPasswordObscured)),
      ),
      validator: (value) {
        if (value!.isEmpty) return 'Confirme sua senha';
        if (value != _passwordController.text) return 'As senhas não correspondem';
        return null;
      },
    );
  }

  Widget _buildTermsAndConditions() {
    return Row(
      children: [
        Checkbox(value: _termsAccepted, onChanged: (value) => setState(() => _termsAccepted = value ?? false)),
        Expanded(
          child: RichText(
            text: TextSpan(
              text: 'Eu li e aceito os ',
              style: Theme.of(context).textTheme.bodySmall,
              children: [
                TextSpan(
                  text: 'Termos e Condições',
                  style: TextStyle(color: Theme.of(context).colorScheme.primary, decoration: TextDecoration.underline),
                  recognizer: TapGestureRecognizer()..onTap = () => context.push('/terms'),
                ),
                const TextSpan(text: ' e a '),
                TextSpan(
                  text: 'Política de Privacidade',
                  style: TextStyle(color: Theme.of(context).colorScheme.primary, decoration: TextDecoration.underline),
                  recognizer: TapGestureRecognizer()..onTap = () => context.push('/privacy-policy'),
                ),
                const TextSpan(text: '.'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
