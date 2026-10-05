import 'generated/api/health.dart' as native;
import 'generated/frb_generated.dart';

abstract interface class MatrixGateway {
  Future<void> initialize();

  String bridgeStatus();
}

final class FrbMatrixGateway implements MatrixGateway {
  @override
  Future<void> initialize() => RustLib.init();

  @override
  String bridgeStatus() => native.bridgeStatus();
}
