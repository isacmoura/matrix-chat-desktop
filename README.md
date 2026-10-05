# Matrix Desktop

Cliente de mensageria desktop desenvolvido em Flutter com integração ao protocolo Matrix. A integração com Rust é implementada por meio do Matrix Rust SDK e integrada ao Flutter com Flutter Rust Bridge.

## Documentação

- [Arquitetura](docs/architecture.md)
- [Estratégia de testes](docs/testing.md)
- [Limitações conhecidas](docs/known-limitations.md)
- [Índice de decisões arquiteturais](docs/adr/README.md)

## Escopo

- Autenticação em um homeserver Matrix.
- Restauração segura da sessão.
- Listagem e seleção de salas.
- Visualização e envio de mensagens de texto.
- Atualização reativa das conversas.
- Logout.
- Execução em aplicação desktop macOS, Windows e Linux.
