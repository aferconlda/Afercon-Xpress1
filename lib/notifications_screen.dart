
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'models/notification_model.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  Stream<List<NotificationModel>> _getNotificationsStream(String userId) {
    return FirebaseFirestore.instance
        .collection('users').doc(userId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .toList());
  }

  Future<void> _markAsRead(String userId, String notificationId) async {
     FirebaseFirestore.instance
        .collection('users').doc(userId)
        .collection('notifications').doc(notificationId)
        .update({'isRead': true});
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<User?>();

    return Scaffold(
      appBar: AppBar(title: const Text('Notificações')),
      body: user == null
          ? const Center(child: Text('Faça login para ver as suas notificações.'))
          : StreamBuilder<List<NotificationModel>>(
              stream: _getNotificationsStream(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Erro: ${snapshot.error}'));
                }
                final notifications = snapshot.data ?? [];

                if (notifications.isEmpty) {
                  return const Center(
                    child: Column(
                       mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Não tem notificações', style: TextStyle(fontSize: 18)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    final bool isRead = notification.isRead;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isRead
                            ? Colors.grey.withAlpha(77) // withOpacity(0.3)
                            : Theme.of(context).colorScheme.primary.withAlpha(204), // withOpacity(0.8)
                        child: Icon(
                          Icons.notifications,
                          color: isRead ? Colors.grey : Colors.white,
                        ),
                      ),
                      title: Text(notification.title, style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold)),
                      subtitle: Text(notification.body),
                      trailing: Text(
                        timeago.format(notification.createdAt.toDate(), locale: 'pt_BR'),
                         style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      onTap: () {
                        if (!isRead) {
                          _markAsRead(user.uid, notification.id);
                        }
                        // Navegar para detalhes da entrega, se aplicável
                        if (notification.deliveryId != null) {
                          // context.push('/details/${notification.deliveryId}');
                        }
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}
