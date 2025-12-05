
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
        title: const Text('O Meu Perfil'),
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
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    _buildProfileHeader(context, appUser, firebaseUser),
                    const SizedBox(height: 24),
                    _buildInfoCard(context, appUser, firebaseUser),
                    if (appUser.vehicleModel != null && appUser.vehicleModel!.isNotEmpty)
                      _buildVehicleCard(context, appUser),
                    const SizedBox(height: 24),
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
            Icons.person,
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
              style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
            ),
            if (firebaseUser.emailVerified)
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Icon(
                  Icons.verified,
                  color: Colors.blueAccent,
                  size: 18,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context, AppUser appUser, User firebaseUser) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Informações Pessoais', style: Theme.of(context).textTheme.titleLarge),
            const Divider(height: 24),
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text('E-mail'),
              subtitle: Row(
                children: [
                  Text(appUser.email),
                  if (firebaseUser.emailVerified)
                    const Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: Icon(
                        Icons.verified_user,
                        color: Colors.green,
                        size: 16,
                      ),
                    ),
                ],
              ),
              trailing: !firebaseUser.emailVerified
                  ? TextButton(
                      onPressed: () async {
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        await firebaseUser.sendEmailVerification();
                        if (!context.mounted) return;
                        scaffoldMessenger.showSnackBar(const SnackBar(
                          content: Text('E-mail de verificação enviado!'),
                          backgroundColor: Colors.green,
                        ));
                      },
                      child: const Text('Verificar'))
                  : null,
            ),
            ListTile(
              leading: const Icon(Icons.phone_outlined),
              title: const Text('Número de Telemóvel'),
              subtitle: Text(appUser.phoneNumber),
            ),
            if (appUser.dateOfBirth != null)
              ListTile(
                leading: const Icon(Icons.cake_outlined),
                title: const Text('Data de Nascimento'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(appUser.dateOfBirth!)),
              ),
            if (appUser.nationality != null && appUser.nationality!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: const Text('Nacionalidade'),
                subtitle: Text(appUser.nationality!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleCard(BuildContext context, AppUser user) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Informações do Veículo', style: Theme.of(context).textTheme.titleLarge),
            const Divider(height: 24),
            ListTile(
              leading: const Icon(Icons.directions_car_filled),
              title: const Text('Modelo'),
              subtitle: Text(user.vehicleModel ?? 'Não especificado'),
            ),
            ListTile(
              leading: const Icon(Icons.numbers),
              title: const Text('Matrícula'),
              subtitle: Text(user.vehiclePlate ?? 'Não especificado'),
            ),
            ListTile(
              leading: const Icon(Icons.color_lens_outlined),
              title: const Text('Cor'),
              subtitle: Text(user.vehicleColor ?? 'Não especificado'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, AppUser user) {
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
        OutlinedButton.icon(
          icon: const Icon(Icons.lock_outline),
          label: const Text('Alterar Palavra-passe'),
          onPressed: () async {
            final authService = context.read<AuthService>();
            final scaffoldMessenger = ScaffoldMessenger.of(context);
            final result = await authService.sendPasswordResetEmail(email: user.email);

            if (!context.mounted) return;
            if (result == "Success") {
              scaffoldMessenger.showSnackBar(
                const SnackBar(
                  content: Text('E-mail para redefinição de palavra-passe enviado! Verifique a sua caixa de entrada.'),
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
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }
}
