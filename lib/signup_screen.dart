
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../auth_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _vehicleModelController = TextEditingController();
  final _vehiclePlateController = TextEditingController();
  final _vehicleColorController = TextEditingController();

  bool _isLoading = false;
  bool _agreedToTerms = false;
  bool _agreedToPrivacyPolicy = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _vehicleModelController.dispose();
    _vehiclePlateController.dispose();
    _vehicleColorController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) {
      // Mostra um snackbar se os termos não forem aceites
      if (!_agreedToTerms || !_agreedToPrivacyPolicy) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Precisa de aceitar os Termos e a Política de Privacidade.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    final authService = context.read<AuthService>();
    final result = await authService.signUp(
      fullName: _fullNameController.text.trim(),
      phoneNumber: _phoneNumberController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      vehicleModel: _vehicleModelController.text.trim(),
      vehiclePlate: _vehiclePlateController.text.trim(),
      vehicleColor: _vehicleColorController.text.trim(),
    );

    if (!mounted) return; // Verificar se o widget ainda está montado

    setState(() => _isLoading = false);

    if (result != "Success") {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result ?? 'Ocorreu um erro desconhecido.')),
      );
    } else {
      // O go_router irá redirecionar automaticamente.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar Conta')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- Campos de Informação Pessoal ---
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(labelText: 'Nome Completo', border: OutlineInputBorder()),
                  validator: (value) => value!.isEmpty ? 'Insira o seu nome completo' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneNumberController,
                  decoration: const InputDecoration(labelText: 'Número de Telemóvel', border: OutlineInputBorder()),
                  keyboardType: TextInputType.phone,
                  validator: (value) => value!.isEmpty ? 'Insira o seu número de telemóvel' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'E-mail', border: OutlineInputBorder()),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => value!.isEmpty || !value.contains('@') ? 'Insira um e-mail válido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Palavra-passe', border: OutlineInputBorder()),
                  obscureText: true,
                  validator: (value) =>
                      value!.length < 6 ? 'A palavra-passe deve ter no mínimo 6 caracteres' : null,
                ),
                const SizedBox(height: 24),
                // --- Campos de Informação do Veículo (Opcional) ---
                Text('Informação do Veículo (para Motoristas)', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _vehicleModelController,
                  decoration: const InputDecoration(labelText: 'Modelo do Veículo (ex: Toyota Yaris)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _vehiclePlateController,
                  decoration: const InputDecoration(labelText: 'Matrícula (ex: AA-00-BB)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _vehicleColorController,
                  decoration: const InputDecoration(labelText: 'Cor do Veículo (ex: Azul)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 24),

                // --- Checkboxes de Consentimento ---
                CheckboxListTile(
                  value: _agreedToTerms,
                  onChanged: (value) => setState(() => _agreedToTerms = value!),
                  title: RichText(
                    text: TextSpan(
                      text: 'Eu li e aceito os ',
                      style: Theme.of(context).textTheme.bodyMedium,
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
                      style: Theme.of(context).textTheme.bodyMedium,
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
                 // Validador para garantir que as checkboxes estão marcadas
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
                const SizedBox(height: 24),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _signUp,
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: const Text('Criar Conta'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
