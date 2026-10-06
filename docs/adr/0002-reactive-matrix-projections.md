# ADR-0002 — Projeções reativas para salas e timeline

- Data: 2026-10-04

## Contexto

Lista de salas, timeline, sincronização e envio são fluxos contínuos. Consultas
periódicas iniciadas pelo Flutter criariam duplicação de estado e risco de
race conditions.

O `matrix-sdk-ui` oferece APIs de alto nível voltadas à interface. Nesta
entrega, `SyncService` mantém o cliente sincronizado e `Timeline` representa os
itens de uma sala. A lista é projetada a partir das salas carregadas pelo
`matrix-sdk` e de seu `rooms_stream`.

## Decisão

Usar `matrix-sdk-ui` 0.19.1 para sincronização e timeline, em conjunto com
`matrix-sdk` 0.19.1. Não usar `RoomListService` nesta primeira entrega.

A camada de integração em Rust assina as atualizações produzidas pelo SDK,
converte seus tipos internos em modelos estáveis da aplicação e os expõe ao
Flutter como streams tipados por meio do Flutter Rust Bridge.

Serão expostas atualizações relacionadas a:

- sessão e autenticação;
- estado da sincronização;
- resumos das salas;
- itens da timeline da sala ativa.

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

- Evita reimplementar a sincronização e a projeção de itens de timeline.
- Mantém uma única fonte de verdade no Rust.
- Permite atualização incremental da UI.

### Negativas

- `matrix-sdk-ui` evolui rapidamente e precisa ser versionado junto com o SDK.
- Streams exigem cancelamento e tratamento explícito de reconexão.
- Testes precisam controlar eventos assíncronos deterministamente.
- O estado visual de envio e retry permanece fora do escopo atual.
