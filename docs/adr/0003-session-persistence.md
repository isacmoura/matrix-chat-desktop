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
- Se o credential store não estiver disponível, o aplicativo não oferece
  restauração persistente; exige novo login em vez de gravar segredos sem
  proteção.
- Logout cancela sincronização, revoga/encerra a sessão quando possível, remove
  credenciais locais e elimina o store daquela conta de forma controlada.

## Consequências

### Positivas

- Tokens e passphrases não ficam em texto puro.
- A responsabilidade de sessão permanece ao lado do cliente Matrix.
- A política de fallback é segura por padrão.

### Negativas

- Integração com macOS Keychain, Windows Credential Manager e Secret Service do
  Linux precisa ser validada por plataforma.
- Logout e remoção de store exigem tratamento cuidadoso de arquivos em uso.
