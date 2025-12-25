
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'auth_service.dart';
import 'models/user_model.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final firebaseUser = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('O Meu Perfil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green, Colors.blue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: firebaseUser == null
          ? const Center(child: Text('Nenhum utilizador autenticado.'))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(firebaseUser.uid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text('Não foi possível carregar os dados do perfil.'));
                }

                final appUser = AppUser.fromMap(snapshot.data!);

                return ListView(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  children: [
                    _buildProfileHeader(context, appUser, firebaseUser),
                    const SizedBox(height: 24),
                    _buildInfoCard(context, appUser, firebaseUser),
                    if (appUser.vehicleType != null && appUser.vehicleType!.isNotEmpty) ...[
                       const SizedBox(height: 24),
                      _buildVehicleCard(context, appUser),
                    ],
                    const SizedBox(height: 32),
                    _buildActionButtons(context, appUser),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, AppUser appUser, User firebaseUser) {
    final theme = Theme.of(context);
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: theme.colorScheme.primary.withAlpha(26),
          child: Icon(
            appUser.vehicleType?.isNotEmpty ?? false ? Icons.drive_eta_outlined : Icons.person_outline,
            size: 50,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          appUser.fullName,
          style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              appUser.email,
              style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
            ),
            if (firebaseUser.emailVerified)
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Tooltip(
                  message: 'E-mail Verificado',
                  child: Icon(
                    Icons.verified,
                    color: Colors.blueAccent,
                    size: 18,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoTile(BuildContext context, {required IconData icon, required String title, required String? subtitle, Widget? trailing}) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.secondary, size: 22),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle ?? 'Não especificado', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      trailing: trailing,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildInfoCard(BuildContext context, AppUser appUser, User firebaseUser) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text('Informações Pessoais', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ),
            const Divider(height: 16),
            _buildInfoTile(
              context,
              icon: Icons.email_outlined,
              title: 'E-mail',
              subtitle: appUser.email,
              trailing: !firebaseUser.emailVerified
                  ? TextButton(onPressed: () async { /* ... */ }, child: const Text('Verificar'))
                  : const Padding(
                      padding: EdgeInsets.only(right: 8.0),
                      child: Icon(Icons.verified, color: Colors.blueAccent, size: 20),
                    ),
            ),
            const Divider(indent: 56),
            _buildInfoTile(
              context,
              icon: Icons.phone_outlined,
              title: 'Número de Telemóvel',
              subtitle: appUser.phoneNumber,
            ),
            if (appUser.dateOfBirth != null) ...[
              const Divider(indent: 56),
              _buildInfoTile(
                context,
                icon: Icons.cake_outlined,
                title: 'Data de Nascimento',
                subtitle: DateFormat('dd/MM/yyyy').format(appUser.dateOfBirth!),
              ),
            ],
            if (appUser.nationality != null && appUser.nationality!.isNotEmpty) ...[
              const Divider(indent: 56),
              _buildInfoTile(
                context,
                icon: Icons.flag_outlined,
                title: 'Nacionalidade',
                subtitle: appUser.nationality!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleCard(BuildContext context, AppUser user) {
    final isMotorcycle = user.vehicleType == 'motorcycle';
    final vehicleName = isMotorcycle ? 'Mota' : 'Carro';
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Icon(isMotorcycle ? Icons.two_wheeler : Icons.directions_car, color: theme.textTheme.titleLarge?.color, size: 22),
                  const SizedBox(width: 12),
                  Text('Informações do Veículo', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const Divider(height: 16),
            _buildInfoTile(context, icon: Icons.category_outlined, title: 'Tipo de Veículo', subtitle: vehicleName),
            const Divider(indent: 56),
            _buildInfoTile(context, icon: Icons.branding_watermark_outlined, title: isMotorcycle ? 'Marca da Mota' : 'Marca do Carro', subtitle: user.vehicleMake),
            const Divider(indent: 56),
            _buildInfoTile(context, icon: Icons.model_training_outlined, title: 'Modelo', subtitle: user.vehicleModel),
            const Divider(indent: 56),
            _buildInfoTile(context, icon: Icons.calendar_today_outlined, title: 'Ano', subtitle: user.vehicleYear?.toString()),
            const Divider(indent: 56),
            _buildInfoTile(context, icon: Icons.pin_outlined, title: 'Matrícula', subtitle: user.vehiclePlate),
            const Divider(indent: 56),
            _buildInfoTile(context, icon: Icons.color_lens_outlined, title: 'Cor', subtitle: user.vehicleColor),
            const Divider(indent: 56),
            _buildInfoTile(context, icon: Icons.badge_outlined, title: 'Nº da Carta de Condução', subtitle: user.driverLicenseNumber),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, AppUser user) {
     final authService = context.read<AuthService>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Editar Perfil'),
          onPressed: () => context.push('/profile/edit'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          icon: Icon(Icons.lock_reset_outlined, color: Theme.of(context).colorScheme.secondary),
          label: Text('Alterar Palavra-passe', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
          onPressed: () async {
            final scaffoldMessenger = ScaffoldMessenger.of(context);
            final result = await authService.sendPasswordResetEmail(email: user.email);

            if (!context.mounted) return;
            if (result == "Success") {
              scaffoldMessenger.showSnackBar(
                const SnackBar(
                  content: Text('E-mail para redefinição de palavra-passe enviado!'),
                  backgroundColor: Colors.green,
                ),
              );
            } else {
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text(result ?? 'Ocorreu um erro desconhecido.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
             side: BorderSide(color: Theme.of(context).colorScheme.secondary)
          ),
        ),
      ],
    );
  }
}
