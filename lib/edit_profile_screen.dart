
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
  late TextEditingController _vehicleMakeController; // Alterado de _vehicleModelController
  late TextEditingController _vehiclePlateController;
  late TextEditingController _vehicleColorController;

  String? _selectedVehicleType; // Para guardar a seleção do dropdown
  AppUser? _currentUserData;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _phoneNumberController = TextEditingController();
    _vehicleMakeController = TextEditingController();
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
          
          // Preenche os campos do veículo, incluindo o novo tipo
          _selectedVehicleType = userData.vehicleType;
          _vehicleMakeController.text = userData.vehicleMake ?? '';
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
    _vehicleMakeController.dispose();
    _vehiclePlateController.dispose();
    _vehicleColorController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final updatedData = {
      'fullName': _fullNameController.text.trim(),
      'phoneNumber': _phoneNumberController.text.trim(),
      'vehicleType': _selectedVehicleType, // Guarda o tipo de veículo
      'vehicleMake': _vehicleMakeController.text.trim(), // Guarda a marca/modelo
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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      body: _currentUserData == null
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24.0),
                children: [
                  Text('Informação Pessoal', style: theme.textTheme.titleLarge),
                  const Divider(height: 24),
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
                  const SizedBox(height: 32),
                  
                  Text('Informação do Motorista', style: theme.textTheme.titleLarge),
                  Text('Preencha para começar a aceitar entregas.', style: theme.textTheme.bodySmall),
                  const Divider(height: 24),

                  // Dropdown para Tipo de Veículo
                  DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    value: _selectedVehicleType,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de Veículo',
                      border: OutlineInputBorder(),
                    ),
                    items: ['Moto', 'Carro'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedVehicleType = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _vehicleMakeController,
                    decoration: const InputDecoration(labelText: 'Marca e Modelo do Veículo', border: OutlineInputBorder()),
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
                  const SizedBox(height: 32),
                  
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton.icon(
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('Guardar Alterações'),
                          onPressed: _saveChanges,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                ],
              ),
            ),
    );
  }
}
