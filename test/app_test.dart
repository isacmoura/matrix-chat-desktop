import 'package:flutter_test/flutter_test.dart';
import 'package:matrix_desktop/app/app.dart';

void main() {
  testWidgets('shows the application and bridge status', (tester) async {
    await tester.pumpWidget(
      const MatrixDesktopApp(bridgeStatus: 'Ponte Flutter–Rust pronta'),
    );

    expect(find.text('Matrix Desktop'), findsOneWidget);
    expect(find.text('Ponte Flutter–Rust pronta'), findsOneWidget);
  });
}
