
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Termos e Condições'),
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
              'Termos e Condições de Uso',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Última atualização: 24 de Julho de 2024',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            SizedBox(height: 24),
            Text(
              'Bem-vindo à nossa aplicação de entregas. Ao utilizar os nossos serviços, você concorda com os seguintes termos e condições.',
            ),
            SizedBox(height: 16),
            Text('1. Visão Geral', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
              'Esta aplicação conecta clientes que precisam de enviar itens com motoristas independentes dispostos a realizar a entrega.',
            ),
            SizedBox(height: 16),
            Text('2. Papel das Partes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
              'A nossa plataforma atua como um intermediário. Não somos responsáveis pelos itens transportados nem pelas ações dos motoristas ou clientes. O motorista é um contratante independente e não um funcionário.',
            ),
            SizedBox(height: 16),
            Text('3. Contas de Utilizador', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
              'Para usar certas funcionalidades, você deve registar-se e criar uma conta. Você é responsável por manter a confidencialidade da sua conta e senha. Motoristas devem fornecer informações verídicas sobre si e o seu veículo.',
            ),
            SizedBox(height: 16),
            Text('4. Conduta do Utilizador', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
              'É proibido usar o serviço para qualquer finalidade ilegal ou não autorizada. Concorda em não violar nenhuma lei na sua jurisdição.',
            ),
            // Adicione mais seções conforme necessário...
          ],
        ),
      ),
    );
  }
}
