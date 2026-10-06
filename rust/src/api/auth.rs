use std::{
    error::Error,
    fmt::Display,
    io,
    path::PathBuf,
    sync::{
        atomic::{AtomicU64, Ordering},
        Arc, OnceLock,
    },
};

use keyring::{Entry, Error as KeyringError};
use matrix_sdk::{
    authentication::matrix::MatrixSession,
    ruma::{OwnedDeviceId, OwnedUserId},
    store::RoomLoadSettings,
    Client, SessionTokens,
};
use matrix_sdk_ui::sync_service::SyncService;
use serde::{Deserialize, Serialize};
use tokio::sync::{broadcast, RwLock};

use crate::frb_generated::StreamSink;

const KEYRING_SERVICE: &str = "com.isacmoura.matrix-desktop";
const KEYRING_ACCOUNT: &str = "matrix-session";
const DEVICE_DISPLAY_NAME: &str = "Matrix Desktop";

static AUTH_RUNTIME: OnceLock<AuthRuntime> = OnceLock::new();
static FAILURE_SEQUENCE: AtomicU64 = AtomicU64::new(1);

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum AuthPhase {
    Uninitialized,
    Unauthenticated,
    RestoringSession,
    Authenticating,
    Authenticated,
    Failure,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum AuthFailureCode {
    InvalidHomeserver,
    NetworkUnavailable,
    InvalidCredentials,
    RateLimited,
    StorageUnavailable,
    SessionExpired,
    Unexpected,
}

#[derive(Clone, Debug)]
pub struct AuthFailure {
    pub code: AuthFailureCode,
    pub message: String,
    pub retry_after_ms: Option<i64>,
    pub reference: String,
}

#[derive(Clone, Debug)]
pub struct AuthenticatedSession {
    pub user_id: String,
    pub device_id: String,
    pub homeserver: String,
}

#[derive(Clone, Debug)]
pub struct AuthState {
    pub phase: AuthPhase,
    pub session: Option<AuthenticatedSession>,
    pub failure: Option<AuthFailure>,
}

impl AuthState {
    fn uninitialized() -> Self {
        Self {
            phase: AuthPhase::Uninitialized,
            session: None,
            failure: None,
        }
    }

    fn unauthenticated() -> Self {
        Self {
            phase: AuthPhase::Unauthenticated,
            session: None,
            failure: None,
        }
    }

    fn transient(phase: AuthPhase) -> Self {
        Self {
            phase,
            session: None,
            failure: None,
        }
    }

    fn authenticated(session: AuthenticatedSession) -> Self {
        Self {
            phase: AuthPhase::Authenticated,
            session: Some(session),
            failure: None,
        }
    }

    fn failure(failure: AuthFailure) -> Self {
        Self {
            phase: AuthPhase::Failure,
            session: None,
            failure: Some(failure),
        }
    }
}

struct AuthRuntime {
    config: RwLock<Option<AuthConfig>>,
    client: RwLock<Option<Client>>,
    sync_service: RwLock<Option<Arc<SyncService>>>,
    state: RwLock<AuthState>,
    states: broadcast::Sender<AuthState>,
}

impl AuthRuntime {
    fn new() -> Self {
        let (states, _) = broadcast::channel(16);
        Self {
            config: RwLock::new(None),
            client: RwLock::new(None),
            sync_service: RwLock::new(None),
            state: RwLock::new(AuthState::uninitialized()),
            states,
        }
    }
}

#[derive(Clone, Debug, Eq, PartialEq)]
struct AuthConfig {
    app_data_directory: PathBuf,
}

impl AuthConfig {
    fn store_directory(&self) -> PathBuf {
        self.app_data_directory.join("matrix-sdk")
    }
}

#[derive(Clone, Debug, Eq, PartialEq, Serialize, Deserialize)]
struct StoredSession {
    homeserver: String,
    user_id: String,
    device_id: String,
    access_token: String,
    refresh_token: Option<String>,
    store_passphrase: String,
}

impl StoredSession {
    fn matrix_session(&self) -> Result<MatrixSession, AuthFailure> {
        let user_id: OwnedUserId = self
            .user_id
            .parse()
            .map_err(|_| AuthFailure::invalid_session())?;
        let device_id: OwnedDeviceId = self.device_id.clone().into();

        Ok(MatrixSession {
            meta: matrix_sdk::SessionMeta { user_id, device_id },
            tokens: matrix_sdk::SessionTokens {
                access_token: self.access_token.clone(),
                refresh_token: self.refresh_token.clone(),
            },
        })
    }
}

impl AuthFailure {
    fn new(code: AuthFailureCode, message: impl Into<String>) -> Self {
        let sequence = FAILURE_SEQUENCE.fetch_add(1, Ordering::Relaxed);
        Self {
            code,
            message: message.into(),
            retry_after_ms: None,
            reference: format!("auth-{sequence}"),
        }
    }

    fn invalid_session() -> Self {
        Self::new(
            AuthFailureCode::SessionExpired,
            "A sessão armazenada não é mais válida. Entre novamente.",
        )
    }
}

fn runtime() -> &'static AuthRuntime {
    AUTH_RUNTIME.get_or_init(AuthRuntime::new)
}

fn session_entry() -> Result<Entry, AuthFailure> {
    Entry::new(KEYRING_SERVICE, KEYRING_ACCOUNT).map_err(|_| {
        AuthFailure::new(
            AuthFailureCode::StorageUnavailable,
            "Não foi possível acessar o armazenamento seguro do sistema.",
        )
    })
}

fn callback_error(message: &str) -> Box<dyn Error + Send + Sync> {
    Box::new(io::Error::other(message))
}

fn save_stored_session(session: &StoredSession) -> Result<(), AuthFailure> {
    let entry = session_entry()?;
    let serialized = serde_json::to_string(session).map_err(|_| {
        AuthFailure::new(
            AuthFailureCode::StorageUnavailable,
            "Não foi possível salvar a sessão no armazenamento seguro.",
        )
    })?;

    entry.set_password(&serialized).map_err(|_| {
        AuthFailure::new(
            AuthFailureCode::StorageUnavailable,
            "Não foi possível salvar a sessão no armazenamento seguro.",
        )
    })
}

fn configure_session_persistence(
    client: &Client,
    store_passphrase: String,
) -> Result<(), AuthFailure> {
    let passphrase_for_save = store_passphrase;
    client
        .set_session_callbacks(
            Box::new(|_| {
                let serialized = session_entry()
                    .map_err(|_| callback_error("secure session storage is unavailable"))?
                    .get_password()
                    .map_err(|_| callback_error("stored session is unavailable"))?;
                let stored: StoredSession = serde_json::from_str(&serialized)
                    .map_err(|_| callback_error("stored session is malformed"))?;

                Ok(SessionTokens {
                    access_token: stored.access_token,
                    refresh_token: stored.refresh_token,
                })
            }),
            Box::new(move |client| {
                let session = client
                    .matrix_auth()
                    .session()
                    .ok_or_else(|| callback_error("matrix session is unavailable"))?;
                let stored = StoredSession {
                    homeserver: client.homeserver().to_string(),
                    user_id: session.meta.user_id.to_string(),
                    device_id: session.meta.device_id.to_string(),
                    access_token: session.tokens.access_token,
                    refresh_token: session.tokens.refresh_token,
                    store_passphrase: passphrase_for_save.clone(),
                };

                save_stored_session(&stored)
                    .map_err(|_| callback_error("could not save refreshed session"))
            }),
        )
        .map_err(|_| {
            AuthFailure::new(
                AuthFailureCode::StorageUnavailable,
                "Não foi possível configurar a persistência da sessão.",
            )
        })
}

fn generate_store_passphrase() -> Result<String, AuthFailure> {
    let mut bytes = [0_u8; 32];
    getrandom::fill(&mut bytes).map_err(|_| {
        AuthFailure::new(
            AuthFailureCode::StorageUnavailable,
            "Não foi possível preparar o armazenamento local seguro.",
        )
    })?;

    Ok(bytes.iter().map(|byte| format!("{byte:02x}")).collect())
}

fn validate_login_input(
    homeserver: &str,
    user_id: &str,
    password: &str,
) -> Result<(), AuthFailure> {
    if homeserver.trim().is_empty() {
        return Err(AuthFailure::new(
            AuthFailureCode::InvalidHomeserver,
            "Informe um servidor Matrix.",
        ));
    }

    if user_id.trim().is_empty() || password.is_empty() {
        return Err(AuthFailure::new(
            AuthFailureCode::InvalidCredentials,
            "Informe usuário e senha.",
        ));
    }

    Ok(())
}

async fn current_state() -> AuthState {
    runtime().state.read().await.clone()
}

async fn publish(state: AuthState) -> AuthState {
    *runtime().state.write().await = state.clone();
    let _ = runtime().states.send(state.clone());
    state
}

async fn configured() -> Result<AuthConfig, AuthFailure> {
    runtime().config.read().await.clone().ok_or_else(|| {
        AuthFailure::new(
            AuthFailureCode::StorageUnavailable,
            "A autenticação ainda não foi inicializada.",
        )
    })
}

pub(crate) async fn active_client() -> Result<Client, String> {
    runtime()
        .client
        .read()
        .await
        .clone()
        .ok_or_else(|| "A sessão Matrix não está autenticada.".to_owned())
}

async fn start_sync_service(client: Client) -> Result<(), AuthFailure> {
    let service = SyncService::builder(client).build().await.map_err(|_| {
        AuthFailure::new(
            AuthFailureCode::Unexpected,
            "Não foi possível iniciar a sincronização das salas.",
        )
    })?;
    service.start().await;

    let previous = runtime()
        .sync_service
        .write()
        .await
        .replace(Arc::new(service));
    if let Some(previous) = previous {
        previous.stop().await;
    }

    Ok(())
}

async fn stop_sync_service() {
    let service = runtime().sync_service.write().await.take();
    if let Some(service) = service {
        service.stop().await;
    }
}

async fn build_client(homeserver: &str, store_passphrase: &str) -> Result<Client, AuthFailure> {
    let config = configured().await?;
    std::fs::create_dir_all(config.store_directory()).map_err(|_| {
        AuthFailure::new(
            AuthFailureCode::StorageUnavailable,
            "Não foi possível preparar o armazenamento local.",
        )
    })?;

    Client::builder()
        .server_name_or_homeserver_url(homeserver)
        .sqlite_store(config.store_directory(), Some(store_passphrase))
        .handle_refresh_tokens()
        .respect_login_well_known(true)
        .build()
        .await
        .map_err(classify_matrix_error)
}

fn classify_matrix_error(error: impl Display) -> AuthFailure {
    let text = error.to_string().to_ascii_lowercase();
    let code = if text.contains("m_unknown_token") || text.contains("unknown token") {
        AuthFailureCode::SessionExpired
    } else if text.contains("m_limit_exceeded") || text.contains("429") {
        AuthFailureCode::RateLimited
    } else if text.contains("m_forbidden")
        || text.contains("unauthorized")
        || text.contains("forbidden")
    {
        AuthFailureCode::InvalidCredentials
    } else if text.contains("error sending request")
        || text.contains("connect")
        || text.contains("dns")
        || text.contains("timeout")
        || text.contains("timed out")
    {
        AuthFailureCode::NetworkUnavailable
    } else if text.contains("invalid server") || text.contains("url") {
        AuthFailureCode::InvalidHomeserver
    } else {
        AuthFailureCode::Unexpected
    };

    let message = match code {
        AuthFailureCode::InvalidHomeserver => {
            "Não foi possível validar o servidor Matrix informado."
        }
        AuthFailureCode::InvalidCredentials => "Usuário ou senha inválidos.",
        AuthFailureCode::SessionExpired => "A sessão expirou. Entre novamente.",
        AuthFailureCode::RateLimited => "Muitas tentativas. Aguarde e tente novamente.",
        AuthFailureCode::NetworkUnavailable => "Não foi possível conectar ao servidor Matrix.",
        AuthFailureCode::StorageUnavailable => "Não foi possível acessar o armazenamento local.",
        AuthFailureCode::Unexpected => "Não foi possível concluir a autenticação.",
    };

    AuthFailure::new(code, message)
}

fn state_result(state: AuthState) -> Result<AuthState, String> {
    if let Some(failure) = &state.failure {
        return Err(failure.reference.clone());
    }

    Ok(state)
}

pub async fn initialize_auth(app_data_directory: String) -> Result<AuthState, String> {
    let directory = PathBuf::from(app_data_directory);
    if directory.as_os_str().is_empty() {
        let state = publish(AuthState::failure(AuthFailure::new(
            AuthFailureCode::StorageUnavailable,
            "O diretório de dados da aplicação é obrigatório.",
        )))
        .await;
        return state_result(state);
    }

    let config = AuthConfig {
        app_data_directory: directory,
    };
    let mut configured = runtime().config.write().await;
    if let Some(existing) = configured.as_ref() {
        if existing != &config {
            let state = publish(AuthState::failure(AuthFailure::new(
                AuthFailureCode::StorageUnavailable,
                "A autenticação já foi inicializada com outro diretório.",
            )))
            .await;
            return state_result(state);
        }
    }

    *configured = Some(config);
    drop(configured);

    Ok(publish(AuthState::unauthenticated()).await)
}

pub async fn login_with_password(
    homeserver: String,
    user_id: String,
    password: String,
) -> Result<AuthState, String> {
    if let Err(failure) = validate_login_input(&homeserver, &user_id, &password) {
        return state_result(publish(AuthState::failure(failure)).await);
    }

    if let Err(failure) = configured().await {
        return state_result(publish(AuthState::failure(failure)).await);
    }

    publish(AuthState::transient(AuthPhase::Authenticating)).await;
    let store_passphrase = match generate_store_passphrase() {
        Ok(passphrase) => passphrase,
        Err(failure) => return state_result(publish(AuthState::failure(failure)).await),
    };
    let client = match build_client(&homeserver, &store_passphrase).await {
        Ok(client) => client,
        Err(failure) => return state_result(publish(AuthState::failure(failure)).await),
    };
    if let Err(failure) = configure_session_persistence(&client, store_passphrase.clone()) {
        return state_result(publish(AuthState::failure(failure)).await);
    }

    let login = client
        .matrix_auth()
        .login_username(&user_id, &password)
        .initial_device_display_name(DEVICE_DISPLAY_NAME)
        .request_refresh_token()
        .await;
    let _ = password;

    if let Err(error) = login {
        return state_result(publish(AuthState::failure(classify_matrix_error(error))).await);
    }

    let matrix_session = match client.matrix_auth().session() {
        Some(session) => session,
        None => {
            return state_result(
                publish(AuthState::failure(AuthFailure::new(
                    AuthFailureCode::Unexpected,
                    "O servidor não retornou uma sessão válida.",
                )))
                .await,
            );
        }
    };
    let session = StoredSession {
        homeserver: client.homeserver().to_string(),
        user_id: matrix_session.meta.user_id.to_string(),
        device_id: matrix_session.meta.device_id.to_string(),
        access_token: matrix_session.tokens.access_token,
        refresh_token: matrix_session.tokens.refresh_token,
        store_passphrase,
    };

    if let Err(failure) = save_stored_session(&session) {
        return state_result(publish(AuthState::failure(failure)).await);
    }

    if let Err(failure) = start_sync_service(client.clone()).await {
        return state_result(publish(AuthState::failure(failure)).await);
    }
    *runtime().client.write().await = Some(client);
    Ok(publish(AuthState::authenticated(AuthenticatedSession {
        user_id: session.user_id,
        device_id: session.device_id,
        homeserver: session.homeserver,
    }))
    .await)
}

pub async fn restore_session() -> Result<AuthState, String> {
    if let Err(failure) = configured().await {
        return state_result(publish(AuthState::failure(failure)).await);
    }

    publish(AuthState::transient(AuthPhase::RestoringSession)).await;
    let entry = match session_entry() {
        Ok(entry) => entry,
        Err(failure) => return state_result(publish(AuthState::failure(failure)).await),
    };
    let serialized = match entry.get_password() {
        Ok(serialized) => serialized,
        Err(KeyringError::NoEntry) => return Ok(publish(AuthState::unauthenticated()).await),
        Err(_) => {
            return state_result(
                publish(AuthState::failure(AuthFailure::new(
                    AuthFailureCode::StorageUnavailable,
                    "Não foi possível ler a sessão armazenada.",
                )))
                .await,
            );
        }
    };
    let session: StoredSession = match serde_json::from_str(&serialized) {
        Ok(session) => session,
        Err(_) => {
            let _ = entry.delete_credential();
            return state_result(publish(AuthState::failure(AuthFailure::invalid_session())).await);
        }
    };
    let client = match build_client(&session.homeserver, &session.store_passphrase).await {
        Ok(client) => client,
        Err(failure) => return state_result(publish(AuthState::failure(failure)).await),
    };
    let matrix_session = match session.matrix_session() {
        Ok(session) => session,
        Err(failure) => return state_result(publish(AuthState::failure(failure)).await),
    };

    if let Err(error) = client
        .matrix_auth()
        .restore_session(matrix_session, RoomLoadSettings::default())
        .await
    {
        return state_result(publish(AuthState::failure(classify_matrix_error(error))).await);
    }
    if let Err(failure) = configure_session_persistence(&client, session.store_passphrase.clone()) {
        return state_result(publish(AuthState::failure(failure)).await);
    }

    if let Err(failure) = start_sync_service(client.clone()).await {
        return state_result(publish(AuthState::failure(failure)).await);
    }
    *runtime().client.write().await = Some(client);
    Ok(publish(AuthState::authenticated(AuthenticatedSession {
        user_id: session.user_id,
        device_id: session.device_id,
        homeserver: session.homeserver,
    }))
    .await)
}

pub async fn logout() -> Result<AuthState, String> {
    stop_sync_service().await;
    if let Some(client) = runtime().client.write().await.take() {
        let _ = client.matrix_auth().logout().await;
    }

    let entry = match session_entry() {
        Ok(entry) => entry,
        Err(failure) => return state_result(publish(AuthState::failure(failure)).await),
    };
    match entry.delete_credential() {
        Ok(()) | Err(KeyringError::NoEntry) => Ok(publish(AuthState::unauthenticated()).await),
        Err(_) => state_result(
            publish(AuthState::failure(AuthFailure::new(
                AuthFailureCode::StorageUnavailable,
                "Não foi possível remover a sessão armazenada.",
            )))
            .await,
        ),
    }
}

pub async fn watch_auth_state(sink: StreamSink<AuthState>) -> Result<(), String> {
    let mut receiver = runtime().states.subscribe();
    if sink.add(current_state().await).is_err() {
        return Ok(());
    }

    loop {
        match receiver.recv().await {
            Ok(state) => {
                if sink.add(state).is_err() {
                    return Ok(());
                }
            }
            Err(broadcast::error::RecvError::Lagged(_)) => {
                if sink.add(current_state().await).is_err() {
                    return Ok(());
                }
            }
            Err(broadcast::error::RecvError::Closed) => return Ok(()),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::{
        classify_matrix_error, generate_store_passphrase, validate_login_input, AuthFailureCode,
        StoredSession,
    };

    #[test]
    fn rejects_missing_login_input_without_contacting_a_homeserver() {
        let failure = validate_login_input("", "user", "password").unwrap_err();

        assert_eq!(failure.code, AuthFailureCode::InvalidHomeserver);
    }

    #[test]
    fn rejects_missing_password_without_contacting_a_homeserver() {
        let failure = validate_login_input("matrix.org", "user", "").unwrap_err();

        assert_eq!(failure.code, AuthFailureCode::InvalidCredentials);
    }

    #[test]
    fn persists_every_value_required_to_restore_a_session() {
        let session = StoredSession {
            homeserver: "https://matrix.example".to_owned(),
            user_id: "@isac:example".to_owned(),
            device_id: "DESKTOP".to_owned(),
            access_token: "access-token".to_owned(),
            refresh_token: Some("refresh-token".to_owned()),
            store_passphrase: "database-key".to_owned(),
        };

        let serialized = serde_json::to_string(&session).unwrap();
        let restored: StoredSession = serde_json::from_str(&serialized).unwrap();

        assert_eq!(restored, session);
    }

    #[test]
    fn creates_a_non_empty_random_database_passphrase() {
        let first = generate_store_passphrase().unwrap();
        let second = generate_store_passphrase().unwrap();

        assert_eq!(first.len(), 64);
        assert_ne!(first, second);
    }

    #[test]
    fn maps_network_errors_without_exposing_the_underlying_error() {
        let failure = classify_matrix_error("DNS lookup failed for private.example");

        assert_eq!(failure.code, AuthFailureCode::NetworkUnavailable);
        assert!(!failure.message.contains("private.example"));
    }

    #[test]
    fn treats_request_failures_mentioning_an_url_as_network_errors() {
        let failure = classify_matrix_error(
            "error sending request for url (https://matrix.example/_matrix/client/versions)",
        );

        assert_eq!(failure.code, AuthFailureCode::NetworkUnavailable);
    }

    #[test]
    fn maps_matrix_error_codes_before_generic_heuristics() {
        let forbidden = classify_matrix_error(
            "the server returned an error: [403 / M_FORBIDDEN] Invalid username or password",
        );
        let expired = classify_matrix_error("[401 / M_UNKNOWN_TOKEN] Invalid access token");
        let limited = classify_matrix_error("[429 / M_LIMIT_EXCEEDED] Too many requests");

        assert_eq!(forbidden.code, AuthFailureCode::InvalidCredentials);
        assert_eq!(expired.code, AuthFailureCode::SessionExpired);
        assert_eq!(limited.code, AuthFailureCode::RateLimited);
    }
}
