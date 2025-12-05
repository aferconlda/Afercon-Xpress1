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

**Objetivo:** Implementar um fluxo de cancelamento de entregas "Em Progresso", que exige confirmação mútua entre o cliente e o motorista.

**Passos:**

1.  **Atualizar o Modelo de Dados:**
    *   Adicionar novos campos ao modelo `Delivery` (em `lib/models/delivery_model.dart`) para gerir o estado do cancelamento:
        *   `cancellationRequestedBy`: String (para armazenar quem iniciou o pedido: 'client' ou 'driver').
        *   `cancellationStatus`: String (para o estado: 'pending', 'confirmed').
        *   `cancellationReason`: String (opcional, para o motivo).

2.  **Modificar o Ecrã de Detalhes da Entrega (`lib/delivery_details_screen.dart`):**
    *   **Para o Iniciador (Cliente ou Motorista):**
        *   Adicionar um botão "Cancelar Entrega" visível apenas quando a entrega está "em progresso" e não há pedido de cancelamento pendente.
        *   Ao clicar, exibir um diálogo para confirmar o desejo de cancelar e, opcionalmente, inserir um motivo.
        *   Após a confirmação, atualizar o documento da entrega no Firestore, definindo `cancellationRequestedBy` e `cancellationStatus` para 'pending'.
        *   A interface deve mudar para indicar "Pedido de cancelamento enviado, a aguardar confirmação".
    *   **Para o Receptor (a outra parte):**
        *   Quando `cancellationStatus` for 'pending', a interface deve exibir uma notificação proeminente.
        *   Mostrar dois botões: "Confirmar Cancelamento" e "Recusar".
        *   **Se confirmar:** Atualizar o estado da entrega para "cancelled".
        *   **Se recusar:** Limpar os campos `cancellationRequestedBy` e `cancellationStatus` no Firestore, e a entrega volta ao normal.

3.  **Ajustar a Lógica de Listagem:**
    *   As entregas com estado "cancelled" devem ser movidas das listas "Em Progresso" para um histórico apropriado ou simplesmente filtradas.
