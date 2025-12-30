
# Blueprint: App de Finanças Pessoais

## Visão Geral

Este documento descreve o design, os recursos e o plano de implementação de um aplicativo de finanças pessoais desenvolvido em Flutter. O objetivo é criar uma ferramenta bonita, intuitiva e acessível para ajudar os usuários a gerenciar suas finanças.

## Design e Estilo

*   **Tema:** Moderno, com um esquema de cores vibrante baseado no Material 3.
*   **Tipografia:** Utiliza `google_fonts` para uma aparência limpa e legível.
*   **Componentes:** Uso de componentes modernos do Material, como `Card`, `ElevatedButton` e ícones expressivos para uma navegação clara.
*   **Layout:** Responsivo, garantindo uma ótima experiência tanto em dispositivos móveis quanto na web.

---

## Funcionalidades Implementadas

*   **Estrutura Inicial:**
    *   Configuração do projeto Flutter.
    *   Implementação de um tema personalizável com suporte a modo claro e escuro.
    *   Criação da tela de login inicial com um design visualmente atraente.
*   **Assinatura de App (Android):**
    *   Criação de uma chave de assinatura (`upload-keystore.jks`).
    *   Configuração do `build.gradle` para assinar automaticamente as versões de release (APK e App Bundle).
    *   Geração bem-sucedida de APKs e App Bundles assinados e prontos para a Google Play Store.

---

## Plano de Implementação Atual: Termos e Privacidade

**Objetivo:** Adicionar a exibição e o aceite dos "Termos e Condições" e da "Política de Privacidade" na tela de registro.

**Passos:**

1.  **Criar Telas de Conteúdo:**
    *   Desenvolver um novo arquivo `lib/terms_screen.dart` para exibir o conteúdo dos Termos e Condições.
    *   Desenvolver um novo arquivo `lib/privacy_policy_screen.dart` para exibir o conteúdo da Política de Privacidade.
    *   Ambas as telas terão um layout simples com um `AppBar` e um texto rolável contendo o conteúdo (inicialmente, um texto de exemplo).

2.  **Atualizar a Tela de Registro:**
    *   Localizar o arquivo da tela de registro (provavelmente `lib/screens/registration_screen.dart`).
    *   Adicionar um `Checkbox` para que o usuário possa marcar o aceite.
    *   Ao lado do checkbox, adicionar um texto como "Eu li e aceito os [Termos e Condições](link) e a [Política de Privacidade](link)".
    *   Tornar os trechos "Termos e Condições" e "Política de Privacidade" clicáveis.
    *   Ao clicar, navegar para as respectivas telas (`TermsScreen` e `PrivacyPolicyScreen`).

3.  **Lógica de Negócio:**
    *   Manter o estado do `Checkbox` (marcado/desmarcado).
    *   O botão de "Registrar" ficará desabilitado enquanto o `Checkbox` não estiver marcado.
    *   Quando o usuário marcar a caixa, o botão de registro se tornará funcional.
