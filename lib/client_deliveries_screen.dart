
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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
      case DeliveryStatus.cancelled:
        return Colors.red;
    }
  }

  // Função para mostrar o diálogo de confirmação de cancelamento
  Future<void> _showCancelDialog(BuildContext context, Delivery delivery) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) { // Usamos um novo nome para o contexto do diálogo
        return AlertDialog(
          title: const Text('Cancelar Pedido'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Tem a certeza que deseja cancelar permanentemente este pedido?'),
                Text('Esta ação não pode ser desfeita.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Não'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Sim, Cancelar'),
              onPressed: () async {
                // Captura o Navigator e o ScaffoldMessenger antes da operação assíncrona
                final navigator = Navigator.of(dialogContext);
                final scaffoldMessenger = ScaffoldMessenger.of(context); // O Scaffold está acima do diálogo

                try {
                  await FirebaseFirestore.instance
                      .collection('deliveries')
                      .doc(delivery.id)
                      .delete();

                  navigator.pop(); // Fecha o diálogo
                  
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Pedido cancelado com sucesso.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  navigator.pop(); // Fecha o diálogo

                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Erro ao cancelar o pedido: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<User?>();

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('As Minhas Entregas'), leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop())),
        body: const Center(
            child: Text('Precisa de estar autenticado para ver as suas entregas.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('As Minhas Entregas'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: StreamBuilder<List<Delivery>>(
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
                  trailing: Row( // Usamos um Row para o botão e o texto
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
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
                          Text(CurrencyFormatter.format(delivery.price)),
                        ],
                      ),
                      // Lógica condicional para mostrar o botão de cancelar
                      if (delivery.status == DeliveryStatus.available)
                        IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          tooltip: 'Cancelar Pedido',
                          onPressed: () => _showCancelDialog(context, delivery),
                        ),
                    ],
                  ),
                  onTap: () => context.push('/details/${delivery.id}'),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
