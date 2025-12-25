
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'models/delivery_model.dart';
import 'utils/currency_formatter.dart';

class ClientDeliveriesScreen extends StatelessWidget {
  const ClientDeliveriesScreen({super.key});

  Stream<List<Delivery>> _getClientDeliveriesStream(String userId) {
    return FirebaseFirestore.instance
        .collection('deliveries')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Delivery.fromMap(doc.id, doc.data()))
            .toList());
  }

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
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!userSnapshot.hasData || userSnapshot.data == null) {
            return const Center(
                child: Text('Precisa de estar autenticado para ver as suas entregas.'));
          }
          final user = userSnapshot.data!;

          return StreamBuilder<List<Delivery>>(
            stream: _getClientDeliveriesStream(user.uid),
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
                    child: Text('Ainda não publicou nenhuma entrega.'));
              }

              return ListView.builder(
                itemCount: deliveries.length,
                itemBuilder: (context, index) {
                  final delivery = deliveries[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text(delivery.title,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                          'De: ${delivery.pickupAddress}\nPara: ${delivery.deliveryAddress}'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _getStatusText(delivery.status),
                            style: TextStyle(
                              color: _getStatusColor(delivery.status),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(CurrencyFormatter.format(delivery.totalPrice)),
                        ],
                      ),
                      onTap: () => context.push('/details/${delivery.id}'),
                      isThreeLine: true,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
