import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'native_installer.dart';

const MethodChannel _systemChannel = MethodChannel('com.infortts.waptia/system');

Future<bool> nativeDownloadAndInstallApk({
  required String slug,
  required String downloadUrl,
  required String packageName,
  required String appName,
  void Function(double progress)? onProgress,
  void Function(DownloadProgressDetails details)? onProgressDetails,
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

      final stopwatch = Stopwatch()..start();
      int lastReportMs = 0;
      int lastReportBytes = 0;
      String currentSpeed = '0 KB/s';

      await for (final chunk in streamedResponse.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;

        final elapsedMs = stopwatch.elapsedMilliseconds;
        // Throttle updates to ~80ms or on completion to prevent UI rebuild thrashing and flickering
        if (elapsedMs - lastReportMs >= 80 || (totalBytes > 0 && receivedBytes >= totalBytes)) {
          final timeDiffSec = (elapsedMs - lastReportMs) / 1000.0;
          if (timeDiffSec > 0) {
            final bytesDiff = receivedBytes - lastReportBytes;
            final bytesPerSec = bytesDiff / timeDiffSec;
            if (bytesPerSec >= 1024 * 1024) {
              currentSpeed = '${(bytesPerSec / (1024 * 1024)).toStringAsFixed(1)} MB/s';
            } else {
              currentSpeed = '${(bytesPerSec / 1024).toStringAsFixed(0)} KB/s';
            }
          }
          lastReportMs = elapsedMs;
          lastReportBytes = receivedBytes;

          final progress = totalBytes > 0 ? (receivedBytes / totalBytes).clamp(0.01, 1.0) : 0.05;
          final downloadedMb = receivedBytes / (1024 * 1024);
          final totalMb = totalBytes > 0 ? (totalBytes / (1024 * 1024)) : 0.0;

          onProgressDetails?.call(DownloadProgressDetails(
            progress: progress,
            downloadedMb: downloadedMb,
            totalMb: totalMb,
            speed: currentSpeed,
            status: 'Downloading',
          ));
          onProgress?.call(progress);
        }
      }
      await sink.flush();
      await sink.close();
    } finally {
      client.close();
    }

    final finalFileSize = await apkFile.length();
    final fileSizeMb = (finalFileSize / (1024 * 1024));
    onProgressDetails?.call(DownloadProgressDetails(
      progress: 1.0,
      downloadedMb: fileSizeMb,
      totalMb: fileSizeMb,
      speed: '',
      status: 'Installing...',
    ));
    onProgress?.call(1.0);

    onNotify?.call(
      '$appName Ready to Install',
      'Download complete (${fileSizeMb.toStringAsFixed(1)} MB). Proceeding with installation.',
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
