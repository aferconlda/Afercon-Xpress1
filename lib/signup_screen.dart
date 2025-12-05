
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../auth_service.dart';

// Enums para tipos de utilizador e veículo
enum UserType { client, driver }
enum VehicleType { car, motorcycle }

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // Controladores e chaves
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _nationalityController = TextEditingController();
  final _vehicleMakeController = TextEditingController();
  final _vehicleModelController = TextEditingController();
  final _vehicleYearController = TextEditingController();
  final _vehiclePlateController = TextEditingController();
  final _vehicleColorController = TextEditingController();
  final _driverLicenseController = TextEditingController();

  // Estado
  DateTime? _selectedDateOfBirth;
  UserType _userType = UserType.client;
  VehicleType _vehicleType = VehicleType.car;
  bool _isLoading = false;
  bool _agreedToTerms = false;
  bool _agreedToPrivacyPolicy = false;

  @override
  void dispose() {
    // Dispose de todos os controladores para libertar recursos
    _fullNameController.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _dateOfBirthController.dispose();
    _nationalityController.dispose();
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
      initialDate: _selectedDateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1920),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)), // Garantir que tem mais de 18 anos
      helpText: 'Selecione a sua data de nascimento',
    );
    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
        _dateOfBirthController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreedToTerms || !_agreedToPrivacyPolicy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('É obrigatório aceitar os Termos e a Política de Privacidade.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final authService = context.read<AuthService>();
    final result = await authService.signUp(
      fullName: _fullNameController.text.trim(),
      phoneNumber: _phoneNumberController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      dateOfBirth: _selectedDateOfBirth,
      nationality: _nationalityController.text.trim(),
      // Dados do veículo apenas se for motorista
      vehicleType: _userType == UserType.driver ? _vehicleType.name : null,
      vehicleMake: _userType == UserType.driver ? _vehicleMakeController.text.trim() : null,
      vehicleModel: _userType == UserType.driver ? _vehicleModelController.text.trim() : null,
      vehicleYear: _userType == UserType.driver ? int.tryParse(_vehicleYearController.text.trim()) : null,
      vehiclePlate: _userType == UserType.driver ? _vehiclePlateController.text.trim() : null,
      vehicleColor: _userType == UserType.driver ? _vehicleColorController.text.trim() : null,
      driverLicenseNumber: _userType == UserType.driver ? _driverLicenseController.text.trim() : null,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result != "Success") {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(result ?? 'Ocorreu um erro desconhecido.')),
      );
    } 
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.asset('assets/afercon-xpress.png', height: 80),
                const SizedBox(height: 24),
                Text(
                  'Criar a sua Conta',
                  style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Preencha os seus dados para começar.',
                  style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                _buildUserTypeSelector(theme),
                const SizedBox(height: 24),
                _buildPersonalInfoCard(),
                if (_userType == UserType.driver) ...[
                    const SizedBox(height: 24),
                    _buildVehicleInfoCard(),
                ],
                const SizedBox(height: 24),
                _buildTermsAndPolicy(theme),
                const SizedBox(height: 24),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _signUp,
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: const Text('Criar Conta'),
                      ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Já tem uma conta?'),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Faça o login'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGETS DE CONSTRUÇÃO ---

  Widget _buildUserTypeSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Selecione o tipo de conta', style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        SegmentedButton<UserType>(
          segments: const [
            ButtonSegment<UserType>(value: UserType.client, label: Text('Cliente'), icon: Icon(Icons.person_outline)),
            ButtonSegment<UserType>(value: UserType.driver, label: Text('Motorista'), icon: Icon(Icons.drive_eta_outlined)),
          ],
          selected: {_userType},
          onSelectionChanged: (newSelection) => setState(() => _userType = newSelection.first),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Informações Pessoais', style: Theme.of(context).textTheme.titleLarge),
            const Divider(height: 24),
            _buildTextFormField(controller: _fullNameController, label: 'Nome Completo', icon: Icons.person_outline, validator: (v) => v!.isEmpty ? 'Insira o seu nome' : null),
            const SizedBox(height: 16),
            _buildTextFormField(controller: _emailController, label: 'E-mail', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress, validator: (v) => v!.isEmpty || !v.contains('@') ? 'Insira um e-mail válido' : null),
            const SizedBox(height: 16),
            _buildTextFormField(controller: _passwordController, label: 'Palavra-passe', icon: Icons.lock_outline, obscureText: true, validator: (v) => v!.length < 6 ? 'Mínimo de 6 caracteres' : null),
            const SizedBox(height: 16),
            _buildTextFormField(controller: _phoneNumberController, label: 'Número de Telemóvel', icon: Icons.phone_outlined, keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? 'Insira o seu número' : null),
            const SizedBox(height: 16),
            _buildTextFormField(controller: _nationalityController, label: 'Nacionalidade', icon: Icons.flag_outlined, validator: (v) => v!.isEmpty ? 'Insira a sua nacionalidade' : null),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dateOfBirthController,
              decoration: _buildInputDecoration('Data de Nascimento', Icons.calendar_today_outlined),
              readOnly: true,
              onTap: () => _selectDate(context),
              validator: (v) => v!.isEmpty ? 'Selecione a data de nascimento' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Informações do Veículo', style: Theme.of(context).textTheme.titleLarge),
            const Divider(height: 24),
            SegmentedButton<VehicleType>(
              segments: const [
                ButtonSegment<VehicleType>(value: VehicleType.car, label: Text('Carro'), icon: Icon(Icons.directions_car_filled)),
                ButtonSegment<VehicleType>(value: VehicleType.motorcycle, label: Text('Moto'), icon: Icon(Icons.two_wheeler)),
              ],
              selected: {_vehicleType},
              onSelectionChanged: (newSelection) => setState(() => _vehicleType = newSelection.first),
            ),
            const SizedBox(height: 24),
            _buildTextFormField(controller: _vehicleMakeController, label: 'Marca do Veículo', icon: Icons.branding_watermark_outlined, validator: (v) => _userType == UserType.driver && v!.isEmpty ? 'Campo obrigatório' : null),
            const SizedBox(height: 16),
            _buildTextFormField(controller: _vehicleModelController, label: 'Modelo do Veículo', icon: Icons.directions_car_outlined, validator: (v) => _userType == UserType.driver && v!.isEmpty ? 'Campo obrigatório' : null),
            const SizedBox(height: 16),
            _buildTextFormField(controller: _vehicleYearController, label: 'Ano do Veículo', icon: Icons.calendar_today_outlined, keyboardType: TextInputType.number, validator: (v) => _userType == UserType.driver && v!.isEmpty ? 'Campo obrigatório' : null),
            const SizedBox(height: 16),
            _buildTextFormField(controller: _vehiclePlateController, label: 'Matrícula', icon: Icons.numbers_outlined, validator: (v) => _userType == UserType.driver && v!.isEmpty ? 'Campo obrigatório' : null),
            const SizedBox(height: 16),
            _buildTextFormField(controller: _vehicleColorController, label: 'Cor do Veículo', icon: Icons.color_lens_outlined, validator: (v) => _userType == UserType.driver && v!.isEmpty ? 'Campo obrigatório' : null),
             const SizedBox(height: 16),
            _buildTextFormField(controller: _driverLicenseController, label: 'Nº da Carta de Condução', icon: Icons.badge_outlined, validator: (v) => _userType == UserType.driver && v!.isEmpty ? 'Campo obrigatório' : null),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: _buildInputDecoration(label, icon),
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
      filled: true,
      fillColor: Colors.grey.withAlpha((255 * 0.1).round()),
    );
  }

 Widget _buildTermsAndPolicy(ThemeData theme) {
    return Column(
      children: [
        CheckboxListTile(
          value: _agreedToTerms,
          onChanged: (value) => setState(() => _agreedToTerms = value!),
          title: RichText(
            text: TextSpan(
              text: 'Eu li e aceito os ',
              style: theme.textTheme.bodyMedium,
              children: [
                TextSpan(
                  text: 'Termos e Condições',
                  style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                  recognizer: TapGestureRecognizer()..onTap = () => context.push('/terms'),
                ),
              ],
            ),
          ),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
        CheckboxListTile(
          value: _agreedToPrivacyPolicy,
          onChanged: (value) => setState(() => _agreedToPrivacyPolicy = value!),
          title: RichText(
            text: TextSpan(
              text: 'Eu li e aceito a ',
              style: theme.textTheme.bodyMedium,
              children: [
                TextSpan(
                  text: 'Política de Privacidade',
                  style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                  recognizer: TapGestureRecognizer()..onTap = () => context.push('/privacy'),
                ),
              ],
            ),
          ),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
         FormField<bool>(
            builder: (state) {
                return state.hasError ? 
                Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(state.errorText!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
                ) : Container();
            },
            validator: (value) {
            if (!_agreedToTerms || !_agreedToPrivacyPolicy) {
                return 'É obrigatório aceitar os termos e a política de privacidade.';
            }
            return null;
            },
        ),
      ],
    );
  }
}
