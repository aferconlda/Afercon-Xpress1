
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  late Stream<Delivery?> _deliveryStream;

  @override
  void initState() {
    super.initState();
    _deliveryStream = context.read<AuthService>().getDeliveryStream(widget.deliveryId);
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
    return StreamBuilder<Delivery?>(
      stream: _deliveryStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Detalhes da Entrega')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Erro')),
            body: const Center(child: Text('Erro ao carregar os detalhes da entrega.')),
          );
        }

        final delivery = snapshot.data!;
        final authService = context.read<AuthService>();
        final currentUser = authService.currentUser;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Detalhes da Entrega'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HeaderCard(delivery: delivery),
                _CancellationInfo(delivery: delivery),
                _RouteTimeline(delivery: delivery),
                _InfoCard(
                  title: 'Detalhes do Pacote',
                  icon: Icons.inventory_2_outlined,
                  children: [
                    _InfoRow(label: 'Item', value: delivery.title),
                    _InfoRow(label: 'Descrição', value: delivery.description, isMultiline: true),
                  ],
                ),
                _InfoCard(
                  title: 'Destinatário',
                  icon: Icons.person_pin_outlined,
                  children: [
                    _InfoRow(label: 'Nome', value: delivery.recipientName),
                    _InfoRow(label: 'Contacto', value: delivery.recipientPhone, isPhone: true, onPhoneTap: () => _launchUri(Uri.parse('tel:${delivery.recipientPhone}'))),
                  ],
                ),
                _InfoCard(
                  title: 'Financeiro',
                  icon: Icons.monetization_on_outlined,
                  children: [
                    _PriceRow(price: delivery.price),
                  ],
                ),
                if (delivery.driverId != null)
                  _DriverInfo(delivery: delivery),
                if (currentUser?.uid == delivery.driverId && delivery.status == DeliveryStatus.completed)
                  _CommissionPanel(delivery: delivery, driverId: delivery.driverId!),
              ],
            ),
          ),
          bottomNavigationBar: _ActionBottomBar(delivery: delivery, onStateChange: () => setState(() {})),
        );
      },
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final Delivery delivery;
  const _HeaderCard({required this.delivery});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            delivery.title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Chip(
              label: Text(_getStatusText(delivery.status)),
              backgroundColor: _getStatusColor(delivery.status),
              labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              elevation: 2,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _RouteTimeline extends StatelessWidget {
  final Delivery delivery;
  const _RouteTimeline({required this.delivery});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Percurso", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _TimelineTile(
                icon: Icons.radio_button_checked,
                iconColor: Colors.blueAccent,
                title: 'Recolha',
                subtitle: delivery.pickupAddress,
                isFirst: true,
              ),
              _TimelineTile(
                icon: Icons.location_on,
                iconColor: Colors.redAccent,
                title: 'Entrega',
                subtitle: delivery.deliveryAddress,
                isLast: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isFirst;
  final bool isLast;

  const _TimelineTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isFirst)
                Expanded(child: Container(width: 2, color: Colors.grey.shade300)),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: iconColor, width: 2),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              if (!isLast)
                Expanded(child: Container(width: 2, color: Colors.grey.shade300)),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 2),
                Text(subtitle, style: theme.textTheme.bodyLarge, maxLines: 3, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _InfoCard({required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: theme.colorScheme.primary, size: 22),
                  const SizedBox(width: 12),
                  Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const Divider(height: 24),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isMultiline;
  final bool isPhone;
  final VoidCallback? onPhoneTap;

  const _InfoRow({
    required this.label,
    required this.value,
    this.isMultiline = false,
    this.isPhone = false,
    this.onPhoneTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          if (isPhone)
            InkWell(
              onTap: onPhoneTap,
              child: Row(
                children: [
                  Text(value, style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Icon(Icons.call_outlined, size: 16, color: theme.colorScheme.primary),
                ],
              ),
            )
          else
            Text(value, style: theme.textTheme.bodyLarge, softWrap: isMultiline, overflow: TextOverflow.fade),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final double price;
  const _PriceRow({required this.price});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Valor da Entrega', style: theme.textTheme.bodyLarge),
        Text(
          CurrencyFormatter.format(price),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

class _DriverInfo extends StatelessWidget {
  final Delivery delivery;
  const _DriverInfo({required this.delivery});

  IconData _getVehicleIcon(String? vehicleType) {
    if (vehicleType == 'motorcycle') return Icons.two_wheeler;
    return Icons.directions_car;
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    return FutureBuilder<AppUser?>(
      future: authService.getUserDetails(delivery.driverId!),
      builder: (context, driverSnapshot) {
        if (!driverSnapshot.hasData) {
          return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()));
        }
        if (driverSnapshot.hasError || driverSnapshot.data == null) {
          return const _InfoCard(
            title: 'Motorista',
            icon: Icons.delivery_dining_outlined,
            children: [_InfoRow(label: 'Erro', value: 'Não foi possível carregar os dados do motorista.')],
          );
        }

        final driver = driverSnapshot.data!;
        
        return _InfoCard(
          title: 'Motorista Responsável',
          icon: _getVehicleIcon(driver.vehicleType),
          children: [
            _InfoRow(label: 'Nome', value: driver.fullName),
             _InfoRow(
                label: 'Contacto', 
                value: driver.phoneNumber, 
                isPhone: true, 
                onPhoneTap: () async {
                  final Uri telUri = Uri.parse('tel:${driver.phoneNumber}');
                   if (await canLaunchUrl(telUri)) {
                    await launchUrl(telUri);
                  }
                }
            ),
            if(driver.vehicleMake != null && driver.vehicleModel != null)
               _InfoRow(label: 'Veículo', value: '${driver.vehicleMake} ${driver.vehicleModel}'),
            if(driver.vehicleColor != null && driver.vehicleYear != null)
                _InfoRow(label: 'Cor e Ano', value: '${driver.vehicleColor} (${driver.vehicleYear})'),
            if(driver.vehiclePlate != null)
                _InfoRow(label: 'Matrícula', value: driver.vehiclePlate!),
          ],
        );
      },
    );
  }
}

class _ActionBottomBar extends StatelessWidget {
  final Delivery delivery;
  final VoidCallback onStateChange;

  const _ActionBottomBar({required this.delivery, required this.onStateChange});

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final currentUser = authService.currentUser;

    if (currentUser == null) return const SizedBox.shrink();

    Widget? actionButton;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    if (currentUser.uid == delivery.driverId && delivery.status == DeliveryStatus.inProgress) {
      actionButton = ElevatedButton.icon(
        onPressed: () async {
          final result = await authService.updateDeliveryStatus(delivery.id, DeliveryStatus.pendingConfirmation);
          if (result != "Success") {
             if (!context.mounted) return;
            scaffoldMessenger.showSnackBar(SnackBar(content: Text(result ?? 'Erro desconhecido')));
          }
        },
        icon: const Icon(Icons.check_circle_outline),
        label: const Text('MARCAR COMO ENTREGUE'),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600, foregroundColor: Colors.white),
      );
    } else if (currentUser.uid == delivery.userId && delivery.status == DeliveryStatus.pendingConfirmation) {
      actionButton = ElevatedButton.icon(
        onPressed: () async {
          final result = await authService.updateDeliveryStatus(delivery.id, DeliveryStatus.completed);
           if (result != "Success") {
            if (!context.mounted) return;
            scaffoldMessenger.showSnackBar(SnackBar(content: Text(result ?? 'Erro desconhecido')));
          }
        },
        icon: const Icon(Icons.thumb_up_outlined),
        label: const Text('CONFIRMAR RECEBIMENTO'),
      );
    }

    if (actionButton == null) return const SizedBox.shrink();

    return BottomAppBar(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: SizedBox(width: double.infinity, child: actionButton),
      ),
    );
  }
}

class _CancellationInfo extends StatefulWidget {
    final Delivery delivery;
    const _CancellationInfo({required this.delivery});

    @override
    State<_CancellationInfo> createState() => _CancellationInfoState();
}

class _CancellationInfoState extends State<_CancellationInfo> {
    final TextEditingController _reasonController = TextEditingController();

    void _showCancellationDialog(BuildContext context, String deliveryId, String requestedBy) {
        final authService = context.read<AuthService>();
        final scaffoldMessenger = ScaffoldMessenger.of(context);

        showDialog(
            context: context,
            builder: (dialogContext) {
                return AlertDialog(
                    title: const Text('Cancelar Entrega'),
                    content: TextField(
                        controller: _reasonController,
                        decoration: const InputDecoration(labelText: 'Motivo do cancelamento (opcional)', border: OutlineInputBorder()),
                        maxLines: 3,
                    ),
                    actions: [
                        TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Voltar')),
                        ElevatedButton(
                            onPressed: () async {
                                final reason = _reasonController.text;
                                final result = await authService.requestCancellation(deliveryId, requestedBy, reason);
                                
                                if (!context.mounted) return;
                                Navigator.of(dialogContext).pop();

                                if (result != 'Success') {
                                     scaffoldMessenger.showSnackBar(SnackBar(content: Text(result ?? 'Erro ao pedir o cancelamento.')));
                                }
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            child: const Text('Pedir Cancelamento'),
                        ),
                    ],
                );
            },
        );
    }

    @override
    void dispose() {
        _reasonController.dispose();
        super.dispose();
    }

    @override
    Widget build(BuildContext context) {
        final authService = context.read<AuthService>();
        final currentUser = authService.currentUser;
        if (currentUser == null) return const SizedBox.shrink();

        final isClient = currentUser.uid == widget.delivery.userId;
        final isDriver = currentUser.uid == widget.delivery.driverId;
        final isCancellationPending = widget.delivery.cancellationStatus == 'pending';
        
        if (widget.delivery.status == DeliveryStatus.cancelled) {
            return _StatusInfoCard(
              message: 'Esta entrega foi cancelada.',
              icon: Icons.cancel,
              statusType: _StatusInfoType.error,
            );
        }

        if (isCancellationPending) {
            final requesterIsClient = widget.delivery.cancellationRequestedBy == 'client';
            if ((isClient && !requesterIsClient) || (isDriver && requesterIsClient)) {
                return _CancellationConfirmationCard(deliveryId: widget.delivery.id);
            } else {
                 return _StatusInfoCard(
                    message: 'Pedido de cancelamento enviado. A aguardar a confirmação da outra parte.',
                    icon: Icons.hourglass_empty,
                    statusType: _StatusInfoType.warning,
                 );
            }
        }
        
        if (widget.delivery.status == DeliveryStatus.inProgress) {
             return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextButton.icon(
                    onPressed: () => _showCancellationDialog(context, widget.delivery.id, isClient ? 'client' : 'driver'),
                    icon: Icon(Icons.cancel_outlined, color: Theme.of(context).colorScheme.error),
                    label: Text('Pedir cancelamento da entrega', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
            );
        }

        return const SizedBox.shrink();
    }
}

class _CancellationConfirmationCard extends StatelessWidget {
  final String deliveryId;
  const _CancellationConfirmationCard({required this.deliveryId});

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        color: theme.colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                'A outra parte solicitou o cancelamento. O que deseja fazer?',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onErrorContainer),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(onPressed: () => authService.clearCancellationRequest(deliveryId), child: const Text('Recusar')),
                  ElevatedButton(
                    onPressed: () => authService.confirmCancellation(deliveryId),
                    style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.error, foregroundColor: theme.colorScheme.onError),
                    child: const Text('Confirmar'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

enum _StatusInfoType { error, warning, info }

class _StatusInfoCard extends StatelessWidget {
    final String message;
    final IconData icon;
    final _StatusInfoType statusType;

    const _StatusInfoCard({required this.message, required this.icon, required this.statusType});

    @override
    Widget build(BuildContext context) {
        final theme = Theme.of(context);
        final Color backgroundColor;
        final Color foregroundColor;

        switch(statusType) {
          case _StatusInfoType.error:
            backgroundColor = theme.colorScheme.errorContainer;
            foregroundColor = theme.colorScheme.onErrorContainer;
            break;
          case _StatusInfoType.warning:
            backgroundColor = theme.colorScheme.tertiaryContainer;
            foregroundColor = theme.colorScheme.onTertiaryContainer;
            break;
          case _StatusInfoType.info:
            backgroundColor = theme.colorScheme.secondaryContainer;
            foregroundColor = theme.colorScheme.onSecondaryContainer;
            break;
        }

        return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Card(
                color: backgroundColor,
                child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                        children: [
                            Icon(icon, color: foregroundColor),
                            const SizedBox(width: 16),
                            Expanded(child: Text(message, style: TextStyle(color: foregroundColor, fontWeight: FontWeight.bold))),
                        ],
                    ),
                ),
            ),
        );
    }
}

class _CommissionPanel extends StatelessWidget {
    final Delivery delivery;
    final String driverId;
    const _CommissionPanel({required this.delivery, required this.driverId});
    
    @override
    Widget build(BuildContext context) {
        final authService = context.read<AuthService>();
        final theme = Theme.of(context);
        final commission = delivery.price * 0.10;
        const iban = 'AO06.0055.0000.39.51.3329.1016.7';
        const bank = 'Banco Atlântico';
        const whatsappNumber = '+244945100502';

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Card(
            color: theme.colorScheme.surfaceContainerHighest,
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: FutureBuilder<AppUser?>(
                  future: authService.getUserDetails(driverId),
                  builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      final driver = snapshot.data!;
                      final whatsappMessage = Uri.encodeComponent(
                          'Comprovativo de Pagamento de Comissão\n\n'
                          'Motorista: ${driver.fullName}\n'
                          'Email: ${driver.email}\n'
                          'Contacto: ${driver.phoneNumber}\n\n'
                          'Entrega: ${delivery.title} (ID: ${delivery.id})\n'
                          'Valor da Comissão: ${CurrencyFormatter.format(commission)}');

                      return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                              Text('Pagamento de Comissão (10%)', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                              const Divider(height: 24),
                              Text('Para manter a plataforma ativa, uma taxa de 10% é aplicada a cada entrega concluída.', style: theme.textTheme.bodyMedium),
                              const SizedBox(height: 16),
                              _PriceRow(price: commission),
                              const Divider(height: 24),
                              _InfoRow(label: 'IBAN', value: iban),
                              _InfoRow(label: 'Banco', value: bank),
                              Center(
                                child: TextButton.icon(
                                  icon: const Icon(Icons.copy, size: 16),
                                  label: const Text('Copiar IBAN'),
                                  onPressed: () {
                                    Clipboard.setData(const ClipboardData(text: iban));
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('IBAN copiado!')));
                                  },
                                ),
                              ),
                              const Divider(height: 24),
                              Text('Após o pagamento, envie o comprovativo pelo WhatsApp.', style: theme.textTheme.bodyMedium),
                              const SizedBox(height: 16),
                              Center(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.send_to_mobile),
                                  label: const Text('Enviar Comprovativo'),
                                  onPressed: () async {
                                      final Uri waUri = Uri.parse('https://wa.me/$whatsappNumber?text=$whatsappMessage');
                                      if (await canLaunchUrl(waUri)) {
                                          await launchUrl(waUri, mode: LaunchMode.externalApplication);
                                      }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF25D366),
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                      );
                  }),
            ),
          ),
        );
    }
}

String _getStatusText(DeliveryStatus status) {
  switch (status) {
    case DeliveryStatus.available: return 'Disponível';
    case DeliveryStatus.inProgress: return 'Em Progresso';
    case DeliveryStatus.pendingConfirmation: return 'A Aguardar Confirmação';
    case DeliveryStatus.completed: return 'Concluída';
    case DeliveryStatus.cancelled: return 'Cancelada';
  }
}

Color _getStatusColor(DeliveryStatus status) {
  switch (status) {
    case DeliveryStatus.available: return Colors.blue.shade600;
    case DeliveryStatus.inProgress: return Colors.orange.shade600;
    case DeliveryStatus.pendingConfirmation: return Colors.purple.shade600;
    case DeliveryStatus.completed: return Colors.green.shade600;
    case DeliveryStatus.cancelled: return Colors.red.shade600;
  }
}
