
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'auth_service.dart';
import 'models/delivery_model.dart';
import 'models/user_model.dart';
import 'utils/currency_formatter.dart';

class DeliveryDetailsScreen extends StatefulWidget {
  final String deliveryId;

  const DeliveryDetailsScreen({super.key, required this.deliveryId});

  @override
  State<DeliveryDetailsScreen> createState() => _DeliveryDetailsScreenState();
}

class _DeliveryDetailsScreenState extends State<DeliveryDetailsScreen> {
  // Adiciona um Future para poder ser recarregado
  late Future<Delivery?> _deliveryFuture;

  @override
  void initState() {
    super.initState();
    // Inicializa o future no initState
    _deliveryFuture = context.read<AuthService>().getDeliveryDetails(widget.deliveryId);
  }

  // Função para recarregar os dados
  void _reloadData() {
    setState(() {
      _deliveryFuture = context.read<AuthService>().getDeliveryDetails(widget.deliveryId);
    });
  }

  Future<void> _launchUri(Uri uri) async {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível executar a ação para: $uri')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da Entrega'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: FutureBuilder<Delivery?>(
        future: _deliveryFuture, // Usa o future do estado
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Erro ao carregar os detalhes da entrega.'));
          }

          final delivery = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, delivery),
                const SizedBox(height: 24),
                 // Adiciona os botões de ação aqui
                _buildActionButtons(context, delivery),
                const SizedBox(height: 24),
                _buildSectionTitle(context, 'Percurso', Icons.map),
                _buildRouteInfo(delivery),
                const Divider(height: 32),
                _buildSectionTitle(context, 'Destinatário', Icons.person_pin),
                _buildRecipientInfo(delivery),
                const Divider(height: 32),
                _buildSectionTitle(context, 'Financeiro', Icons.attach_money),
                _buildPricingInfo(context, delivery),
                const SizedBox(height: 24),
                if (delivery.driverId != null)
                  FutureBuilder<AppUser?>(
                    future: context.read<AuthService>().getUserDetails(delivery.driverId!),
                    builder: (context, driverSnapshot) {
                      if (driverSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (driverSnapshot.hasData && driverSnapshot.data != null) {
                        // Passa o status da entrega para o _buildDriverInfo
                        return _buildDriverInfo(context, driverSnapshot.data!, delivery.status);
                      }
                      return const SizedBox.shrink();
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

   Widget _buildActionButtons(BuildContext context, Delivery delivery) {
    final authService = context.read<AuthService>();
    final currentUser = authService.currentUser;
    final scaffoldMessenger = ScaffoldMessenger.of(context); // Guardar o ScaffoldMessenger

    if (currentUser == null) return const SizedBox.shrink();

    // Lógica para o Motorista
    if (currentUser.uid == delivery.driverId && delivery.status == DeliveryStatus.inProgress) {
      return Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.check_circle, color: Colors.white),
          label: const Text('Marcar como Entregue'),
          onPressed: () async {
            final result = await authService.updateDeliveryStatus(delivery.id, DeliveryStatus.pendingConfirmation);
            if (result == "Success") {
              _reloadData(); // Recarrega os dados
            } else {
              scaffoldMessenger.showSnackBar(SnackBar(content: Text(result ?? 'Erro desconhecido')));
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
        ),
      );
    }

    // Lógica para o Cliente
    if (currentUser.uid == delivery.userId && delivery.status == DeliveryStatus.pendingConfirmation) {
      return Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.thumb_up, color: Colors.white),
          label: const Text('Confirmar Recebimento'),
          onPressed: () async {
             final result = await authService.updateDeliveryStatus(delivery.id, DeliveryStatus.completed);
            if (result == "Success") {
              _reloadData(); // Recarrega os dados
            } else {
              scaffoldMessenger.showSnackBar(SnackBar(content: Text(result ?? 'Erro desconhecido')));
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildHeader(BuildContext context, Delivery delivery) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          delivery.title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(delivery.description, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 16),
        Chip(
          label: Text(_getStatusText(delivery.status)),
          backgroundColor: _getStatusColor(delivery.status),
          labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildRouteInfo(Delivery delivery) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.location_on, color: Colors.blue),
          title: const Text('Recolha'),
          subtitle: Text(delivery.pickupAddress),
        ),
        ListTile(
          leading: const Icon(Icons.pin_drop, color: Colors.red),
          title: const Text('Entrega'),
          subtitle: Text(delivery.deliveryAddress),
        ),
      ],
    );
  }

  Widget _buildRecipientInfo(Delivery delivery) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.person),
          title: const Text('Nome'),
          subtitle: Text(delivery.recipientName),
        ),
        ListTile(
          leading: const Icon(Icons.phone),
          title: const Text('Contacto'),
          subtitle: Text(delivery.recipientPhone),
        ),
      ],
    );
  }

  Widget _buildPricingInfo(BuildContext context, Delivery delivery) {
    return ListTile(
      title: const Text('Valor da Entrega'),
      trailing: Text(
        CurrencyFormatter.format(delivery.price),
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

   Widget _buildDriverInfo(BuildContext context, AppUser driver, DeliveryStatus status) {
    final vehicleInfo = (
      driver.vehicleModel?.isNotEmpty == true ||
      driver.vehiclePlate?.isNotEmpty == true ||
      driver.vehicleColor?.isNotEmpty == true
    ) ? '${driver.vehicleModel ?? ''} - ${driver.vehicleColor ?? ''} (${driver.vehiclePlate ?? 'N/A'})' 
      : 'Veículo não informado';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        _buildSectionTitle(context, 'Motorista Responsável', Icons.delivery_dining),
        Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                 ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(driver.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(driver.phoneNumber, style: Theme.of(context).textTheme.bodyMedium),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.directions_car),
                  title: const Text('Veículo'),
                  subtitle: Text(vehicleInfo),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Mostra os botões de contacto apenas se a entrega estiver em progresso
        if(status == DeliveryStatus.inProgress || status == DeliveryStatus.pendingConfirmation)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.call),
                label: const Text('Ligar'),
                onPressed: () => _launchUri(Uri.parse('tel:${driver.phoneNumber}')),
                 style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.message),
                label: const Text('WhatsApp'),
                onPressed: () => _launchUri(Uri.parse('https://wa.me/${driver.phoneNumber}')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
      ],
    );
  }

  // Atualizado para incluir o novo estado
  String _getStatusText(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.available:
        return 'Disponível';
      case DeliveryStatus.inProgress:
        return 'Em Progresso';
      case DeliveryStatus.pendingConfirmation:
        return 'A Aguardar Confirmação';
      case DeliveryStatus.completed:
        return 'Concluída';
    }
  }

  // Atualizado para incluir o novo estado
  Color _getStatusColor(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.available:
        return Colors.blue;
      case DeliveryStatus.inProgress:
        return Colors.orange;
       case DeliveryStatus.pendingConfirmation:
        return Colors.deepPurple;
      case DeliveryStatus.completed:
        return Colors.green;
    }
  }
}
