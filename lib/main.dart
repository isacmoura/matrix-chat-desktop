import 'package:flutter/widgets.dart';
import 'package:matrix_desktop/app/app.dart';
import 'package:matrix_desktop/bridge/matrix_gateway.dart';
import 'package:matrix_desktop/features/auth/data/auth_repository.dart';
import 'package:matrix_desktop/features/rooms/data/room_repository.dart';
import 'package:path_provider/path_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final gateway = FrbMatrixGateway();
  await gateway.initialize();
  final appDataDirectory = await getApplicationSupportDirectory();

  runApp(
    MatrixDesktopApp(
      authRepository: AuthRepository(gateway),
      roomRepository: RoomRepository(gateway),
      appDataDirectory: appDataDirectory.path,
    ),
  );
}
