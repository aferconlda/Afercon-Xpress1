
import 'package:flutter/material.dart';

// Um widget reutilizável que contém todos os campos do formulário para um motorista.
class DriverForm extends StatelessWidget {
  final TextEditingController vehicleTypeController;
  final TextEditingController vehicleMakeController;
  final TextEditingController vehicleModelController;
  final TextEditingController vehicleYearController;
  final TextEditingController vehiclePlateController;
  final TextEditingController vehicleColorController;
  final TextEditingController driverLicenseController;

  const DriverForm({
    super.key,
    required this.vehicleTypeController,
    required this.vehicleMakeController,
    required this.vehicleModelController,
    required this.vehicleYearController,
    required this.vehiclePlateController,
    required this.vehicleColorController,
    required this.driverLicenseController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        Text(
          'Dados do Veículo e Motorista',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        _buildTextFormField(controller: vehicleTypeController, label: 'Tipo de Veículo (ex: Carro, Mota)', icon: Icons.two_wheeler),
        const SizedBox(height: 16),
        _buildTextFormField(controller: vehicleMakeController, label: 'Marca do Veículo', icon: Icons.directions_car),
        const SizedBox(height: 16),
        _buildTextFormField(controller: vehicleModelController, label: 'Modelo do Veículo', icon: Icons.time_to_leave),
        const SizedBox(height: 16),
        _buildTextFormField(controller: vehicleYearController, label: 'Ano do Veículo', icon: Icons.event, keyboardType: TextInputType.number),
        const SizedBox(height: 16),
        _buildTextFormField(controller: vehiclePlateController, label: 'Matrícula', icon: Icons.pin),
        const SizedBox(height: 16),
        _buildTextFormField(controller: vehicleColorController, label: 'Cor do Veículo', icon: Icons.color_lens_outlined),
        const SizedBox(height: 16),
        _buildTextFormField(controller: driverLicenseController, label: 'Nº da Carta de Condução', icon: Icons.badge_outlined),
      ],
    );
  }

  // Método auxiliar para criar os campos de texto, mantendo a consistência.
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      keyboardType: keyboardType,
      validator: (value) => (value?.isEmpty ?? true) ? 'Este campo não pode estar vazio' : null,
    );
  }
}
