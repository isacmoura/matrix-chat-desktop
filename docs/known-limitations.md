# Limitações conhecidas e itens não concluídos

## Estado atual

- [x] Arquitetura e decisões iniciais propostas.
- [x] Projeto Flutter/Rust.
- [x] Integração Flutter Rust Bridge validada no macOS.
- [x] Compatibilidade entre `matrix-sdk` e `matrix-sdk-ui` validada.
- [x] Camada Rust de autenticação por senha, persistência segura e restauração
  implementada.
- [x] Autenticação integrada ao Flutter (`MatrixGateway`, `AuthRepository`,
  `AuthCubit`, tela de login, restauração na inicialização e logout).
- [ ] Login real contra um homeserver Matrix de teste.
- [ ] Validação do Keychain e dos backends Windows/Linux em execução de ponta a
  ponta.
- [ ] Lista de salas e timeline reais.
- [ ] Envio real de mensagens.
- [x] Testes automatizados iniciais em Flutter e Rust.
- [ ] CI.

## Limitações intencionais

- Somente mensagens de texto.
- Uma timeline ativa por vez.
- Sem criação, convite ou administração de salas.
- Sem Spaces, threads, reações, edição ou remoção de mensagens.
- Sem upload/download de anexos.
- Sem chamadas de voz/vídeo.
- Sem notificações nativas.
- Sem múltiplas contas simultâneas.
- Sem sincronização completa de preferências.
- Fluxos avançados de criptografia e verificação de dispositivos podem ser
  exibidos como limitação se não forem validados de ponta a ponta.

## Plataformas

Esta aplicação foi **desenvolvida e testada em macOS**. No entanto, a compatibilidade com outros sistemas operacionais como Windows e Linux foi mantida.
