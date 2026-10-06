import 'package:matrix_desktop/bridge/matrix_gateway.dart';
import 'package:matrix_desktop/core/models/session_state.dart';

final class AuthRepository {
  const AuthRepository(this._gateway);

  final MatrixGateway _gateway;

  Stream<SessionState> watchSession() => _gateway.watchSession();

  Future<bool> initialize({required String appDataDirectory}) =>
      _gateway.initializeAuth(appDataDirectory: appDataDirectory);

  Future<bool> restoreSession() => _gateway.restoreSession();

  Future<bool> login({
    required String homeserver,
    required String userId,
    required String password,
  }) =>
      _gateway.login(
        homeserver: homeserver,
        userId: userId,
        password: password,
      );

  Future<bool> logout() => _gateway.logout();
}
