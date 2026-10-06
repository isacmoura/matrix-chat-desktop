import 'package:flutter_test/flutter_test.dart';
import 'package:matrix_desktop/app/app.dart';
import 'package:matrix_desktop/core/models/matrix_sdk_status.dart';

void main() {
  testWidgets('shows the application and bridge status', (tester) async {
    await tester.pumpWidget(
      const MatrixDesktopApp(
        bridgeStatus: 'Ponte Flutter–Rust pronta',
        matrixSdkStatus: MatrixSdkStatus(
          matrixSdk: '0.19.1',
          matrixSdkUi: '0.19.1',
        ),
      ),
    );

    expect(find.text('Matrix Desktop'), findsOneWidget);
    expect(find.text('Ponte Flutter–Rust pronta'), findsOneWidget);
    expect(find.text('Matrix SDK 0.19.1 • SDK UI 0.19.1'), findsOneWidget);
  });
}
