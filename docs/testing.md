# Estratégia de testes

## Critério adotado

O desafio prioriza os fluxos de maior risco: fronteira Flutter–Rust,
autenticação, persistência de sessão e comportamento da interface. A suíte não
usa uma conta Matrix nem um homeserver externo; por isso, não substitui a
validação manual ponta a ponta descrita nas limitações.

## Cobertura implementada

### Rust

- Validação de campos de login sem chamada de rede.
- Classificação de falhas de autenticação sem expor detalhes sensíveis.
- Serialização dos dados necessários para restaurar uma sessão.
- Geração de passphrase do store local.
- DTO de salas e contrato de status da ponte.

### Flutter

- `AuthCubit`: inicialização, restauração, login, erro, proteção contra login
  concorrente e logout.
- Widgets: validação do formulário, limpeza da senha, progresso, erro de
  autenticação, restauração e logout.
- Repositórios usam `FakeMatrixGateway`; os testes de UI não dependem de rede,
  Keychain ou FFI.

### Integração nativa

O smoke test em `integration_test/bridge_test.dart` inicializa o Rust por meio
do Flutter Rust Bridge, lê as versões do Matrix SDK e verifica a transição
inicial do stream de autenticação.

## Comandos

```shell
fvm flutter analyze
fvm flutter test
fvm flutter test integration_test/bridge_test.dart -d macos
PATH="/opt/homebrew/opt/rustup/bin:$PATH" cargo fmt --manifest-path rust/Cargo.toml -- --check
PATH="/opt/homebrew/opt/rustup/bin:$PATH" cargo clippy --manifest-path rust/Cargo.toml --all-targets --all-features -- -D warnings
PATH="/opt/homebrew/opt/rustup/bin:$PATH" cargo test --manifest-path rust/Cargo.toml
```

## Próximas validações recomendadas

1. Usar uma conta Matrix exclusiva de teste para login, reinício, restauração,
   lista de salas, leitura e envio.
2. Adicionar testes dos cubits de salas/timeline e de falha no envio.
3. Executar a mesma matriz no Windows e Linux em CI.
