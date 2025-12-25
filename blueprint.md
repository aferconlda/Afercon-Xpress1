# Blueprint do Projeto Afercon Xpress

## Visão Geral

Este documento serve como a planta para o desenvolvimento do aplicativo Afercon Xpress, um intermediário de entregas via motoboy. Ele detalha a arquitetura, funcionalidades, design e os planos de implementação.

## Arquitetura e Tecnologia

*   **Framework:** Flutter
*   **Backend:** Firebase (Authentication, Firestore, Storage, Cloud Functions)
*   **Gerenciamento de Estado:** Provider
*   **Fonte:** Google Fonts (Oswald, Roboto, Open Sans)

## Funcionalidades Implementadas

*   **Autenticação de Utilizador:**
    *   Registo de Cliente e Motorista (com recolha de dados do veículo).
    *   Login com E-mail e Senha.
    *   Verificação de E-mail.
    *   Recuperação de Senha.
*   **Perfil do Utilizador:**
    *   Visualização e edição de perfil (Nome, Telemóvel, Foto).
*   **Sistema de Entregas:**
    *   Criação de novos pedidos de entrega (detalhes do item, local de recolha/entrega, preço).
    *   Listagem de entregas disponíveis para motoristas.
    *   Aceitação de entregas por motoristas.
    *   Visualização de entregas "Em Progresso" e "Concluídas".
    *   Fluxo de cancelamento de entregas com confirmação mútua.
*   **Pagamento de Comissões (Motoristas):**
    *   Após a conclusão da entrega, o motorista visualiza os dados bancários da Afercon Lda para pagamento da comissão de 10%.
    *   Disponibiliza um atalho para enviar o comprovativo de pagamento via WhatsApp.
*   **Navegação e Ecrãs:**
    *   Ecrã de Início (Home).
    *   Ecrãs de "Termos e Condições" e "Política de Privacidade".
    *   Ecrã de detalhes da entrega.
*   **Notificações:**
    *   Configuração básica do Firebase Messaging.

## Estilo e Design

*   **Tema:** Material 3 com esquema de cores baseado em `Colors.deepPurple`.
*   **Modos:** Suporte para Light e Dark Mode com um seletor.
*   **Tipografia:**
    *   `displayLarge`: Oswald
    *   `titleLarge`: Roboto
    *   `bodyMedium`: Open Sans
*   **Componentes:** Uso de `ElevatedButton`, `AppBar`, etc., com estilos centralizados no `ThemeData`.

---

## Plano para a Tarefa Atual

**Objetivo:** Implementar o fluxo de pagamento de comissão para o motorista após a confirmação do recebimento pelo cliente.

**Passos:**

1.  **Modificar o Ecrã de Detalhes da Entrega (`lib/delivery_details_screen.dart`):**
    *   Verificar se o utilizador é o motorista e se o estado da entrega é "Concluída".
    *   Se as condições forem verdadeiras, exibir um novo card (`_CommissionPaymentInfo`) com as seguintes informações:
        *   Dados bancários da Afercon Lda (IBAN: `0055.0000.3951.3329.1016.7`).
        *   Instruções para o pagamento da comissão de 10%.
        *   Um botão para abrir o WhatsApp (`+244945100502`) com uma mensagem pré-definida para o envio do comprovativo.

2.  **Ajustar a Visibilidade dos Componentes:**
    *   Ocultar a barra de ações inferior (`_ActionBottomBar`) e as opções de cancelamento quando a entrega estiver no estado "Concluída" para evitar ações desnecessárias e manter a interface limpa.
