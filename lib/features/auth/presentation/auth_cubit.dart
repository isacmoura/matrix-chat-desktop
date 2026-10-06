import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:matrix_desktop/core/models/session_state.dart';
import 'package:matrix_desktop/features/auth/data/auth_repository.dart';

class AuthCubit extends Cubit<SessionState> {
  AuthCubit(this._repository, {required String appDataDirectory})
      : _appDataDirectory = appDataDirectory,
        super(const SessionUninitialized());

  final AuthRepository _repository;
  final String _appDataDirectory;
  StreamSubscription<SessionState>? _subscription;

  Future<void> start() async {
    if (_subscription != null) return;
    _subscription = _repository.watchSession().listen(
          _emitIfOpen,
          onError: (Object _) => _emitUnexpected(),
        );

    final initialized = await _guard(
      () => _repository.initialize(appDataDirectory: _appDataDirectory),
    );
    if (initialized) {
      await _guard(_repository.restoreSession);
    }
  }

  Future<void> login({
    required String homeserver,
    required String userId,
    required String password,
  }) async {
    if (state is SessionAuthenticating || state is SessionRestoring) return;
    await _guard(
      () => _repository.login(
        homeserver: homeserver.trim(),
        userId: userId.trim(),
        password: password,
      ),
    );
  }

  Future<void> logout() => _guard(_repository.logout);

  Future<bool> _guard(Future<bool> Function() command) async {
    try {
      return await command();
    } catch (_) {
      _emitUnexpected();
      return false;
    }
  }

  void _emitIfOpen(SessionState state) {
    if (!isClosed) emit(state);
  }

  void _emitUnexpected() => _emitIfOpen(
        const SessionFailed(
          AuthError(code: AuthErrorCode.unexpected, reference: 'auth-ui'),
        ),
      );

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
