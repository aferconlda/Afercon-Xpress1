
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Text(
      text,
      textAlign: TextAlign.justify,
      style: const TextStyle(fontSize: 14, height: 1.5),
    );
  }

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Termos e Condições de Uso da Afercon Xpress',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Última atualização: 24 de Julho de 2024',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            _buildSectionTitle('1. Introdução e Objeto'),
            _buildParagraph(
              'Bem-vindo à Afercon Xpress. Estes Termos e Condições regem o uso da nossa aplicação móvel e serviços (a "Plataforma"), que visa conectar utilizadores que necessitam de serviços de entrega ("Clientes") com motoristas independentes dispostos a realizar tais entregas ("Motoristas"). Ao aceder e utilizar a nossa Plataforma, o Utilizador concorda em vincular-se a estes termos.',
            ),
            _buildSectionTitle('2. Definições'),
            _buildParagraph(
              '• Cliente: Qualquer pessoa singular ou coletiva que se regista na Plataforma para solicitar um serviço de entrega.\n• Motorista: Pessoa singular que se regista na Plataforma, cumpre os requisitos exigidos e utiliza o seu próprio veículo para realizar as entregas solicitadas pelos Clientes.\n• Utilizador: Refere-se coletivamente a Clientes e Motoristas.',
            ),
             _buildSectionTitle('3. Natureza do Serviço'),
            _buildParagraph(
              'A Afercon Xpress atua exclusivamente como uma plataforma de intermediação tecnológica. A Afercon Xpress não é uma empresa de transporte ou logística. Os Motoristas são contratantes independentes, não sendo funcionários, agentes ou representantes da Afercon Xpress. A relação contratual para o serviço de entrega é estabelecida diretamente entre o Cliente e o Motorista.',
            ),
            _buildSectionTitle('4. Registo e Contas de Utilizador'),
            _buildParagraph(
              '4.1. Para aceder aos serviços, o Utilizador deve criar uma conta, fornecendo informações verdadeiras, precisas e completas. O Utilizador é responsável pela segurança da sua senha e por todas as atividades que ocorram na sua conta.\n4.2. Os Motoristas devem fornecer informações adicionais, incluindo, mas não se limitando a, carta de condução válida, registo de propriedade do veículo, seguro do veículo e registo criminal. A Afercon Xpress reserva-se o direito de verificar estas informações.',
            ),
            _buildSectionTitle('5. Obrigações do Cliente'),
            _buildParagraph(
              '• Fornecer informações precisas sobre o item a ser entregue, os endereços de recolha e entrega.\n• Embalar adequadamente os itens para garantir um transporte seguro.\n• Não solicitar o transporte de itens ilegais, perigosos, valiosos (joias, dinheiro em espécie) ou proibidos por lei, conforme detalhado na secção 7.',
            ),
            _buildSectionTitle('6. Obrigações do Motorista'),
            _buildParagraph(
              '• Manter um comportamento profissional e cortês.\n• Zelar pela integridade do item desde a recolha até à entrega.\n• Cumprir todas as leis de trânsito aplicáveis.\n• Não violar a embalagem ou o conteúdo da entrega.',
            ),
             _buildSectionTitle('7. Itens Proibidos'),
            _buildParagraph(
              'É estritamente proibido o transporte de: substâncias ilícitas, armas de fogo, materiais explosivos ou inflamáveis, animais vivos (exceto se permitido por lei e acordado entre as partes), material pornográfico, e qualquer item cuja posse ou transporte seja proibido pela lei angolana.',
            ),
            _buildSectionTitle('8. Pagamentos e Taxas'),
            _buildParagraph(
              'O Cliente pagará o valor exibido na aplicação no momento da solicitação. A Afercon Xpress reterá uma comissão de serviço (taxa de intermediação) sobre o valor da transação, sendo o remanescente transferido para o Motorista. Todas as taxas e impostos aplicáveis são da responsabilidade de cada parte, conforme a legislação fiscal em vigor.',
            ),
            _buildSectionTitle('9. Limitação de Responsabilidade'),
            _buildParagraph(
              'A Afercon Xpress não se responsabiliza por perdas, danos, ou atrasos nas entregas. A responsabilidade pela integridade do item transportado é do Motorista, desde o momento da recolha até à confirmação da entrega. Recomenda-se que os Utilizadores não enviem itens de alto valor sem um seguro privado. A nossa responsabilidade limita-se ao valor da taxa de intermediação cobrada.',
            ),
            _buildSectionTitle('10. Proteção de Dados'),
            _buildParagraph(
              'A recolha e tratamento de dados pessoais são realizados em conformidade com a Lei n.º 22/11, de 17 de Junho (Lei da Proteção de Dados Pessoais) e a nossa Política de Privacidade. Ao usar a Plataforma, o Utilizador consente com tal tratamento.',
            ),
            _buildSectionTitle('11. Lei Aplicável e Foro'),
            _buildParagraph(
              'Estes Termos e Condições são regidos e interpretados de acordo com as leis da República de Angola. Para a resolução de quaisquer litígios emergentes, as partes elegem o foro da Comarca de Luanda, com expressa renúncia a qualquer outro.',
            ),
            _buildSectionTitle('12. Alterações aos Termos'),
            _buildParagraph(
              'A Afercon Xpress reserva-se o direito de modificar estes Termos e Condições a qualquer momento. As alterações entrarão em vigor após a sua publicação na Plataforma. É responsabilidade do Utilizador rever os termos periodicamente.',
            ),
             _buildSectionTitle('13. Contacto'),
             _buildParagraph(
              'Para qualquer esclarecimento, por favor, entre em contacto connosco através do e-mail: suporte@aferconxpress.com.',
            ),
          ],
        ),
      ),
    );
  }
}
