# Matrix Desktop

Cliente desktop de mensageria Matrix construído em Flutter. O protocolo Matrix,
o armazenamento da sessão e a sincronização ficam no Rust, por meio do Matrix
Rust SDK; o Flutter consome uma API própria através do Flutter Rust Bridge.

## O que está implementado

- Login por homeserver, ID Matrix e senha.
- Persistência segura dos tokens e da passphrase do banco no armazenamento de
  credenciais do sistema operacional.
- Restauração de sessão e logout.
- Sincronização de salas, listagem, seleção e contagem de não lidas.
- Timeline de mensagens de texto da sala selecionada e envio de texto.
- Interface desktop para macOS, Windows e Linux.

As limitações de validação e de escopo estão registradas em
[Limitações conhecidas](docs/known-limitations.md).

## Requisitos

- Flutter 3.22.2, gerenciado pelo [FVM](https://fvm.app/).
- Rust stable.
- Flutter Rust Bridge Codegen 2.12.0.
- Ferramentas nativas da plataforma de destino.

Em instalações do Rust via Homebrew no macOS, disponibilize as ferramentas no
`PATH` antes dos comandos Rust:

```shell
export PATH="/opt/homebrew/opt/rustup/bin:$PATH"
```

Instale o gerador do bridge uma vez:

```shell
cargo install flutter_rust_bridge_codegen --version 2.12.0 --locked
```

## Configuração e execução

```shell
fvm install
fvm flutter pub get
PATH="/Users/isacmoura/.cargo/bin:/opt/homebrew/opt/rustup/bin:$PATH" flutter_rust_bridge_codegen generate
fvm flutter run -d macos
```

Substitua `macos` por `windows` ou `linux` na plataforma desejada. Arquivos em
`lib/bridge/generated/` e `rust/src/frb_generated.rs` são gerados; não devem ser
editados manualmente.

## Verificações

```shell
fvm flutter analyze
fvm flutter test
fvm flutter test integration_test/bridge_test.dart -d macos
PATH="/opt/homebrew/opt/rustup/bin:$PATH" cargo fmt --manifest-path rust/Cargo.toml -- --check
PATH="/opt/homebrew/opt/rustup/bin:$PATH" cargo clippy --manifest-path rust/Cargo.toml --all-targets --all-features -- -D warnings
PATH="/opt/homebrew/opt/rustup/bin:$PATH" cargo test --manifest-path rust/Cargo.toml
```

## Documentação

- [Arquitetura](docs/architecture.md)
- [Estratégia e cobertura de testes](docs/testing.md)
- [Limitações conhecidas](docs/known-limitations.md)
- [Decisões arquiteturais](docs/adr/README.md)
