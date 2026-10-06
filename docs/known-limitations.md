# Limitações conhecidas e itens não concluídos

## Estado da entrega

- [x] Cliente Flutter desktop com bridge Flutter–Rust.
- [x] Login, persistência segura, restauração de sessão e logout.
- [x] Sincronização, lista de salas, timeline e envio de mensagens de texto.
- [x] Testes unitários/widget no Flutter, testes unitários no Rust e smoke test
  nativo do bridge.
- [x] Teste manual autenticado contra um homeserver Matrix real.
- [ ] Teste de ponta a ponta para salas, timeline e envio com uma conta Matrix
  de teste.
- [ ] Validação de runtime no Windows e Linux.
- [ ] Integração contínua.

## Limitações funcionais

- A aplicação trata somente mensagens de texto simples.
- Não há criação, convite ou administração de salas.
- Não há Spaces, threads, reações, edição, remoção, anexos ou chamadas.
- Há uma única conta ativa por vez.
- A interface não expõe estado de envio, retry de mensagem nem status detalhado
  de reconexão.
- O logout remove os segredos do credential store e encerra a sessão remota em
  melhor esforço, mas não remove fisicamente o SQLite local. Sem a passphrase
  removida, esse banco não pode ser reaberto pela aplicação.
- Fluxos avançados de criptografia, como verificação de dispositivos e salas
  criptografadas em um cenário real, não foram validados de ponta a ponta.

## Plataformas

O desenvolvimento e as verificações automatizadas foram realizados no macOS.
Flutter, Rust e as configurações do projeto preservam o destino Windows/Linux,
mas esses sistemas ainda exigem validação de execução e do respectivo
credential store.
