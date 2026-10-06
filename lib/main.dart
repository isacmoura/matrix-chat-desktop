import 'package:flutter/widgets.dart';
import 'package:matrix_desktop/app/app.dart';
import 'package:matrix_desktop/bridge/matrix_gateway.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final gateway = FrbMatrixGateway();
  await gateway.initialize();
  final matrixSdkStatus = await gateway.watchMatrixSdkStatus().first;

  runApp(
    MatrixDesktopApp(
      bridgeStatus: gateway.bridgeStatus(),
      matrixSdkStatus: matrixSdkStatus,
    ),
  );
}
