# Estratégia de testes

## Objetivo

Este documento descreve a estratégia de testes utilizada neste projeto. Dada a limitação de tempo, a estratégia prioriza os riscos reais do fluxo obrigatório, em vez de buscar uma alta cobertura de testes que talvez não agreguem valor proporcional.

A prioridade é provar que a fronteira Flutter–Rust é estável, que sessão e
sincronização têm estados previsíveis e que o fluxo obrigatório funciona.

## Camadas

### Rust — testes unitários

- Conversão de eventos/salas do SDK para DTOs da aplicação.
- Taxonomia de erros, incluindo dados que nunca podem aparecer em mensagens/logs.
- Regras de ciclo de vida do `MatrixClientService`.
- Validação e normalização de homeserver/identificadores.
- Persistência e limpeza de metadados de sessão usando diretório temporário.
- Estado local de envio: `sending`, `sent`, `failed` e retry.

### Contrato Flutter–Rust

- Compilação do código gerado em CI.
- Round-trip dos DTOs e enums expostos.
- Propagação de `Result` Rust para erros tipados no Dart.
- Streams encerram/cancelam sem eventos posteriores.
- Smoke test nativo garantindo que Flutter chama uma operação Rust real.

### Dart — testes unitários

- `AuthCubit/ViewModel`: login, restauração, erro e logout.
- `RoomsCubit/ViewModel`: snapshots, deltas, seleção e busca local.
- `TimelineCubit/ViewModel`: troca de sala, cancelamento de stream, envio e retry.
- Repositórios com um `FakeMatrixGateway`, sem FFI.

### Flutter — widget tests

- Formulário de login e mensagens de erro.
- Lista de salas, seleção e indicador de não lidas.
- Timeline nos estados loading, vazia, conteúdo e reconectando.
- Composer desabilitado sem sala e envio por botão/Enter.
- Mensagem local nos estados de envio e falha.
- Logout retornando ao login.

### Integração

Um único fluxo principal obrigatório:

1. Inicializar com gateway falso determinístico.
2. Fazer login.
3. Receber e selecionar uma sala.
4. Receber mensagens.
5. Enviar uma mensagem e observar `sending → sent`.
6. Fazer logout.

## Verificações estáticas

- `flutter analyze`
- `flutter test`
- `cargo fmt --check`
- `cargo clippy --all-targets --all-features -- -D warnings`
- `cargo test`
- verificação de que o código FRB gerado está atualizado

## Referências

- [Flutter — visão geral de testes](https://docs.flutter.dev/testing/overview)
- [Flutter — testes de integração](https://docs.flutter.dev/testing/integration-tests)
- [Flutter — testes de plugins](https://docs.flutter.dev/testing/testing-plugins)
