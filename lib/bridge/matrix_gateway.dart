import 'package:matrix_desktop/core/models/matrix_sdk_status.dart';
import 'package:matrix_desktop/core/models/room_summary.dart';
import 'package:matrix_desktop/core/models/session_state.dart';

import 'package:matrix_desktop/core/models/timeline_message.dart';

import 'generated/api/auth.dart' as native_auth;
import 'generated/api/health.dart' as native;
import 'generated/api/rooms.dart' as native_rooms;
import 'generated/api/timeline.dart' as native_timeline;
import 'generated/frb_generated.dart';

abstract interface class MatrixGateway {
  Future<void> initialize();

  String bridgeStatus();

  Stream<MatrixSdkStatus> watchMatrixSdkStatus();

  Future<bool> initializeAuth({required String appDataDirectory});

  Future<bool> login({
    required String homeserver,
    required String userId,
    required String password,
  });

  Future<bool> restoreSession();
  Future<bool> logout();
  Stream<SessionState> watchSession();
  Stream<List<RoomSummary>> watchRooms();
  Stream<List<TimelineMessage>> watchTimeline({required String roomId});
  Future<bool> sendTextMessage({required String roomId, required String text});
}

final class FrbMatrixGateway implements MatrixGateway {
  @override
  Future<void> initialize() => RustLib.init();

  @override
  String bridgeStatus() => native.bridgeStatus();

  @override
  Stream<MatrixSdkStatus> watchMatrixSdkStatus() =>
      native.watchMatrixSdkVersions().map(
            (versions) => MatrixSdkStatus(
              matrixSdk: versions.matrixSdk,
              matrixSdkUi: versions.matrixSdkUi,
            ),
          );

  @override
  Future<bool> initializeAuth({required String appDataDirectory}) => _command(
        () => native_auth.initializeAuth(appDataDirectory: appDataDirectory),
      );

  @override
  Future<bool> login({
    required String homeserver,
    required String userId,
    required String password,
  }) =>
      _command(
        () => native_auth.loginWithPassword(
          homeserver: homeserver,
          userId: userId,
          password: password,
        ),
      );

  @override
  Future<bool> restoreSession() => _command(native_auth.restoreSession);

  @override
  Future<bool> logout() => _command(native_auth.logout);

  @override
  Stream<SessionState> watchSession() =>
      native_auth.watchAuthState().map(_mapAuthState);

  @override
  Stream<List<RoomSummary>> watchRooms() => native_rooms.watchRooms().map(
        (rooms) => rooms
            .map(
              (room) => RoomSummary(
                roomId: room.roomId,
                name: room.name,
                unreadMessages: room.unreadMessages.toInt(),
                isInvited: room.isInvited,
              ),
            )
            .toList(growable: false),
      );

  @override
  Stream<List<TimelineMessage>> watchTimeline({required String roomId}) =>
      native_timeline.watchTimeline(roomId: roomId).map(
            (items) => items
                .map(
                  (item) => TimelineMessage(
                    id: item.id,
                    sender: item.sender,
                    body: item.body,
                    isOwn: item.isOwn,
                    timestamp: DateTime.fromMillisecondsSinceEpoch(
                      item.timestamp.toInt(),
                    ),
                  ),
                )
                .toList(growable: false),
          );

  @override
  Future<bool> sendTextMessage({required String roomId, required String text}) =>
      _voidCommand(() => native_timeline.sendTextMessage(roomId: roomId, text: text));

  Future<bool> _command(Future<native_auth.AuthState> Function() call) async {
    try {
      await call();
      return true;
    } on String {
      return false;
    }
  }

  Future<bool> _voidCommand(Future<void> Function() call) async {
    try {
      await call();
      return true;
    } on String {
      return false;
    }
  }
}

SessionState _mapAuthState(native_auth.AuthState state) {
  switch (state.phase) {
    case native_auth.AuthPhase.uninitialized:
      return const SessionUninitialized();
    case native_auth.AuthPhase.unauthenticated:
      return const SessionUnauthenticated();
    case native_auth.AuthPhase.restoringSession:
      return const SessionRestoring();
    case native_auth.AuthPhase.authenticating:
      return const SessionAuthenticating();
    case native_auth.AuthPhase.authenticated:
      final session = state.session;
      if (session == null) {
        return const SessionFailed(
          AuthError(code: AuthErrorCode.unexpected, reference: 'auth-bridge'),
        );
      }
      return SessionAuthenticated(
        UserSession(
          userId: session.userId,
          deviceId: session.deviceId,
          homeserver: session.homeserver,
        ),
      );
    case native_auth.AuthPhase.failure:
      final failure = state.failure;
      if (failure == null) {
        return const SessionFailed(
          AuthError(code: AuthErrorCode.unexpected, reference: 'auth-bridge'),
        );
      }
      final retryAfterMs = failure.retryAfterMs?.toInt();
      return SessionFailed(
        AuthError(
          code: _mapFailureCode(failure.code),
          reference: failure.reference,
          retryAfter: retryAfterMs == null
              ? null
              : Duration(milliseconds: retryAfterMs),
        ),
      );
  }
}

AuthErrorCode _mapFailureCode(native_auth.AuthFailureCode code) =>
    switch (code) {
      native_auth.AuthFailureCode.invalidHomeserver =>
        AuthErrorCode.invalidHomeserver,
      native_auth.AuthFailureCode.networkUnavailable =>
        AuthErrorCode.networkUnavailable,
      native_auth.AuthFailureCode.invalidCredentials =>
        AuthErrorCode.invalidCredentials,
      native_auth.AuthFailureCode.rateLimited => AuthErrorCode.rateLimited,
      native_auth.AuthFailureCode.storageUnavailable =>
        AuthErrorCode.storageUnavailable,
      native_auth.AuthFailureCode.sessionExpired =>
        AuthErrorCode.sessionExpired,
      native_auth.AuthFailureCode.unexpected => AuthErrorCode.unexpected,
    };
