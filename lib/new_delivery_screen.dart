
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'models/delivery_model.dart';
import 'utils/currency_formatter.dart';

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
  final _basePriceController = TextEditingController();

  final ValueNotifier<double> _basePriceNotifier = ValueNotifier<double>(0.0);
  bool _isLoading = false;
  static const double _serviceFeePercentage = 0.005; // 0.5%
  static const double _minimumDeliveryPrice = 1000.0; // Valor mínimo da entrega

  @override
  void initState() {
    super.initState();
    _basePriceController.addListener(() {
      _basePriceNotifier.value = double.tryParse(_basePriceController.text) ?? 0.0;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pickupAddressController.dispose();
    _deliveryAddressController.dispose();
    _recipientNameController.dispose();
    _recipientPhoneController.dispose();
    _basePriceController.dispose();
    _basePriceNotifier.dispose();
    super.dispose();
  }

  Future<void> _showConfirmationDialog(User user) async {
    if (!_formKey.currentState!.validate()) return;

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // O utilizador deve tomar uma decisão
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmação de Publicação'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Ao publicar esta entrega, concorda em partilhar os detalhes do pedido com os motoristas e outros utilizadores da plataforma Afercon Xpress.'),
                SizedBox(height: 10),
                Text('Isto inclui informações como o título, descrição, endereços de recolha/entrega e o nome do destinatário.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Confirmar e Publicar'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _submitDelivery(user);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitDelivery(User user) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final double basePrice = _basePriceNotifier.value;
      if (basePrice < _minimumDeliveryPrice) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('O valor mínimo para uma entrega é de ${CurrencyFormatter.format(_minimumDeliveryPrice)}.')),
        );
        setState(() => _isLoading = false);
        return;
      }

      final double serviceFee = basePrice * _serviceFeePercentage;
      final double totalPrice = basePrice + serviceFee;

      final delivery = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'pickupAddress': _pickupAddressController.text,
        'deliveryAddress': _deliveryAddressController.text,
        'recipientName': _recipientNameController.text,
        'recipientPhone': _recipientPhoneController.text,
        'basePrice': basePrice,
        'serviceFee': serviceFee,
        'totalPrice': totalPrice,
        'status': DeliveryStatus.available.name,
        'userId': user.uid,
        'driverId': null,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('deliveries').add(delivery);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entrega publicada com sucesso!')),
        );
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
        title: const Text('Publicar Nova Entrega', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text('Precisa de estar autenticado para publicar uma entrega.'),
            );
          }
          final user = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Título da Entrega', prefixIcon: Icon(Icons.label_important_outline), border: OutlineInputBorder(), helperText: 'Ex: Entrega de Documentos Urgentes'),
                    validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Descrição Detalhada', prefixIcon: Icon(Icons.description_outlined), border: OutlineInputBorder(), helperText: 'Detalhes sobre o pacote, cuidados a ter, etc.'),
                    maxLines: 3,
                    validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                  ),
                  const SizedBox(height: 24),
                  Text('Informações de Rota', style: Theme.of(context).textTheme.titleLarge),
                  const Divider(),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _pickupAddressController,
                    decoration: const InputDecoration(labelText: 'Endereço de Recolha', prefixIcon: Icon(Icons.location_on_outlined, color: Colors.blue), border: OutlineInputBorder()),
                    validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _deliveryAddressController,
                    decoration: const InputDecoration(labelText: 'Endereço de Entrega', prefixIcon: Icon(Icons.pin_drop_outlined, color: Colors.red), border: OutlineInputBorder()),
                    validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                  ),
                  const SizedBox(height: 24),
                  Text('Informações do Destinatário', style: Theme.of(context).textTheme.titleLarge),
                  const Divider(),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _recipientNameController,
                    decoration: const InputDecoration(labelText: 'Nome do Destinatário', prefixIcon: Icon(Icons.person_outline), border: OutlineInputBorder()),
                    validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _recipientPhoneController,
                    decoration: const InputDecoration(labelText: 'Contacto do Destinatário', prefixIcon: Icon(Icons.phone_outlined), border: OutlineInputBorder()),
                    keyboardType: TextInputType.phone,
                    validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                  ),
                  const SizedBox(height: 24),
                  Text('Valor a Pagar', style: Theme.of(context).textTheme.titleLarge),
                  const Divider(),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _basePriceController,
                    decoration: const InputDecoration(
                      labelText: 'Valor para o Motorista',
                      prefixIcon: Icon(Icons.wallet_giftcard_outlined),
                      suffixText: 'AOA',
                      border: OutlineInputBorder(),
                      helperText: 'O valor que o motorista irá receber.',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Campo obrigatório';
                      }
                      final price = double.tryParse(value);
                      if (price == null) {
                        return 'Valor inválido';
                      }
                      if (price < _minimumDeliveryPrice) {
                        return 'O valor mínimo para uma entrega é de ${CurrencyFormatter.format(_minimumDeliveryPrice)}.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  ValueListenableBuilder<double>(
                    valueListenable: _basePriceNotifier,
                    builder: (context, basePrice, child) {
                      if (basePrice <= 0) return const SizedBox.shrink();
                      final serviceFee = basePrice * _serviceFeePercentage;
                      final totalPrice = basePrice + serviceFee;
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondaryContainer.withAlpha(80),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            _buildPriceRow('Taxa de Serviço (0.5%)', serviceFee, context, isFee: true),
                            const Divider(height: 20, thickness: 0.5),
                            _buildPriceRow('Valor Total (a pagar por si)', totalPrice, context, isTotal: true),
                            const SizedBox(height: 12),
                            Text(
                              'A taxa de serviço ajuda a manter a plataforma funcional e segura para todos.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSecondaryContainer),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton.icon(
                          icon: const Icon(Icons.publish, color: Colors.white),
                          label: const Text('Publicar Entrega', style: TextStyle(color: Colors.white)),
                          onPressed: () => _showConfirmationDialog(user),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPriceRow(String label, double value, BuildContext context, {bool isFee = false, bool isTotal = false}) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: isTotal ? theme.textTheme.titleMedium : theme.textTheme.bodyMedium),
        Text(
          CurrencyFormatter.format(value),
          style: (isTotal ? theme.textTheme.titleLarge : theme.textTheme.titleMedium)?.copyWith(
            fontWeight: FontWeight.bold,
            color: isTotal ? theme.colorScheme.primary : theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
