import 'package:flutter_test/flutter_test.dart';
import 'package:matrix_desktop/core/models/session_state.dart';
import 'package:matrix_desktop/features/auth/data/auth_repository.dart';
import 'package:matrix_desktop/features/auth/presentation/auth_cubit.dart';

import '../../support/fake_matrix_gateway.dart';

void main() {
  late FakeMatrixGateway gateway;
  late AuthCubit cubit;

  AuthCubit buildCubit({String directory = '/app-data'}) => AuthCubit(
        AuthRepository(gateway),
        appDataDirectory: directory,
      );

  setUp(() => gateway = FakeMatrixGateway());
  tearDown(() => cubit.close());

  test('initializes Rust and attempts to restore the session on start',
      () async {
    cubit = buildCubit();

    await cubit.start();
    await pumpEventQueue();

    expect(gateway.calls, ['initializeAuth:/app-data', 'restoreSession']);
    expect(cubit.state, isA<SessionUnauthenticated>());
  });

  test('restores a persisted session', () async {
    const session = UserSession(
      userId: '@isac:matrix.org',
      deviceId: 'DEVICE',
      homeserver: 'https://matrix.org/',
    );
    gateway.storedSession = session;
    cubit = buildCubit();

    await cubit.start();
    await pumpEventQueue();

    expect(cubit.state, const SessionAuthenticated(session));
  });

  test('does not restore when initialization fails', () async {
    cubit = buildCubit(directory: '');

    await cubit.start();
    await pumpEventQueue();

    expect(gateway.calls, ['initializeAuth:']);
    expect(
      cubit.state,
      isA<SessionFailed>().having(
        (s) => s.error.code,
        'code',
        AuthErrorCode.storageUnavailable,
      ),
    );
  });

  test('logs in with trimmed identifiers and the raw password', () async {
    cubit = buildCubit();
    await cubit.start();

    await cubit.login(
      homeserver: ' https://matrix.org ',
      userId: ' @isac:matrix.org ',
      password: ' secret ',
    );
    await pumpEventQueue();

    expect(gateway.calls.last, 'login:https://matrix.org:@isac:matrix.org');
    expect(gateway.lastPassword, ' secret ');
    expect(cubit.state, isA<SessionAuthenticated>());
  });

  test('surfaces classified login failures from the stream', () async {
    gateway.loginFailure = AuthErrorCode.invalidCredentials;
    cubit = buildCubit();
    await cubit.start();

    await cubit.login(homeserver: 'matrix.org', userId: 'isac', password: 'x');
    await pumpEventQueue();

    expect(
      cubit.state,
      isA<SessionFailed>().having(
        (s) => s.error.code,
        'code',
        AuthErrorCode.invalidCredentials,
      ),
    );
  });

  test('ignores a second login while one is in progress', () async {
    gateway.holdLogin = true;
    cubit = buildCubit();
    await cubit.start();
    await pumpEventQueue();

    final first =
        cubit.login(homeserver: 'matrix.org', userId: 'isac', password: 'x');
    await pumpEventQueue();
    await cubit.login(homeserver: 'matrix.org', userId: 'isac', password: 'x');
    gateway.completeLogin();
    await first;

    expect(gateway.calls.where((c) => c.startsWith('login')), hasLength(1));
  });

  test('returns to unauthenticated after logout', () async {
    cubit = buildCubit();
    await cubit.start();
    await cubit.login(homeserver: 'matrix.org', userId: 'isac', password: 'x');

    await cubit.logout();
    await pumpEventQueue();

    expect(cubit.state, isA<SessionUnauthenticated>());
    expect(gateway.storedSession, isNull);
  });
}
