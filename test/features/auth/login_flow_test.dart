import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix_desktop/app/app.dart';
import 'package:matrix_desktop/core/models/session_state.dart';
import 'package:matrix_desktop/features/auth/data/auth_repository.dart';
import 'package:matrix_desktop/features/auth/presentation/login_page.dart';
import 'package:matrix_desktop/features/rooms/data/room_repository.dart';

import '../../support/fake_matrix_gateway.dart';

void main() {
  late FakeMatrixGateway gateway;

  setUp(() => gateway = FakeMatrixGateway());

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MatrixDesktopApp(
        authRepository: AuthRepository(gateway),
        roomRepository: RoomRepository(gateway),
        appDataDirectory: '/app-data',
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> fillAndSubmit(
    WidgetTester tester, {
    String userId = '@isac:matrix.org',
    String password = 'secret',
  }) async {
    await tester.enterText(find.byKey(const Key('login-user-id')), userId);
    await tester.enterText(find.byKey(const Key('login-password')), password);
    await tester.tap(find.byKey(const Key('login-submit')));
  }

  String passwordText(WidgetTester tester) => tester
      .widget<TextField>(
        find.descendant(
          of: find.byKey(const Key('login-password')),
          matching: find.byType(TextField),
        ),
      )
      .controller!
      .text;

  testWidgets('shows the login form when there is no stored session',
      (tester) async {
    await pumpApp(tester);

    expect(find.text('Entrar no Matrix Desktop'), findsOneWidget);
    expect(find.text('Converse sem perder o foco.'), findsOneWidget);
    expect(find.text('https://matrix.org'), findsOneWidget);
  });

  testWidgets('validates required fields without calling Rust', (tester) async {
    await pumpApp(tester);

    await tester.enterText(find.byKey(const Key('login-homeserver')), '');
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pump();

    expect(find.text('Informe o homeserver.'), findsOneWidget);
    expect(find.text('Informe seu ID Matrix.'), findsOneWidget);
    expect(find.text('Informe sua senha.'), findsOneWidget);
    expect(gateway.calls.where((c) => c.startsWith('login')), isEmpty);
  });

  testWidgets('rejects a malformed Matrix ID', (tester) async {
    await pumpApp(tester);

    await fillAndSubmit(tester, userId: '@isac');
    await tester.pump();

    expect(find.text('Use o formato @usuario:servidor.'), findsOneWidget);
  });

  testWidgets('clears the password and shows progress while authenticating',
      (tester) async {
    gateway.holdLogin = true;
    await pumpApp(tester);

    await fillAndSubmit(tester);
    await tester.pump();

    expect(gateway.lastPassword, 'secret');
    expect(passwordText(tester), isEmpty);
    expect(find.text('Entrar'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    gateway.completeLogin();
    await tester.pumpAndSettle();
  });

  testWidgets('shows a Flutter-defined message for invalid credentials',
      (tester) async {
    gateway.loginFailure = AuthErrorCode.invalidCredentials;
    await pumpApp(tester);

    await fillAndSubmit(tester);
    await tester.pumpAndSettle();

    expect(find.text('ID, senha ou homeserver não conferem.'), findsOneWidget);
    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('logs in, shows the session and logs out back to login',
      (tester) async {
    await pumpApp(tester);

    await fillAndSubmit(tester);
    await tester.pumpAndSettle();

    expect(find.text('Sessão ativa'), findsOneWidget);
    expect(find.text('@isac:matrix.org'), findsOneWidget);

    await tester.tap(find.byKey(const Key('logout-button')));
    await tester.pumpAndSettle();

    expect(find.text('Entrar no Matrix Desktop'), findsOneWidget);
  });

  testWidgets('opens directly in the session when it can be restored',
      (tester) async {
    gateway.storedSession = const UserSession(
      userId: '@isac:matrix.org',
      deviceId: 'DEVICE',
      homeserver: 'https://matrix.org/',
    );

    await pumpApp(tester);

    expect(find.text('Sessão ativa'), findsOneWidget);
    expect(find.byType(LoginPage), findsNothing);
  });

  testWidgets('hides the hero panel on narrow windows', (tester) async {
    tester.view.physicalSize = const Size(700, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MatrixDesktopApp(
        authRepository: AuthRepository(gateway),
        roomRepository: RoomRepository(gateway),
        appDataDirectory: '/app-data',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Converse sem perder o foco.'), findsNothing);
    expect(find.text('Entrar no Matrix Desktop'), findsOneWidget);
  });
}
