import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

const MethodChannel _systemChannel = MethodChannel('com.infortts.waptia/system');

Future<bool> nativeDownloadAndInstallApk({
  required String slug,
  required String downloadUrl,
  required String packageName,
  required String appName,
  void Function(double progress)? onProgress,
  void Function(String title, String message)? onNotify,
}) async {
  if (kIsWeb) return false;
  try {
    final canInstall = await _systemChannel.invokeMethod<bool>('canRequestPackageInstalls') ?? true;
    if (!canInstall) {
      await _systemChannel.invokeMethod('requestInstallPermission');
    }

    final tempDir = await getTemporaryDirectory();
    final apkFile = File('${tempDir.path}/$slug.apk');
    if (await apkFile.exists()) {
      try {
        await apkFile.delete();
      } catch (_) {}
    }

    final client = http.Client();
    try {
      final req = http.Request('GET', Uri.parse(downloadUrl));
      req.followRedirects = true;
      req.maxRedirects = 10;
      final streamedResponse = await client.send(req);

      if (streamedResponse.statusCode != 200) {
        throw Exception('Download failed with status ${streamedResponse.statusCode}');
      }

      final totalBytes = streamedResponse.contentLength ?? 0;
      int receivedBytes = 0;
      final sink = apkFile.openWrite();

      await for (final chunk in streamedResponse.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0) {
          final progress = (receivedBytes / totalBytes).clamp(0.0, 1.0);
          onProgress?.call(progress);
        }
      }
      await sink.flush();
      await sink.close();
    } finally {
      client.close();
    }

    onProgress?.call(1.0);
    final fileSizeMb = (await apkFile.length() / (1024 * 1024)).toStringAsFixed(1);
    onNotify?.call(
      '$appName Ready to Install',
      'Download complete ($fileSizeMb MB). Proceeding with installation.',
    );

    final res = await _systemChannel.invokeMethod<bool>('installApk', {
      'filePath': apkFile.path,
    });
    return res ?? true;
  } catch (e) {
    if (kDebugMode) print('[nativeDownloadAndInstallApk] Error: $e');
    return false;
  }
}
