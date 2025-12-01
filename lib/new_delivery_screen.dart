
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'models/delivery_model.dart';

class NewDeliveryScreen extends StatefulWidget {
  const NewDeliveryScreen({super.key});

  @override
  State<NewDeliveryScreen> createState() => _NewDeliveryScreenState();
}

class _NewDeliveryScreenState extends State<NewDeliveryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pickupAddressController = TextEditingController();
  final _deliveryAddressController = TextEditingController();
  final _recipientNameController = TextEditingController();
  final _recipientPhoneController = TextEditingController();
  final _priceController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pickupAddressController.dispose();
    _deliveryAddressController.dispose();
    _recipientNameController.dispose();
    _recipientPhoneController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submitDelivery() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final user = context.read<User?>();
    if (user == null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro: Utilizador não autenticado.')),
      );
      return;
    }

    try {
      final delivery = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'pickupAddress': _pickupAddressController.text,
        'deliveryAddress': _deliveryAddressController.text,
        'recipientName': _recipientNameController.text,
        'recipientPhone': _recipientPhoneController.text,
        'price': double.parse(_priceController.text),
        'status': DeliveryStatus.available.name,
        'userId': user.uid,
        'driverId': null,
        'createdAt': FieldValue.serverTimestamp(), // Para ordenar
      };

      await FirebaseFirestore.instance.collection('deliveries').add(delivery);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entrega publicada com sucesso!')),
        );
        // Usa context.pop() para voltar ao ecrã anterior após sucesso.
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ocorreu um erro: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Publicar Nova Entrega'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
               const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título da Entrega',
                  prefixIcon: Icon(Icons.label_important_outline),
                  border: OutlineInputBorder(),
                  helperText: 'Ex: Entrega de Documentos Urgentes'
                ),
                validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descrição Detalhada',
                  prefixIcon: Icon(Icons.description_outlined),
                  border: OutlineInputBorder(),
                   helperText: 'Detalhes sobre o pacote, cuidados a ter, etc.'
                ),
                maxLines: 3,
                 validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 24),
              Text('Informações de Rota', style: Theme.of(context).textTheme.titleLarge),
              const Divider(),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pickupAddressController,
                decoration: const InputDecoration(
                  labelText: 'Endereço de Recolha',
                  prefixIcon: Icon(Icons.location_on_outlined, color: Colors.blue),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _deliveryAddressController,
                decoration: const InputDecoration(
                  labelText: 'Endereço de Entrega',
                  prefixIcon: Icon(Icons.pin_drop_outlined, color: Colors.red),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 24),
              Text('Informações do Destinatário', style: Theme.of(context).textTheme.titleLarge),
              const Divider(),
              const SizedBox(height: 16),
              TextFormField(
                controller: _recipientNameController,
                decoration: const InputDecoration(
                  labelText: 'Nome do Destinatário',
                   prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _recipientPhoneController,
                decoration: const InputDecoration(
                  labelText: 'Contacto do Destinatário',
                   prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 24),
               Text('Valor a Pagar', style: Theme.of(context).textTheme.titleLarge),
              const Divider(),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Valor da Entrega',
                  prefixIcon: Icon(Icons.monetization_on_outlined),
                  suffixText: 'AOA',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Campo obrigatório';
                  if (double.tryParse(value) == null) return 'Valor inválido';
                  return null;
                },
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.publish),
                      label: const Text('Publicar Entrega'),
                      onPressed: _submitDelivery,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
