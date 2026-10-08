import 'package:flutter/foundation.dart';
import 'native_installer.dart';

Future<bool> nativeDownloadAndInstallApk({
  required String slug,
  required String downloadUrl,
  required String packageName,
  required String appName,
  void Function(double progress)? onProgress,
  void Function(DownloadProgressDetails details)? onProgressDetails,
  void Function(String title, String message)? onNotify,
}) async {
  // Stub for Web & non-IO platforms
  if (kDebugMode) {
    print('[nativeDownloadAndInstallApk] Web/stub platform active. Browser direct download used.');
  }
  return true;
}
