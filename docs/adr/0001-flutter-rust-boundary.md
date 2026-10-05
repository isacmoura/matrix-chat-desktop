# ADR-0001 — Fronteira Flutter–Rust orientada a DTOs

- Data: 2026-10-04

## Contexto

O desafio exige que toda comunicação Matrix seja feita em Rust pelo Matrix Rust
SDK, usando Flutter Rust Bridge para a integração. Expor diretamente objetos do
SDK ao Dart geraria acoplamento entre a interface e uma biblioteca externa, aumentaria o custo de
serialização e tornaria testes e atualizações mais frágeis e complicadas de manter.

## Decisão

Criar uma facade Rust pequena, assíncrona e orientada a casos de uso. A ponte
expõe somente DTOs e enums próprios da aplicação. O `matrix_sdk::Client` e demais
tipos do SDK permanecem privados no Rust e a aplicação Flutter é agnóstica a eles.

No Flutter, uma interface manual `MatrixGateway` encapsula o código gerado pelo
Flutter Rust Bridge. Nenhum ViewModel, Cubit ou widget importa diretamente a API
gerada.

## Consequências

### Positivas

- Reduz acoplamento com Matrix SDK e FRB.
- Contratos podem ser mockados em testes Dart.
- Erros e modelos ficam adequados à interface.
- Atualizações do SDK ficam concentradas no Rust, evitando retrabalho na aplicação inteira.

### Negativas

- Exige mapeamento explícito entre SDK, DTOs Rust e modelos Dart.
- Mudanças no contrato exigem gerar a ponte novamente.

## Alternativas rejeitadas

- Expor `Client` e `Room` como objetos opacos no Dart: preserva menos cópias, mas
  transfere ciclo de vida e detalhes do SDK para a camada errada (front/client).
- Implementar Matrix diretamente no Dart: viola requisito explícito do desafio.
- Criar um protocolo JSON genérico na ponte: perde segurança de tipos e desloca
  erros para runtime.
