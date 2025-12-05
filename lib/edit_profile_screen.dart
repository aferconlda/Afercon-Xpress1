
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'auth_service.dart';
import 'models/user_model.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers para os campos do formulário
  late TextEditingController _fullNameController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _vehicleModelController;
  late TextEditingController _vehiclePlateController;
  late TextEditingController _vehicleColorController;

  AppUser? _currentUserData;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _phoneNumberController = TextEditingController();
    _vehicleModelController = TextEditingController();
    _vehiclePlateController = TextEditingController();
    _vehicleColorController = TextEditingController();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = context.read<AuthService>().currentUser;
    if (user != null) {
      final userData = await context.read<AuthService>().getUserDetails(user.uid);
      if (userData != null) {
        setState(() {
          _currentUserData = userData;
          _fullNameController.text = userData.fullName;
          _phoneNumberController.text = userData.phoneNumber;
          // Preenche os campos do veículo se existirem, caso contrário ficam vazios
          _vehicleModelController.text = userData.vehicleModel ?? '';
          _vehiclePlateController.text = userData.vehiclePlate ?? '';
          _vehicleColorController.text = userData.vehicleColor ?? '';
        });
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneNumberController.dispose();
    _vehicleModelController.dispose();
    _vehiclePlateController.dispose();
    _vehicleColorController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // CORRECÇÃO: Guarda os dados do veículo incondicionalmente.
    // Se estiverem vazios, serão guardados como strings vazias.
    final updatedData = {
      'fullName': _fullNameController.text.trim(),
      'phoneNumber': _phoneNumberController.text.trim(),
      'vehicleModel': _vehicleModelController.text.trim(),
      'vehiclePlate': _vehiclePlateController.text.trim(),
      'vehicleColor': _vehicleColorController.text.trim(),
    };

    final userId = context.read<AuthService>().currentUser!.uid;
    await FirebaseFirestore.instance.collection('users').doc(userId).update(updatedData);

    if (!mounted) return;

    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Perfil atualizado com sucesso!'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Perfil')),
      body: _currentUserData == null
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24.0),
                children: [
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
                    initialValue: _currentUserData!.email,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'E-mail (não pode ser alterado)',
                      border: OutlineInputBorder(),
                      fillColor: Colors.black12,
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // CORRECÇÃO: O formulário do veículo está agora sempre visível.
                  Text('Informação do Veículo (Obrigatório para Motoristas)', style: Theme.of(context).textTheme.titleLarge),
                  const Divider(height: 24),
                  TextFormField(
                    controller: _vehicleModelController,
                    decoration: const InputDecoration(labelText: 'Marca e Modelo do Veículo', border: OutlineInputBorder()),
                    // Opcional: Adicionar validação se soubermos que o user é motorista
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _vehiclePlateController,
                    decoration: const InputDecoration(labelText: 'Matrícula', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _vehicleColorController,
                    decoration: const InputDecoration(labelText: 'Cor do Veículo', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 24),
                  
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton.icon(
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('Guardar Alterações'),
                          onPressed: _saveChanges,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                ],
              ),
            ),
    );
  }
}
