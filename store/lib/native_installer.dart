import 'native_installer_stub.dart'
    if (dart.library.io) 'native_installer_io.dart';

Future<bool> executeNativeDownloadAndInstall({
  required String slug,
  required String downloadUrl,
  required String packageName,
  required String appName,
  void Function(double progress)? onProgress,
  void Function(String title, String message)? onNotify,
}) =>
    nativeDownloadAndInstallApk(
      slug: slug,
      downloadUrl: downloadUrl,
      packageName: packageName,
      appName: appName,
      onProgress: onProgress,
      onNotify: onNotify,
    );
