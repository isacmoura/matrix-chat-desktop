import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:matrix_desktop/app/app.dart';
import 'package:matrix_desktop/bridge/matrix_gateway.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('calls Rust through the gateway', (tester) async {
    final gateway = FrbMatrixGateway();
    await gateway.initialize();

    await tester.pumpWidget(
      MatrixDesktopApp(bridgeStatus: gateway.bridgeStatus()),
    );

    expect(find.text('Ponte Flutter–Rust pronta'), findsOneWidget);
  });
}
