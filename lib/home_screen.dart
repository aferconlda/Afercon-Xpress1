
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'auth_service.dart';
import 'main.dart';
import 'models/delivery_model.dart';
import 'models/user_model.dart';
import 'utils/currency_formatter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Stream<List<Delivery>> _availableDeliveriesStream = FirebaseFirestore
      .instance
      .collection('deliveries')
      .where('status', isEqualTo: DeliveryStatus.available.name)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => Delivery.fromMap(doc.id, doc.data()))
          .toList());

  Future<void> _acceptDelivery(Delivery delivery) async {
    final authService = context.read<AuthService>();
    final driverId = authService.currentUser?.uid;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    if (driverId == null) return;

    final AppUser? driverData = await authService.getUserDetails(driverId);

    if (driverData?.vehiclePlate?.trim().isEmpty ?? true) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text(
              'Por favor, complete as informações do seu veículo no perfil.'),
          backgroundColor: Colors.orange,
        ),
      );
      // Opcional: Navegar para a tela de edição de perfil
      // router.push('/profile/edit');
      return;
    }

    if (delivery.userId == driverId) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
            content: Text('Não pode aceitar a sua própria entrega.')),
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

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Entrega aceite com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      router.push('/details/${delivery.id}');
    } catch (e) {
      scaffoldMessenger
          .showSnackBar(SnackBar(content: Text('Erro ao aceitar: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final theme = Theme.of(context);
    final authService = context.read<AuthService>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Mercado de Entregas',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(themeProvider.themeMode == ThemeMode.dark
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined),
            tooltip: 'Alterar Tema',
            onPressed: () => context.read<ThemeProvider>().toggleTheme(),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            tooltip: 'Notificações',
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Perfil',
            onPressed: () => context.push('/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Terminar Sessão',
            onPressed: () => authService.signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          const _GreetingCard(),
          Expanded(
            child: StreamBuilder<List<Delivery>>(
              stream: _availableDeliveriesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                      child:
                          Text('Ocorreu um erro: ${snapshot.error}'));
                }
                final deliveries = snapshot.data ?? [];
                if (deliveries.isEmpty) {
                  return const Center(
                      child:
                          Text('Nenhuma entrega disponível de momento.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  itemCount: deliveries.length,
                  itemBuilder: (context, index) {
                    final delivery = deliveries[index];
                    return DeliveryCard(
                      delivery: delivery,
                      onAccept: () => _acceptDelivery(delivery),
                      onTap: () => context.push('/details/${delivery.id}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.list_alt),
              tooltip: 'Minhas Entregas (Cliente)',
              onPressed: () => context.push('/client-deliveries'),
            ),
            IconButton(
              icon: const Icon(Icons.delivery_dining),
              tooltip: 'Minhas Entregas (Motorista)',
              onPressed: () => context.push('/my-deliveries'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/new'),
        label: const Text('Nova Entrega'),
        icon: const Icon(Icons.add),
        tooltip: 'Criar uma nova entrega',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

class _GreetingCard extends StatelessWidget {
  const _GreetingCard();

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia';
    if (hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<User?>()?.uid;
    final theme = Theme.of(context);

    if (userId == null) return const SizedBox.shrink();

    final userFuture =
        FirebaseFirestore.instance.collection('users').doc(userId).get();

    return FutureBuilder<DocumentSnapshot>(
      future: userFuture,
      builder: (context, snapshot) {
        final userName = (snapshot.hasData && snapshot.data!.exists)
            ? (snapshot.data!.data() as Map<String, dynamic>)['fullName'] ??
                'Utilizador'
            : 'Utilizador';

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                Color.lerp(theme.colorScheme.primary, theme.colorScheme.secondary, 0.5)!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withAlpha(77),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_getGreeting()}, $userName!',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Aqui estão as novas oportunidades de entrega.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withAlpha(230),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}


class DeliveryCard extends StatelessWidget {
  final Delivery delivery;
  final VoidCallback onAccept;
  final VoidCallback onTap;

  const DeliveryCard({
    super.key,
    required this.delivery,
    required this.onAccept,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFormat = DateFormat('dd/MM, HH:mm');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      elevation: 5,
      shadowColor: Colors.black.withAlpha(25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Linha do Título e Preço
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      delivery.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    CurrencyFormatter.format(delivery.price),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Informação do Percurso
              _buildRouteInfo(theme, delivery.pickupAddress, delivery.deliveryAddress),

              const Divider(height: 32),

              // Linha de Data e Botão de Aceitar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.timer_outlined, size: 16, color: theme.textTheme.bodySmall?.color),
                      const SizedBox(width: 6),
                      Text(
                        'Criado às ${timeFormat.format(delivery.createdAt)}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),

                  ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Aceitar', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRouteInfo(ThemeData theme, String pickup, String delivery) {
    return Row(
      children: [
        // Ícones do percurso
        Column(
          children: [
            const Icon(Icons.radio_button_checked, color: Colors.blue, size: 20),
            Container(
              height: 30,
              width: 1,
              color: Colors.grey.shade400,
            ),
            const Icon(Icons.location_on, color: Colors.red, size: 20),
          ],
        ),
        const SizedBox(width: 12),
        // Textos do percurso
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Recolha', style: theme.textTheme.bodySmall),
              Text(
                pickup,
                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text('Entrega', style: theme.textTheme.bodySmall),
              Text(
                delivery,
                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
