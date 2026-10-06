sealed class SessionState {
  const SessionState();
}

final class SessionUninitialized extends SessionState {
  const SessionUninitialized();
}

final class SessionRestoring extends SessionState {
  const SessionRestoring();
}

final class SessionUnauthenticated extends SessionState {
  const SessionUnauthenticated();
}

final class SessionAuthenticating extends SessionState {
  const SessionAuthenticating();
}

final class SessionAuthenticated extends SessionState {
  const SessionAuthenticated(this.session);

  final UserSession session;

  @override
  bool operator ==(Object other) =>
      other is SessionAuthenticated && other.session == session;

  @override
  int get hashCode => session.hashCode;
}

final class SessionFailed extends SessionState {
  const SessionFailed(this.error);

  final AuthError error;

  @override
  bool operator ==(Object other) =>
      other is SessionFailed && other.error == error;

  @override
  int get hashCode => error.hashCode;
}

final class UserSession {
  const UserSession({
    required this.userId,
    required this.deviceId,
    required this.homeserver,
  });

  final String userId;
  final String deviceId;
  final String homeserver;

  @override
  bool operator ==(Object other) =>
      other is UserSession &&
      other.userId == userId &&
      other.deviceId == deviceId &&
      other.homeserver == homeserver;

  @override
  int get hashCode => Object.hash(userId, deviceId, homeserver);
}

enum AuthErrorCode {
  invalidHomeserver,
  networkUnavailable,
  invalidCredentials,
  rateLimited,
  storageUnavailable,
  sessionExpired,
  unexpected,
}

final class AuthError {
  const AuthError({
    required this.code,
    required this.reference,
    this.retryAfter,
  });

  final AuthErrorCode code;
  final String reference;
  final Duration? retryAfter;

  @override
  bool operator ==(Object other) =>
      other is AuthError &&
      other.code == code &&
      other.reference == reference &&
      other.retryAfter == retryAfter;

  @override
  int get hashCode => Object.hash(code, reference, retryAfter);
}
