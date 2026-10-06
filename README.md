# Matrix Desktop

Cliente de mensageria desktop em Flutter, cuja integração com o protocolo Matrix
será implementada em Rust por meio do Matrix Rust SDK e do Flutter Rust Bridge.

## Requisitos

- Flutter 3.22.2, gerenciado pelo [FVM](https://fvm.app/).
- Rust stable.
- Flutter Rust Bridge Codegen 2.12.0.
- Matrix Rust SDK e Matrix SDK UI 0.19.1.
- Ferramentas nativas da plataforma de destino.

O `cargo`, o `rustc` e o `rustup` precisam estar disponíveis no `PATH`. Em uma
instalação do Rust via Homebrew no macOS, execute:

```shell
export PATH="/opt/homebrew/opt/rustup/bin:$PATH"
```

Instale o gerador da ponte:

```shell
cargo install flutter_rust_bridge_codegen --version 2.12.0 --locked
```

## Configuração e execução

```shell
fvm install
fvm flutter pub get
flutter_rust_bridge_codegen generate
fvm flutter run -d macos
```

Substitua `macos` por `windows` ou `linux` ao executar na plataforma correspondente.

## Verificações

```shell
fvm flutter analyze
fvm flutter test
fvm flutter test integration_test/bridge_test.dart -d macos
cargo fmt --manifest-path rust/Cargo.toml -- --check
cargo test --manifest-path rust/Cargo.toml
```

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
