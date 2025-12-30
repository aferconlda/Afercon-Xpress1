
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'models/delivery_model.dart';
import 'auth_service.dart';

class ChatScreen extends StatefulWidget {
  final String deliveryId;

  const ChatScreen({super.key, required this.deliveryId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final Stream<Delivery> _deliveryStream;
  late final Stream<QuerySnapshot> _messagesStream;

  @override
  void initState() {
    super.initState();
    _deliveryStream = FirebaseFirestore.instance
        .collection('deliveries')
        .doc(widget.deliveryId)
        .snapshots()
        .map((doc) => Delivery.fromMap(doc.id, doc.data()!));

    _messagesStream = FirebaseFirestore.instance
        .collection('deliveries')
        .doc(widget.deliveryId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();

    _messagesStream.listen((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });

    _markChatAsViewed();
  }

  Future<void> _markChatAsViewed() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final deliveryRef = FirebaseFirestore.instance.collection('deliveries').doc(widget.deliveryId);
    final deliveryDoc = await deliveryRef.get();
    final delivery = Delivery.fromMap(deliveryDoc.id, deliveryDoc.data()!);

    final updateData = <String, dynamic>{};
    if (user.uid == delivery.userId) {
      updateData['clientLastViewedChat'] = FieldValue.serverTimestamp();
    } else if (user.uid == delivery.driverId) {
      updateData['driverLastViewedChat'] = FieldValue.serverTimestamp();
    }

    if (updateData.isNotEmpty) {
      await deliveryRef.update(updateData);
    }
  }

  Future<void> _sendMessage(User user) async {
    if (_messageController.text.trim().isEmpty) {
      return;
    }

    final authService = context.read<AuthService>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final userDetails = await authService.getUserDetails(user.uid);

    if (userDetails == null) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Erro: Não foi possível obter os detalhes do utilizador.')),
      );
      return;
    }

    final messageText = _messageController.text.trim();
    _messageController.clear();

    try {
      await FirebaseFirestore.instance
          .collection('deliveries')
          .doc(widget.deliveryId)
          .collection('messages')
          .add({
        'text': messageText,
        'senderId': user.uid,
        'senderName': userDetails.fullName,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e, s) {
      developer.log(
        'Falha ao enviar mensagem',
        name: 'chat_screen',
        error: e,
        stackTrace: s,
      );
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Erro ao enviar mensagem: ${e.message}')),
        );
      }
    }
  }


  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (!userSnapshot.hasData || userSnapshot.data == null) {
            return const Scaffold(
              body: Center(child: Text("Precisa de estar autenticado para aceder ao chat.")),
            );
          }
          final currentUser = userSnapshot.data!;

          return StreamBuilder<Delivery> (
            stream: _deliveryStream,
            builder: (context, deliverySnapshot) {
              final delivery = deliverySnapshot.data;
              final isChatActive = delivery != null && delivery.status == DeliveryStatus.inProgress;

              return Scaffold(
                appBar: AppBar(
                  title: Text(delivery?.title ?? 'Chat'),
                  flexibleSpace: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green, Colors.blue],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
                body: Column(
                  children: [
                    Expanded(
                      child: StreamBuilder<QuerySnapshot> (
                        stream: _messagesStream,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return const Center(child: Text('Ainda não há mensagens. Envie a primeira!'));
                          }

                          final messages = snapshot.data!.docs;

                          return ListView.builder(
                            reverse: true,
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16.0),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final message = messages[index];
                              final messageData = message.data() as Map<String, dynamic>;
                              final isMe = messageData['senderId'] == currentUser.uid;
                              return _buildMessageBubble(messageData, isMe);
                            },
                          );
                        },
                      ),
                    ),
                    _buildMessageInput(isChatActive, currentUser),
                  ],
                ),
              );
            },
          );
        }
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> messageData, bool isMe) {
    final theme = Theme.of(context);
    final timestamp = (messageData['timestamp'] as Timestamp?)?.toDate();
    
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: isMe ? theme.colorScheme.primary : theme.colorScheme.secondary.withAlpha(128),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(0),
            bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
             Text(
              isMe ? 'Eu' : messageData['senderName'] ?? '...',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isMe ? Colors.white : theme.textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              messageData['text'] ?? '',
              style: TextStyle(color: isMe ? Colors.white : theme.textTheme.bodyLarge?.color),
            ),
            const SizedBox(height: 6),
            Text(
              timestamp != null ? DateFormat('HH:mm').format(timestamp) : '--:--',
              style: theme.textTheme.labelSmall?.copyWith(
                color: isMe ? Colors.white70 : theme.textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput(bool isChatActive, User currentUser) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: isChatActive
          ? Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Escreva uma mensagem...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _sendMessage(currentUser),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _sendMessage(currentUser),
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            )
          : Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              alignment: Alignment.center,
              child: const Text(
                'Este chat foi encerrado.',
                style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
              ),
            ),
    );
  }
}
