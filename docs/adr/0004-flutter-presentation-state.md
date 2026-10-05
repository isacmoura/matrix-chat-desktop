# ADR-0004 — Presentation state por feature

- Data: 2026-10-04

## Contexto

O Flutter precisa combinar snapshots e streams provenientes do Rust com estado
efêmero de interface: sala selecionada, busca, loading, erro e texto do composer.
Um controlador global concentraria responsabilidades demais; ao mesmo tempo, uma
camada de use case para cada ação adicionaria boilerplate incompatível com o desafio (overengineering).

## Decisão

- Organizar a aplicação por feature.
- Usar um Cubit/ViewModel por fluxo principal: `Auth`, `Rooms` e `Timeline`.
- Expor estados imutáveis e uniões fechadas para loading/success/failure.
- Os repositórios são o ponto de acesso aos dados Matrix no Dart e encapsulam o MatrixGateway; o estado Matrix permanece sob responsabilidade do Rust.
- Não criar uma camada de use cases por padrão; introduzi-la somente quando uma
  regra combinar repositórios, for reutilizada ou exceder a responsabilidade do
  ViewModel.
- Usar composição manual de dependências inicialmente.
- Alternar login/conversas pela sessão na raiz, sem adicionar um pacote de
  roteamento para duas telas.

## Consequências

### Positivas

- Estado assíncrono explícito e facilmente testável.
- Widgets permanecem focados em apresentação.
- Menos abstrações e dependências.
- Cada assinatura de stream possui um dono claro.

### Negativas

- Exige disciplina para cancelar subscriptions no fechamento de cada Cubit.

## Alternativas consideradas

- `setState`/`ValueNotifier` em cada tela: suficiente para protótipo, mas frágil
  para múltiplos streams e erros concorrentes.
- Um BLoC global: simplifica injeção, mas mistura ciclo de sessão, salas e
  timeline.
- Clean Architecture completa com use case por operação: testável, porém cria
  mais arquivos que comportamento neste escopo.
