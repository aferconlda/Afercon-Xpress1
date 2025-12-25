
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'models/delivery_model.dart';

class MyDeliveriesScreen extends StatefulWidget {
  const MyDeliveriesScreen({super.key});

  @override
  State<MyDeliveriesScreen> createState() => _MyDeliveriesScreenState();
}

class _MyDeliveriesScreenState extends State<MyDeliveriesScreen> {
  Stream<List<Delivery>>? _myDeliveriesStream;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final driverId = context.watch<User?>()?.uid;
    if (driverId != null && _myDeliveriesStream == null) {
      _setupStream(driverId);
    }
  }

  void _setupStream(String driverId) {
    setState(() {
      _myDeliveriesStream = FirebaseFirestore.instance
          .collection('deliveries')
          .where('driverId', isEqualTo: driverId)
          .where('status', whereIn: [
            DeliveryStatus.inProgress.name,
            DeliveryStatus.pendingConfirmation.name,
            DeliveryStatus.completed.name,
            DeliveryStatus.cancellationRequestedByClient.name,
            DeliveryStatus.cancellationRequestedByDriver.name,
            DeliveryStatus.cancelled.name,
          ])
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => Delivery.fromMap(doc.id, doc.data()))
              .toList());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('As Minhas Entregas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green, Colors.blue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white), // Para o botão de voltar, se houver
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _myDeliveriesStream == null
          ? const Center(child: Text('A iniciar...'))
          : StreamBuilder<List<Delivery>>(
              stream: _myDeliveriesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Erro: ${snapshot.error}'));
                }
                final deliveries = snapshot.data ?? [];
                if (deliveries.isEmpty) {
                  return const Center(
                      child: Text('Não tem entregas em andamento ou concluídas.'));
                }

                return ListView.builder(
                  itemCount: deliveries.length,
                  itemBuilder: (context, index) {
                    final delivery = deliveries[index];
                    return DeliveryListItem(
                      delivery: delivery,
                    );
                  },
                );
              },
            ),
    );
  }
}

class DeliveryListItem extends StatelessWidget {
  final Delivery delivery;

  const DeliveryListItem({
    super.key,
    required this.delivery,
  });

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
      case DeliveryStatus.cancellationRequestedByClient:
        return 'Cancelamento Solicitado';
      case DeliveryStatus.cancellationRequestedByDriver:
        return 'Cancelamento Solicitado';
      case DeliveryStatus.cancelled:
        return 'Cancelada';
    }
  }

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
      case DeliveryStatus.cancellationRequestedByClient:
      case DeliveryStatus.cancellationRequestedByDriver:
      case DeliveryStatus.cancelled:
        return Colors.red;
    }
  }


  @override
  Widget build(BuildContext context) {

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(delivery.title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
            'De: ${delivery.pickupAddress}\nPara: ${delivery.deliveryAddress}'),
        trailing: Chip(
          label: Text(_getStatusText(delivery.status)),
          backgroundColor: _getStatusColor(delivery.status),
          labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onTap: () => context.push('/details/${delivery.id}'),
        isThreeLine: true,
      ),
    );
  }
}
