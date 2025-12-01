
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Política de Privacidade'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Política de Privacidade',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Última atualização: 24 de Julho de 2024',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            SizedBox(height: 24),
            Text(
              'Esta Política de Privacidade descreve como as suas informações são recolhidas, usadas e partilhadas quando utiliza a nossa aplicação.',
            ),
            SizedBox(height: 16),
            Text('1. Informações que Recolhemos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
              'Recolhemos informações que nos fornece diretamente, como nome, email, número de telefone e detalhes do veículo (para motoristas). Também recolhemos dados de transação relacionados às entregas.',
            ),
            SizedBox(height: 16),
            Text('2. Como Usamos as Suas Informações', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
              'Usamos as suas informações para operar e manter a aplicação, para processar transações, para nos comunicarmos consigo e para melhorar os nossos serviços.',
            ),
             SizedBox(height: 16),
            Text('3. Partilha de Informações', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
              'Partilhamos informações entre clientes e motoristas para facilitar a entrega (ex: nomes, localizações). Não vendemos as suas informações pessoais a terceiros.',
            ),
            // Adicione mais seções conforme necessário...
          ],
        ),
      ),
    );
  }
}
