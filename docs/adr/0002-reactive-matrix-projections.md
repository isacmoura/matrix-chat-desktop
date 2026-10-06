# ADR-0002 — Projeções reativas para salas e timeline

- Data: 2026-10-04

## Contexto

Lista de salas, timeline, sincronização e envio são fluxos contínuos. Consultas
periódicas iniciadas pelo Flutter criariam duplicação de estado e risco de
race conditions.

O `matrix-sdk-ui` oferece APIs de alto nível voltadas à interface, incluindo
`RoomListService`, baseado em Sliding Sync, e `Timeline`, que representa os itens
e estados de envio de uma sala.

## Decisão

Usar `matrix-sdk-ui` 0.19.1 para a lista de salas e a timeline, em conjunto com
`matrix-sdk` 0.19.1.

A camada de integração em Rust assina as atualizações produzidas pelo SDK,
converte seus tipos internos em modelos estáveis da aplicação e os expõe ao
Flutter como streams tipados por meio do Flutter Rust Bridge.

Serão expostas atualizações relacionadas a:

- sessão e autenticação;
- estado da sincronização;
- resumos das salas;
- itens e estados de envio da timeline da sala ativa.

## Validação

A compatibilidade foi confirmada com Rust 1.97.1 e Flutter Rust Bridge 2.12.0.
Os testes feitos foram:

- compilar `matrix-sdk` e `matrix-sdk-ui` na mesma biblioteca Rust;
- confirmar que as duas dependências resolvem para a versão 0.19.1;
- habilitar criptografia e SQLite embarcado;
- transportar um DTO por um stream Rust → Dart;
- executar o smoke test nativo no macOS.

## Consequências

### Positivas

- Evita reimplementar regras complexas de ordenação, deltas e estado de envio.
- Mantém uma única fonte de verdade no Rust.
- Permite atualização incremental da UI.

### Negativas

- `matrix-sdk-ui` evolui rapidamente e precisa ser versionado junto com o SDK.
- Streams exigem cancelamento e tratamento explícito de reconexão.
- Testes precisam controlar eventos assíncronos deterministamente.
