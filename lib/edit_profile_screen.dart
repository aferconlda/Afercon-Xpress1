
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'auth_service.dart';
import 'models/user_model.dart';
import 'widgets/driver_form.dart'; // Import the reusable form

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Basic Info Controllers
  late TextEditingController _fullNameController;
  late TextEditingController _phoneNumberController;

  // Driver Specific Controllers
  late TextEditingController _vehicleTypeController;
  late TextEditingController _vehicleMakeController;
  late TextEditingController _vehicleModelController;
  late TextEditingController _vehicleYearController;
  late TextEditingController _vehiclePlateController;
  late TextEditingController _vehicleColorController;
  late TextEditingController _driverLicenseController;

  AppUser? _currentUserData;

  @override
  void initState() {
    super.initState();
    // Initialize all controllers
    _fullNameController = TextEditingController();
    _phoneNumberController = TextEditingController();
    _vehicleTypeController = TextEditingController();
    _vehicleMakeController = TextEditingController();
    _vehicleModelController = TextEditingController();
    _vehicleYearController = TextEditingController();
    _vehiclePlateController = TextEditingController();
    _vehicleColorController = TextEditingController();
    _driverLicenseController = TextEditingController();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = context.read<AuthService>().currentUser;
    if (user != null) {
      final userData = await context.read<AuthService>().getUserDetails(user.uid);
      if (userData != null) {
        setState(() {
          _currentUserData = userData;
          // Pre-fill basic info
          _fullNameController.text = userData.fullName;
          _phoneNumberController.text = userData.phoneNumber;

          // Pre-fill driver info if it exists
          _vehicleTypeController.text = userData.vehicleType ?? '';
          _vehicleMakeController.text = userData.vehicleMake ?? '';
          _vehicleModelController.text = userData.vehicleModel ?? '';
          _vehicleYearController.text = userData.vehicleYear?.toString() ?? '';
          _vehiclePlateController.text = userData.vehiclePlate ?? '';
          _vehicleColorController.text = userData.vehicleColor ?? '';
          _driverLicenseController.text = userData.driverLicenseNumber ?? '';
        });
      }
    }
  }

  @override
  void dispose() {
    // Dispose all controllers
    _fullNameController.dispose();
    _phoneNumberController.dispose();
    _vehicleTypeController.dispose();
    _vehicleMakeController.dispose();
    _vehicleModelController.dispose();
    _vehicleYearController.dispose();
    _vehiclePlateController.dispose();
    _vehicleColorController.dispose();
    _driverLicenseController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final updatedData = {
      'fullName': _fullNameController.text.trim(),
      'phoneNumber': _phoneNumberController.text.trim(),
      // Update all driver fields, sending null if empty to clear them
      'vehicleType': _vehicleTypeController.text.trim().isNotEmpty ? _vehicleTypeController.text.trim() : null,
      'vehicleMake': _vehicleMakeController.text.trim().isNotEmpty ? _vehicleMakeController.text.trim() : null,
      'vehicleModel': _vehicleModelController.text.trim().isNotEmpty ? _vehicleModelController.text.trim() : null,
      'vehicleYear': int.tryParse(_vehicleYearController.text.trim()),
      'vehiclePlate': _vehiclePlateController.text.trim().isNotEmpty ? _vehiclePlateController.text.trim() : null,
      'vehicleColor': _vehicleColorController.text.trim().isNotEmpty ? _vehicleColorController.text.trim() : null,
      'driverLicenseNumber': _driverLicenseController.text.trim().isNotEmpty ? _driverLicenseController.text.trim() : null,
    };

    final userId = context.read<AuthService>().currentUser!.uid;
    await FirebaseFirestore.instance.collection('users').doc(userId).update(updatedData);

    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perfil atualizado com sucesso!'), backgroundColor: Colors.green),
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
                  
                  // --- Reusable Driver Form ---
                  DriverForm(
                    vehicleTypeController: _vehicleTypeController,
                    vehicleMakeController: _vehicleMakeController,
                    vehicleModelController: _vehicleModelController,
                    vehicleYearController: _vehicleYearController,
                    vehiclePlateController: _vehiclePlateController,
                    vehicleColorController: _vehicleColorController,
                    driverLicenseController: _driverLicenseController,
                  ),
                  // --- End of Reusable Form ---
                  
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
