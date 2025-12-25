
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import 'auth_service.dart';
import 'main.dart'; // Importa o main.dart para aceder ao ThemeProvider
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
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final authService = context.read<AuthService>();
    final theme = Theme.of(context);

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar Entrega'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Tem a certeza de que deseja aceitar esta entrega?'),
            const SizedBox(height: 16),
            _buildDialogInfo(
                icon: Icons.location_on,
                label: 'Recolha:',
                value: delivery.pickupAddress),
            const SizedBox(height: 8),
            _buildDialogInfo(
                icon: Icons.flag,
                label: 'Destino:',
                value: delivery.deliveryAddress),
            const SizedBox(height: 8),
            _buildDialogInfo(
                icon: Icons.payment,
                label: 'Valor a Receber:',
                value: CurrencyFormatter.format(delivery.totalPrice),
                valueColor: theme.colorScheme.primary),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar e Aceitar'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    final driverId = authService.currentUser?.uid;
    if (driverId == null) return;

    final AppUser? driverData = await authService.getUserDetails(driverId);
    
    if (!mounted) return;

    final isDriverProfileComplete = driverData != null &&
                                    (driverData.vehicleType?.isNotEmpty ?? false) &&
                                    (driverData.vehicleMake?.isNotEmpty ?? false);

    if (!isDriverProfileComplete) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Perfil de Motorista Incompleto'),
          content: const Text(
              'Para aceitar entregas, precisa de preencher todas as informações do seu veículo no seu perfil.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                router.push('/profile/edit');
              },
              child: const Text('Completar Perfil'),
            ),
          ],
        ),
      );
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

      if (!mounted) return;

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Entrega aceite com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      router.go('/delivery-details/${delivery.id}');
    } catch (e) {
        if (mounted) {
             scaffoldMessenger.showSnackBar(SnackBar(content: Text('Erro ao aceitar: $e')));
        }
    }
  }

  Widget _buildDialogInfo({required IconData icon, required String label, required String value, Color? valueColor}) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: theme.textTheme.bodySmall?.color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.bodySmall),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = context.read<AuthService>();
    final themeProvider = context.watch<ThemeProvider>(); // Ouve as alterações do tema

    return Scaffold(
      appBar: AppBar(
        title: Text('Afercon Xpress',
            style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white)
            ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green, Colors.blue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            // Ícone dinâmico com base no tema
            icon: Icon(
              themeProvider.themeMode == ThemeMode.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
              color: Colors.white,
            ),
            tooltip: 'Alterar Tema',
            // Chama o método para alterar o tema
            onPressed: () => context.read<ThemeProvider>().toggleTheme(),
          ),
          const _NotificationBadge(), // Ícone de notificação com contador
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, color: Colors.white),
            tooltip: 'Perfil',
            onPressed: () => context.push('/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Terminar Sessão',
            onPressed: () => authService.signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          const _GreetingCard(),
          const _AferconPayBanner(),
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
                      onTap: () => context.go('/delivery-details/${delivery.id}'),
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
        onPressed: () => context.push('/new-delivery'),
        label: const Text('Nova Entrega', style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Criar uma nova entrega',
        backgroundColor: Colors.green,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

class _NotificationBadge extends StatelessWidget {
  const _NotificationBadge();

  Stream<int> _getUnreadCountStream(String? userId) {
    if (userId == null) {
      return Stream.value(0);
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<User?>()?.uid;

    return StreamBuilder<int>(
      stream: _getUnreadCountStream(userId),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;

        return IconButton(
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_none, color: Colors.white),
              if (count > 0)
                Positioned(
                  top: -6,
                  right: -6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Center(
                      child: Text(
                        count > 9 ? '9+' : count.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          tooltip: 'Notificações',
          onPressed: () => context.push('/notifications'),
        );
      },
    );
  }
}

class _AferconPayBanner extends StatelessWidget {
  const _AferconPayBanner();

  Future<void> _launchAferconPayURL() async {
    final Uri url = Uri.parse('https://aferconpay1.web.app/');
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF004D40), Color(0xFF00796B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(51),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Descubra Afercon Pay',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pagamentos QR, transferências e mais. A sua carteira digital.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withAlpha(230),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _launchAferconPayURL,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF004D40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Saber Mais'),
          ),
        ],
      ),
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
    final authService = context.read<AuthService>();
    final theme = Theme.of(context);

    return FutureBuilder<AppUser?>(
      future: authService.getUserDetails(authService.currentUser!.uid),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final userName = user?.fullName ?? 'Utilizador';
        final isDriver = user?.vehicleType != null && user!.vehicleType!.isNotEmpty;

        final subtext = isDriver
            ? 'Aqui estão as novas oportunidades de entrega.'
            : 'Pronto para enviar a sua encomenda? Toque em \'Nova Entrega\' para começar.';

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Colors.green, Colors.blue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withAlpha(100),
                blurRadius: 12,
                offset: const Offset(0, 6),
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
                subtext,
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
                    CurrencyFormatter.format(delivery.basePrice),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildRouteInfo(theme, delivery.pickupAddress, delivery.deliveryAddress),
              const Divider(height: 32),
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
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
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
