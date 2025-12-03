
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
        title: const Text('Política de Privacidade'),
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
              'Política de Privacidade da Afercon Xpress',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
             const SizedBox(height: 12),
            const Text(
              'Última atualização: 24 de Julho de 2024',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            _buildSectionTitle('1. Introdução'),
            _buildParagraph(
              'A Afercon Xpress, no cumprimento da Lei n.º 22/11, de 17 de Junho (Lei da Proteção de Dados Pessoais), compromete-se a garantir a privacidade e a proteção dos dados pessoais dos seus Utilizadores (Clientes e Motoristas). Esta política explica como recolhemos, utilizamos, partilhamos e protegemos os seus dados.',
            ),
            _buildSectionTitle('2. Responsável pelo Tratamento'),
            _buildParagraph(
              'O responsável pelo tratamento dos seus dados é a Afercon Xpress, com e-mail de contacto: suporte@aferconxpress.com.',
            ),
            _buildSectionTitle('3. Dados Pessoais Recolhidos'),
            _buildParagraph(
              'Recolhemos os seguintes dados:\n• Informações de Identificação: Nome completo, número de telemóvel, endereço de e-mail.\n• Informações para Motoristas: Adicionalmente, recolhemos dados da carta de condução, matrícula e modelo do veículo, cor, e registo criminal para verificação de elegibilidade.\n• Dados de Localização: Recolhemos dados de localização em tempo real (via GPS) do Motorista durante uma entrega ativa e do Cliente (endereços de recolha/entrega) para permitir a funcionalidade do serviço.\n• Dados de Transação: Detalhes sobre as entregas solicitadas, incluindo os itens (descrição), valores e datas.',
            ),
             _buildSectionTitle('4. Finalidade do Tratamento dos Dados'),
            _buildParagraph(
              'Os seus dados são utilizados para:\n• Gestão da Plataforma: Criar e gerir a sua conta de utilizador.\n• Prestação do Serviço: Facilitar a conexão entre Clientes e Motoristas, permitir o seguimento da entrega em tempo real e processar pagamentos.\n• Segurança: Verificar a identidade e a elegibilidade dos Motoristas e prevenir atividades fraudulentas.\n• Comunicação: Enviar notificações sobre o estado das suas entregas e outras comunicações relevantes sobre o serviço.\n• Melhoria do Serviço: Analisar dados de uso de forma agregada e anónima para melhorar a experiência na aplicação.',
            ),

            _buildSectionTitle('5. Partilha de Dados'),
            _buildParagraph(
              'Os seus dados pessoais apenas são partilhados nas seguintes circunstâncias:\n• Entre Cliente e Motorista: O nome do Cliente e os endereços de recolha/entrega são partilhados com o Motorista que aceita o serviço. O nome, a fotografia e os detalhes do veículo do Motorista são partilhados com o Cliente.\n• Cumprimento da Lei: Poderemos partilhar dados com autoridades judiciais ou administrativas mediante uma ordem legal.\n• A Afercon Xpress não vende, aluga ou cede os seus dados pessoais a terceiros para fins de marketing.',
            ),
            _buildSectionTitle('6. Segurança dos Dados'),
            _buildParagraph(
              'Implementamos medidas técnicas e organizativas adequadas para proteger os seus dados contra acesso não autorizado, alteração, divulgação ou destruição. Isto inclui o uso de encriptação e controlos de acesso restritos.',
            ),

            _buildSectionTitle('7. Direitos do Titular dos Dados'),
            _buildParagraph(
              'Nos termos da lei, o Utilizador tem o direito de:\n• Aceder: Solicitar o acesso aos seus dados pessoais.\n• Retificar: Solicitar a correção de dados incorretos ou incompletos.\n• Opor-se: Opor-se ao tratamento dos seus dados para certas finalidades.\n• Limitar: Solicitar a limitação do tratamento dos seus dados.\n• Apagar: Solicitar a eliminação dos seus dados (direito ao esquecimento), salvaguardando as obrigações legais de conservação de dados.\nPara exercer estes direitos, por favor, contacte-nos através do e-mail fornecido.',
            ),

            _buildSectionTitle('8. Conservação dos Dados'),
            _buildParagraph(
              'Os seus dados são conservados apenas pelo período necessário para cumprir as finalidades para as quais foram recolhidos, incluindo para fins de cumprimento de obrigações legais (por exemplo, fiscais).',
            ),

            _buildSectionTitle('9. Alterações à Política de Privacidade'),
             _buildParagraph(
              'Reservamo-nos o direito de alterar esta Política de Privacidade. Qualquer alteração será comunicada através da Plataforma ou por e-mail.',
            ),
          ],
        ),
      ),
    );
  }
}
