import 'dart:async';

import 'package:matrix_desktop/bridge/matrix_gateway.dart';
import 'package:matrix_desktop/core/models/matrix_sdk_status.dart';
import 'package:matrix_desktop/core/models/session_state.dart';
import 'package:matrix_desktop/core/models/room_summary.dart';
import 'package:matrix_desktop/core/models/timeline_message.dart';

class FakeMatrixGateway implements MatrixGateway {
  FakeMatrixGateway({this.storedSession});

  UserSession? storedSession;

  AuthErrorCode? loginFailure;

  bool holdLogin = false;

  final _states = StreamController<SessionState>.broadcast();
  SessionState _current = const SessionUninitialized();
  Completer<void>? _pendingLogin;

  final calls = <String>[];
  String? lastPassword;

  void _publish(SessionState state) {
    _current = state;
    _states.add(state);
  }

  void completeLogin() => _pendingLogin?.complete();

  @override
  Future<void> initialize() async {}

  @override
  String bridgeStatus() => 'Ponte Flutter–Rust pronta';

  @override
  Stream<MatrixSdkStatus> watchMatrixSdkStatus() => Stream.value(
        const MatrixSdkStatus(matrixSdk: '0.19.1', matrixSdkUi: '0.19.1'),
      );

  @override
  Future<bool> initializeAuth({required String appDataDirectory}) async {
    calls.add('initializeAuth:$appDataDirectory');
    if (appDataDirectory.isEmpty) {
      _publish(
        const SessionFailed(
          AuthError(code: AuthErrorCode.storageUnavailable, reference: 'a-1'),
        ),
      );
      return false;
    }
    _publish(const SessionUnauthenticated());
    return true;
  }

  @override
  Future<bool> restoreSession() async {
    calls.add('restoreSession');
    _publish(const SessionRestoring());
    await Future<void>.delayed(Duration.zero);
    final session = storedSession;
    _publish(
      session == null
          ? const SessionUnauthenticated()
          : SessionAuthenticated(session),
    );
    return true;
  }

  @override
  Future<bool> login({
    required String homeserver,
    required String userId,
    required String password,
  }) async {
    calls.add('login:$homeserver:$userId');
    lastPassword = password;
    _publish(const SessionAuthenticating());
    if (holdLogin) {
      _pendingLogin = Completer<void>();
      await _pendingLogin!.future;
    } else {
      await Future<void>.delayed(Duration.zero);
    }

    final failure = loginFailure;
    if (failure != null) {
      _publish(SessionFailed(AuthError(code: failure, reference: 'a-2')));
      return false;
    }

    final session = UserSession(
      userId: userId,
      deviceId: 'DEVICE',
      homeserver: homeserver,
    );
    storedSession = session;
    _publish(SessionAuthenticated(session));
    return true;
  }

  @override
  Future<bool> logout() async {
    calls.add('logout');
    storedSession = null;
    _publish(const SessionUnauthenticated());
    return true;
  }

  @override
  Stream<SessionState> watchSession() async* {
    yield _current;
    yield* _states.stream;
  }

  final _rooms = StreamController<List<RoomSummary>>.broadcast();

  @override
  Stream<List<RoomSummary>> watchRooms() async* {
    yield [];
    yield* _rooms.stream;
  }

  @override
  Stream<List<TimelineMessage>> watchTimeline({required String roomId}) async* {
    yield [];
  }

  @override
  Future<bool> sendTextMessage({required String roomId, required String text}) async {
    calls.add('sendTextMessage:$roomId:$text');
    return true;
  }
}
