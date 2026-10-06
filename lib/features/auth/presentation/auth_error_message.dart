import 'package:matrix_desktop/core/models/session_state.dart';

extension AuthErrorMessage on AuthError {
  String get message => switch (code) {
        AuthErrorCode.invalidHomeserver =>
          'Não foi possível validar o homeserver informado.',
        AuthErrorCode.networkUnavailable =>
          'Não foi possível conectar ao homeserver. Verifique sua conexão.',
        AuthErrorCode.invalidCredentials =>
          'ID, senha ou homeserver não conferem.',
        AuthErrorCode.rateLimited => _rateLimitedMessage(),
        AuthErrorCode.storageUnavailable =>
          'Não foi possível acessar o armazenamento seguro do sistema.',
        AuthErrorCode.sessionExpired => 'Sua sessão expirou. Entre novamente.',
        AuthErrorCode.unexpected =>
          'Não foi possível concluir a autenticação. Referência: $reference.',
      };

  String _rateLimitedMessage() {
    final seconds = retryAfter?.inSeconds;
    if (seconds == null || seconds <= 0) {
      return 'Muitas tentativas. Aguarde e tente novamente.';
    }
    return 'Muitas tentativas. Tente novamente em $seconds s.';
  }
}
