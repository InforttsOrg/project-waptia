import 'native_installer_stub.dart'
    if (dart.library.io) 'native_installer_io.dart';

class DownloadProgressDetails {
  final double progress;
  final double downloadedMb;
  final double totalMb;
  final String speed;
  final String status;

  const DownloadProgressDetails({
    required this.progress,
    required this.downloadedMb,
    required this.totalMb,
    required this.speed,
    required this.status,
  });
}

Future<bool> executeNativeDownloadAndInstall({
  required String slug,
  required String downloadUrl,
  required String packageName,
  required String appName,
  void Function(double progress)? onProgress,
  void Function(DownloadProgressDetails details)? onProgressDetails,
  void Function(String title, String message)? onNotify,
}) =>
    nativeDownloadAndInstallApk(
      slug: slug,
      downloadUrl: downloadUrl,
      packageName: packageName,
      appName: appName,
      onProgress: onProgress,
      onProgressDetails: onProgressDetails,
      onNotify: onNotify,
    );
