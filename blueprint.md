
# Visão Geral do Afercon Xpress

O Afercon Xpress é uma aplicação Flutter desenhada para facilitar a conexão entre clientes que precisam de enviar encomendas e motoristas disponíveis para as transportar. A aplicação gere todo o fluxo, desde a publicação de uma nova entrega até à sua conclusão, com um sistema de autenticação e perfis de utilizador.

## Funcionalidades Implementadas

### Estilo e Design
- **Tema Visual Moderno:** Interface com um esquema de cores baseado em Azul Petróleo (`#008080`) e Verde Vibrante (`#00C853`), com suporte para **modo claro e escuro**.
- **Tipografia Profissional:** Utilização da fonte "Poppins" (via `google_fonts`) para uma leitura agradável e consistente.
- **Componentes Material 3:** A aplicação utiliza os componentes mais recentes do Material Design 3, garantindo um look and feel atual.
- **Layout Responsivo:** Ecrãs desenhados para se adaptarem a diferentes tamanhos, com uso de `Card` para uma apresentação organizada da informação.

### Arquitetura e Navegação
- **Gestão de Estado com Provider:** A gestão do tema e da autenticação do utilizador é feita de forma eficiente com o `provider`.
- **Navegação Declarativa com `go_router`:** Toda a navegação da aplicação é gerida pelo `go_router`, permitindo URLs limpas, passagem de parâmetros (como o ID da entrega) e um controlo de fluxo de autenticação robusto.
- **Serviço de Autenticação Centralizado (`AuthService`):** Um único serviço gere todas as interações com o Firebase Auth e Firestore (registo, login, logout, obtenção de dados do utilizador e das entregas), promovendo um código mais limpo e organizado.

### Funcionalidades Principais
- **Autenticação Completa:**
    - Registo de novos utilizadores (clientes ou motoristas) com nome, contacto, email e senha.
    - Login com email e senha.
    - Funcionalidade de "Esqueci a minha senha".
    - Verificação de email após o registo.
- **Fluxo de Entregas:**
    - **Publicação de Entregas (Cliente):** Um cliente autenticado pode publicar uma nova entrega através de um formulário detalhado, que inclui título, descrição, moradas de recolha/entrega, dados do destinatário e o valor a pagar.
    - **Lista de Entregas Disponíveis (Motorista):** Na `HomeScreen`, os motoristas podem ver uma lista de todas as entregas disponíveis, ordenadas das mais recentes para as mais antigas.
    - **Aceitar Entregas (Motorista):** Um motorista pode aceitar uma entrega, que passará para o estado "Em Progresso" e ficará associada ao seu perfil.
- **Ecrãs do Utilizador:**
    - **As Minhas Entregas (Cliente):** Um ecrã onde o cliente pode ver o estado de todas as entregas que publicou.
    - **As Minhas Entregas (Motorista):** Um ecrã onde o motorista pode ver as entregas que aceitou e que estão em andamento ou já foram concluídas.
- **Ecrã de Detalhes da Entrega:**
    - Ao tocar numa entrega em qualquer lista, o utilizador é levado para um ecrã de detalhes completo, que mostra:
        - Título, descrição e estado da entrega.
        - Percurso (morada de recolha e entrega).
        - Informação do destinatário.
        - Valor da entrega.
        - **Dados do Motorista:** Se a entrega já foi aceite, são mostrados os detalhes do motorista responsável (nome, veículo), com botões para **ligar ou enviar mensagem via WhatsApp**, facilitando a comunicação.

---

## Plano para a Tarefa Atual

**Objetivo:** Adicionar a recolha de informações do veículo do motorista no registo, exibir esses dados para o cliente e integrar os ecrãs de "Termos e Condições" e "Política de Privacidade".

**Passos:**

1.  **Atualizar o Modelo de Dados:**
    - Adicionar os campos `vehiclePlate` (matrícula) e `vehicleColor` (cor) ao modelo `AppUser` em `lib/models/user_model.dart`.
2.  **Modificar o Ecrã de Autenticação (`lib/auth_screen.dart`):**
    - Adicionar `TextFormField`s para "Matrícula do Veículo" e "Cor do Veículo" no formulário de registo.
    - Adicionar duas `CheckboxListTile` para a aceitação dos "Termos e Condições" e da "Política de Privacidade". A aceitação será obrigatória para o registo.
    - Adicionar links nos textos dos checkboxes que irão navegar para os respetivos ecrãs de políticas.
3.  **Criar Ecrãs de Políticas:**
    - Criar o ficheiro `lib/terms_screen.dart` com um texto padrão para os Termos e Condições da Afercon Xpress.
    - Criar o ficheiro `lib/privacy_policy_screen.dart` com um texto padrão para a Política de Privacidade.
4.  **Atualizar Rotas e Navegação:**
    - Adicionar as rotas `/terms` e `/privacy` no `main.dart` para os novos ecrãs.
5.  **Atualizar Serviço de Autenticação (`lib/auth_service.dart`):**
    - Modificar o método `signUp` para receber e guardar os novos dados do veículo (`vehiclePlate`, `vehicleColor`) no documento do utilizador no Firestore.
6.  **Exibir Dados do Veículo (`lib/delivery_details_screen.dart`):**
    - No ecrã de detalhes, quando uma entrega estiver em curso, carregar e exibir os dados completos do veículo do motorista (modelo, matrícula e cor) para que o cliente tenha mais informações e segurança.
