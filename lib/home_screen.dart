
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'auth_service.dart';
import 'models/delivery_model.dart';
import 'utils/currency_formatter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Ordenar por data de criação para mostrar as mais recentes primeiro
  final Stream<List<Delivery>> _availableDeliveriesStream = FirebaseFirestore.instance
      .collection('deliveries')
      .where('status', isEqualTo: DeliveryStatus.available.name)
      .orderBy('createdAt', descending: true) // Mais recentes primeiro
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) =>
              Delivery.fromMap(doc.id, doc.data()))
          .toList());

  Future<void> _acceptDelivery(Delivery delivery) async {
    final driverId = context.read<User?>()?.uid;
    if (driverId == null) return;

    if (delivery.userId == driverId) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não pode aceitar a sua própria entrega.')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('deliveries')
          .doc(delivery.id)
          .update({
        'driverId': driverId,
        'status': DeliveryStatus.inProgress.name,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entrega aceite com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao aceitar a entrega: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Afercon Xpress'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'As Minhas Entregas (Cliente)',
            onPressed: () => context.push('/client-deliveries'),
          ),
          IconButton(
            icon: const Icon(Icons.delivery_dining),
            tooltip: 'As Minhas Entregas (Motorista)',
            onPressed: () => context.push('/my-deliveries'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Terminar Sessão',
            onPressed: () => authService.signOut(),
          ),
        ],
      ),
      body: StreamBuilder<List<Delivery>>(
        stream: _availableDeliveriesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Ocorreu um erro: ${snapshot.error}'));
          }
          final deliveries = snapshot.data ?? [];
          if (deliveries.isEmpty) {
            return const Center(
                child: Text('Nenhuma entrega disponível de momento.'));
          }

          return ListView.builder(
            itemCount: deliveries.length,
            itemBuilder: (context, index) {
              final delivery = deliveries[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 3,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(delivery.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(child: Text(delivery.pickupAddress)),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 10.0),
                        child:
                            Icon(Icons.more_vert, size: 16, color: Colors.grey),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.pin_drop, size: 16, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(child: Text(delivery.deliveryAddress)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          CurrencyFormatter.format(delivery.price),
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: () => _acceptDelivery(delivery),
                    child: const Text('Aceitar'),
                  ),
                  isThreeLine: true,
                  onTap: () =>
                      context.push('/details/${delivery.id}'), // Navegar para os detalhes
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/new'),
        label: const Text('Nova Entrega'),
        icon: const Icon(Icons.add),
        tooltip: 'Criar uma nova entrega',
      ),
    );
  }
}
