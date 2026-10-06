import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:matrix_desktop/bridge/matrix_gateway.dart';
import 'package:matrix_desktop/core/models/session_state.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final gateway = FrbMatrixGateway();

  setUpAll(gateway.initialize);

  testWidgets('calls Rust through the gateway', (tester) async {
    final matrixSdkStatus = await gateway.watchMatrixSdkStatus().first;

    expect(gateway.bridgeStatus(), 'Ponte Flutter–Rust pronta');
    expect(matrixSdkStatus.label, 'Matrix SDK 0.19.1 • SDK UI 0.19.1');
  });

  testWidgets('initializes authentication and streams the session state',
      (tester) async {
    final directory = await Directory.systemTemp.createTemp('matrix-desktop');
    addTearDown(() => directory.delete(recursive: true));

    final unauthenticated = gateway
        .watchSession()
        .firstWhere((state) => state is SessionUnauthenticated);

    final initialized =
        await gateway.initializeAuth(appDataDirectory: directory.path);

    expect(initialized, isTrue);
    expect(
      await unauthenticated.timeout(const Duration(seconds: 5)),
      isA<SessionUnauthenticated>(),
    );
  });
}
