# ADR-0003 — Persistência segura da sessão

- Data: 2026-10-04

## Contexto

O aplicativo deve restaurar a sessão. Tokens Matrix e chaves do store são
segredos. Salvar a sessão em JSON puro ou preferências localmente é inadequado.

A restauração do Matrix Rust SDK exige reconstruir o cliente com o mesmo store
persistente usado no login. Sem isso, estado de salas e material criptográfico
podem ficar indisponíveis.

## Decisão

- O Rust é o dono da persistência da sessão.
- O SDK usa SQLite em um diretório privado da aplicação.
- Metadados e tokens necessários à restauração ficam no credential store do
  sistema operacional.
- A passphrase do SQLite store também fica no credential store.
- Senhas de usuário existem apenas em memória durante o login.
- A implementação usa a crate `keyring`, que no macOS delega o armazenamento
  seguro ao Keychain. Windows e Linux dependem, respectivamente, dos backends
  Credential Manager e Secret Service disponibilizados pela crate.
- Se o credential store não estiver disponível, o aplicativo não oferece
  restauração persistente; exige novo login em vez de gravar segredos sem
  proteção.
- Logout cancela sincronização, revoga/encerra a sessão quando possível, remove
  as credenciais locais. A remoção física do SQLite será tratada por um fluxo
  explícito de limpeza da conta; sem a passphrase removida, o store não pode ser
  reaberto pela aplicação.

## Consequências

### Positivas

- Tokens e passphrases não ficam em texto puro.
- A responsabilidade de sessão permanece ao lado do cliente Matrix.
- A política de fallback é segura por padrão.

### Negativas

- Integração com macOS Keychain, Windows Credential Manager e Secret Service do
  Linux precisa ser validada por plataforma.
- Uma futura limpeza física do store exige tratamento cuidadoso de arquivos em
  uso.
