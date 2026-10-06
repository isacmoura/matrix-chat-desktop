import 'package:matrix_desktop/core/models/matrix_sdk_status.dart';

import 'generated/api/health.dart' as native;
import 'generated/frb_generated.dart';

abstract interface class MatrixGateway {
  Future<void> initialize();

  String bridgeStatus();

  Stream<MatrixSdkStatus> watchMatrixSdkStatus();
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
}
