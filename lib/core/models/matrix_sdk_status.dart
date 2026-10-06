final class MatrixSdkStatus {
  const MatrixSdkStatus({
    required this.matrixSdk,
    required this.matrixSdkUi,
  });

  final String matrixSdk;
  final String matrixSdkUi;

  String get label => 'Matrix SDK $matrixSdk • SDK UI $matrixSdkUi';
}
