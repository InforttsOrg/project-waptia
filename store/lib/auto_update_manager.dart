import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:infortts_shared/infortts_shared.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'catalog_data.dart';
import 'models.dart';
import 'native_installer.dart';

class WaptiaAutoUpdateManager {
  static final WaptiaAutoUpdateManager instance = WaptiaAutoUpdateManager._internal();
  WaptiaAutoUpdateManager._internal();

  static const MethodChannel _systemChannel = MethodChannel('com.infortts.waptia/system');

  static const String _prefInstalledPrefix = 'waptia_installed_';
  static const String _prefBuildPrefix = 'waptia_build_';
  static const String _prefVersionPrefix = 'waptia_ver_';
  static const String _prefAutoUpdateMaster = 'waptia_autoupdate_master';
  static const String _prefCheckInterval = 'waptia_check_interval_min';
  static const String _prefSilentPatches = 'waptia_silent_patches';
  static const String _prefWifiOnly = 'waptia_wifi_only';
  static const String _prefAppAutoUpdatePrefix = 'waptia_app_autoupdate_';

  final ValueNotifier<List<AppInstallState>> appsNotifier = ValueNotifier<List<AppInstallState>>([]);
  final ValueNotifier<int> pendingUpdatesCount = ValueNotifier<int>(0);
  final ValueNotifier<bool> isCheckingUpdates = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isBatchUpdating = ValueNotifier<bool>(false);
  final ValueNotifier<DateTime?> lastCheckedNotifier = ValueNotifier<DateTime?>(null);

  bool autoUpdateMaster = true;
  int checkIntervalMinutes = 15;
  bool silentPatches = true;
  bool wifiOnly = false;

  Timer? _bgCronTimer;

  /// Initialize local store, request notification permission, detect installed packages, and start auto-update daemon
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    autoUpdateMaster = prefs.getBool(_prefAutoUpdateMaster) ?? true;
    checkIntervalMinutes = prefs.getInt(_prefCheckInterval) ?? 15;
    silentPatches = prefs.getBool(_prefSilentPatches) ?? true;
    wifiOnly = prefs.getBool(_prefWifiOnly) ?? false;

    // Seed initial app states from catalog and cache
    List<AppInstallState> initialList = [];
    for (final app in inforttsCatalog) {
      final isInstalled = prefs.getBool('$_prefInstalledPrefix${app.slug}') ?? false;
      final installedBuild = prefs.getInt('$_prefBuildPrefix${app.slug}') ?? 
          (app.slug == 'waptia' ? 20700 : (app.slug == 'mitochondria' ? 20600 : 10000));
      final installedVer = prefs.getString('$_prefVersionPrefix${app.slug}') ?? 
          (app.slug == 'waptia' ? '2.07.00' : (app.slug == 'mitochondria' ? '2.06.00' : '1.0.0'));
      final appAuto = prefs.getBool('$_prefAppAutoUpdatePrefix${app.slug}') ?? true;

      final latestVer = app.latest['android'] ?? '1.2.0';
      final latestBuild = app.versions.isNotEmpty ? app.versions.first.buildNumber : 10200;

      initialList.add(AppInstallState(
        slug: app.slug,
        name: app.name,
        packageName: app.packageName.isNotEmpty ? app.packageName : 'com.infortts.${app.slug}',
        category: app.category,
        installedVersion: installedVer,
        installedBuild: installedBuild,
        latestVersion: latestVer,
        latestBuild: latestBuild,
        latestPatch: 1,
        isInstalled: isInstalled,
        hasUpdate: isInstalled && latestBuild > installedBuild,
        releaseNotes: app.versions.isNotEmpty ? app.versions.first.releaseNotes : ['✓ Infortts sovereign release'],
        downloadUrl: app.versions.isNotEmpty ? app.versions.first.downloadUrl : 'https://update.infortts.site/download/${app.slug}.apk',
        patchUrl: 'https://update.infortts.site/patches/${app.slug}/patch_1.bin',
        autoUpdateEnabled: appAuto,
      ));
    }

    appsNotifier.value = initialList;
    _recomputePendingCount();

    // 1. Request Notification Permission on Android 13+
    await requestNotificationPermission();

    // 2. Automatically query device PackageManager to detect real installed packages
    await detectInstalledApps();

    // 3. Start background cron
    _restartCronTimer();

    // 4. Perform initial live check against update.infortts.site
    await checkAllUpdates(silent: true);
  }

  /// Query Android PackageManager to detect which apps are truly installed on the device
  Future<void> detectInstalledApps() async {
    if (kIsWeb) return;
    try {
      final List<String> packageList = inforttsCatalog
          .map((a) => a.packageName.isNotEmpty ? a.packageName : 'com.infortts.${a.slug}')
          .toList();
      
      final result = await _systemChannel.invokeMethod<Map>('getInstalledPackages', {'packages': packageList});

      if (result != null) {
        final prefs = await SharedPreferences.getInstance();
        final updated = appsNotifier.value.map((app) {
          final pkgData = result[app.packageName];
          if (pkgData != null && pkgData is Map && pkgData['installed'] == true) {
            final vName = pkgData['versionName']?.toString() ?? app.installedVersion;
            final vCode = (pkgData['versionCode'] as num?)?.toInt() ?? app.installedBuild;

            prefs.setBool('$_prefInstalledPrefix${app.slug}', true);
            prefs.setString('$_prefVersionPrefix${app.slug}', vName);
            prefs.setInt('$_prefBuildPrefix${app.slug}', vCode);

            return app.copyWith(
              isInstalled: true,
              installedVersion: vName,
              installedBuild: vCode,
              hasUpdate: app.latestBuild > vCode,
            );
          } else {
            // Not installed on device: clear pref and set isInstalled false (except host app waptia)
            final isHost = (app.slug == 'waptia');
            prefs.setBool('$_prefInstalledPrefix${app.slug}', isHost);
            return app.copyWith(
              isInstalled: isHost,
              hasUpdate: false,
            );
          }
        }).toList();

        appsNotifier.value = updated;
        _recomputePendingCount();
      }
    } catch (e) {
      if (kDebugMode) print('[WaptiaAutoUpdateManager] Error detecting installed packages: $e');
    }
  }

  /// Launch application on device
  Future<bool> openApp(String packageName) async {
    if (kIsWeb) {
      final app = appsNotifier.value.firstWhere(
        (a) => a.packageName == packageName,
        orElse: () => appsNotifier.value.first,
      );
      if (app.downloadUrl.isNotEmpty) {
        await launchUrl(Uri.parse(app.downloadUrl), mode: LaunchMode.externalApplication);
      }
      return true;
    }

    try {
      final res = await _systemChannel.invokeMethod<bool>('openApp', {'packageName': packageName});
      if (res == true) return true;
    } catch (_) {}

    try {
      final uri = Uri.parse('android-app://$packageName');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Check whether Waptia has permission to install unknown apps
  Future<bool> canRequestPackageInstalls() async {
    if (kIsWeb) return true;
    try {
      final res = await _systemChannel.invokeMethod<bool>('canRequestPackageInstalls');
      return res ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Request unknown app install permission from system settings
  Future<void> requestInstallPermission() async {
    if (kIsWeb) return;
    try {
      await _systemChannel.invokeMethod('requestInstallPermission');
    } catch (_) {}
  }

  /// Check whether POST_NOTIFICATIONS permission is active
  Future<bool> isNotificationPermissionGranted() async {
    if (kIsWeb) return false;
    try {
      final res = await _systemChannel.invokeMethod<bool>('isNotificationPermissionGranted');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Request POST_NOTIFICATIONS permission
  Future<void> requestNotificationPermission() async {
    if (kIsWeb) return;
    try {
      await _systemChannel.invokeMethod('requestNotificationPermission');
    } catch (_) {}
  }

  /// Dispatch local system notification for downloads, installs, or updates
  Future<void> showNotification({required String title, required String message}) async {
    if (kIsWeb) return;
    try {
      await _systemChannel.invokeMethod('showNotification', {
        'title': title,
        'message': message,
      });
    } catch (_) {}
  }

  void _restartCronTimer() {
    _bgCronTimer?.cancel();
    if (!autoUpdateMaster) return;

    final duration = Duration(minutes: checkIntervalMinutes);
    _bgCronTimer = Timer.periodic(duration, (_) async {
      if (autoUpdateMaster) {
        await checkAllUpdates(silent: true);
        if (silentPatches) {
          await _autoApplySilentPatches();
        }
      }
    });
  }

  void _recomputePendingCount() {
    int count = 0;
    for (final app in appsNotifier.value) {
      if (app.isInstalled && app.hasUpdate) {
        count++;
      }
    }
    pendingUpdatesCount.value = count;
  }

  /// Live check against central single-domain OTA endpoint update.infortts.site
  Future<void> checkAllUpdates({bool silent = false}) async {
    if (isCheckingUpdates.value) return;
    isCheckingUpdates.value = true;

    try {
      final response = await http
          .get(Uri.parse('$kOtaBaseUrl/api/v1/ota/catalog'))
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List catalog = data['catalog'] ?? [];
        final Map<String, dynamic> remoteMap = {
          for (var item in catalog) (item['slug'] ?? item['app'] ?? '').toString(): item
        };

        final updatedList = appsNotifier.value.map((app) {
          final remote = remoteMap[app.slug];
          if (remote != null) {
            final remoteVer = remote['latest_version']?.toString();
            final remoteBuild = (remote['latest_build'] as num?)?.toInt() ?? 0;
            final latestPatch = (remote['latestPatch'] as num?)?.toInt() ?? app.latestPatch;
            final dlUrl = remote['download_url']?.toString();
            final pUrl = remote['cdn_patch_url']?.toString();
            
            // Protect against stale remote registry: never downgrade below bundled catalog
            final effectiveLatestBuild = remoteBuild > app.latestBuild ? remoteBuild : app.latestBuild;
            final effectiveLatestVer = (remoteBuild >= app.latestBuild && remoteVer != null && remoteVer.isNotEmpty)
                ? remoteVer
                : app.latestVersion;

            List<String> notes = app.releaseNotes;
            if (remote['release_notes'] is List) {
              notes = List<String>.from(remote['release_notes']);
            }

            final hasUpdate = app.isInstalled && effectiveLatestBuild > app.installedBuild;
            return app.copyWith(
              latestVersion: effectiveLatestVer,
              latestBuild: effectiveLatestBuild,
              latestPatch: latestPatch,
              downloadUrl: (dlUrl != null && dlUrl.isNotEmpty) ? dlUrl : app.downloadUrl,
              patchUrl: (pUrl != null && pUrl.isNotEmpty) ? pUrl : app.patchUrl,
              releaseNotes: notes,
              hasUpdate: hasUpdate,
              lastChecked: DateTime.now(),
            );
          }
          return app;
        }).toList();

        final int previousPending = pendingUpdatesCount.value;
        appsNotifier.value = updatedList;
        lastCheckedNotifier.value = DateTime.now();
        _recomputePendingCount();

        // Dispatch alert if new updates were discovered on installed apps
        if (pendingUpdatesCount.value > previousPending && pendingUpdatesCount.value > 0) {
          await showNotification(
            title: 'Waptia Store Updates',
            message: 'Discovered ${pendingUpdatesCount.value} pending update${pendingUpdatesCount.value > 1 ? "s" : ""} for your installed apps.',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) print('[WaptiaAutoUpdateManager] Error checking updates: $e');
    } finally {
      isCheckingUpdates.value = false;
    }
  }

  /// Update single app (downloads differential patch or falls back to in-app APK installer)
  Future<bool> updateApp(String slug, {void Function(double progress)? onProgress}) async {
    final list = List<AppInstallState>.from(appsNotifier.value);
    final idx = list.indexWhere((a) => a.slug == slug);
    if (idx == -1) return false;

    final app = list[idx];
    list[idx] = app.copyWith(isDownloading: true, downloadProgress: 0.1);
    appsNotifier.value = list;

    try {
      // 1. Attempt Silent Differential Patching via InforttsCdnOtaEngine
      final otaEngine = InforttsCdnOtaEngine(
        appName: app.slug,
        appVersion: app.latestVersion,
        packageName: app.packageName,
      );

      final manifest = await otaEngine.fetchManifest();
      bool patchSuccess = false;
      if (manifest != null && manifest.latestPatch > 0) {
        onProgress?.call(0.4);
        list[idx] = list[idx].copyWith(downloadProgress: 0.4);
        appsNotifier.value = List.from(list);

        patchSuccess = await otaEngine.downloadAndApplyPatch(manifest, onStatusChanged: (status, patch) {
          if (status == InforttsCdnOtaStatus.downloading) {
            onProgress?.call(0.7);
            list[idx] = list[idx].copyWith(downloadProgress: 0.7);
            appsNotifier.value = List.from(list);
          }
        });
      }

      onProgress?.call(1.0);

      if (patchSuccess) {
        // Mark differential patch applied in persistent preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('$_prefBuildPrefix${app.slug}', app.latestBuild);
        await prefs.setString('$_prefVersionPrefix${app.slug}', app.latestVersion);
        list[idx] = list[idx].copyWith(
          installedBuild: app.latestBuild,
          installedVersion: app.latestVersion,
          hasUpdate: false,
          isDownloading: false,
          downloadProgress: 1.0,
        );
        appsNotifier.value = list;
        _recomputePendingCount();

        await showNotification(
          title: '${app.name} Updated',
          message: '${app.name} updated to v${app.latestVersion} successfully.',
        );
        return true;
      }

      // If differential patch was not applicable or unavailable, download APK in-app and trigger native install
      return await installApp(slug, onProgress: onProgress);
    } catch (e) {
      if (kDebugMode) print('[WaptiaAutoUpdateManager] Failed updating ${app.slug}: $e');
      list[idx] = list[idx].copyWith(isDownloading: false, downloadProgress: 0.0);
      appsNotifier.value = list;
      return false;
    }
  }

  /// Batch update all pending applications (F-Droid style Update All)
  Future<int> updateAllPending() async {
    if (isBatchUpdating.value) return 0;
    isBatchUpdating.value = true;

    int successCount = 0;
    try {
      final pendingList = appsNotifier.value.where((a) => a.isInstalled && a.hasUpdate).toList();
      for (final app in pendingList) {
        final ok = await updateApp(app.slug);
        if (ok) successCount++;
        await Future.delayed(const Duration(milliseconds: 300));
      }
    } finally {
      isBatchUpdating.value = false;
    }
    return successCount;
  }

  /// Automatically apply silent differential patches for apps with auto-update enabled
  Future<void> _autoApplySilentPatches() async {
    final pending = appsNotifier.value
        .where((a) => a.isInstalled && a.hasUpdate && a.autoUpdateEnabled)
        .toList();
    for (final app in pending) {
      await updateApp(app.slug);
    }
  }

  /// In-app download and native package installation (no browser redirect on Android)
  Future<bool> installApp(String slug, {void Function(double progress)? onProgress}) async {
    final list = List<AppInstallState>.from(appsNotifier.value);
    final idx = list.indexWhere((a) => a.slug == slug);
    if (idx == -1) return false;

    final app = list[idx];
    if (app.downloadUrl.isEmpty) return false;

    if (kIsWeb) {
      await launchUrl(Uri.parse(app.downloadUrl), mode: LaunchMode.externalApplication);
      return true;
    }

    list[idx] = app.copyWith(isDownloading: true, downloadProgress: 0.05);
    appsNotifier.value = List.from(list);
    onProgress?.call(0.05);

    try {
      final success = await executeNativeDownloadAndInstall(
        slug: app.slug,
        downloadUrl: app.downloadUrl,
        packageName: app.packageName,
        appName: app.name,
        onProgress: (p) {
          list[idx] = list[idx].copyWith(downloadProgress: p);
          appsNotifier.value = List<AppInstallState>.from(list);
          onProgress?.call(p);
        },
        onNotify: (title, msg) => showNotification(title: title, message: msg),
      );

      list[idx] = list[idx].copyWith(isDownloading: false, downloadProgress: success ? 1.0 : 0.0);
      appsNotifier.value = List<AppInstallState>.from(list);
      onProgress?.call(success ? 1.0 : 0.0);

      if (success) {
        _pollForAppInstallation(app.packageName, app.slug);
      }
      return success;
    } catch (e) {
      if (kDebugMode) print('[WaptiaAutoUpdateManager] Error downloading/installing ${app.slug}: $e');
      list[idx] = list[idx].copyWith(isDownloading: false, downloadProgress: 0.0);
      appsNotifier.value = List<AppInstallState>.from(list);
      return false;
    }
  }

  void _pollForAppInstallation(String packageName, String slug) {
    for (final delay in [3, 7, 14, 25, 45]) {
      Future.delayed(Duration(seconds: delay), () async {
        await detectInstalledApps();
        final current = appsNotifier.value.firstWhere(
          (a) => a.slug == slug,
          orElse: () => AppInstallState(
            slug: '', name: '', packageName: '', category: '',
            installedVersion: '', installedBuild: 0, latestVersion: '',
            latestBuild: 0, latestPatch: 0, isInstalled: false,
            hasUpdate: false, releaseNotes: [], downloadUrl: '',
            patchUrl: '', autoUpdateEnabled: true,
          ),
        );
        if (current.isInstalled) {
          await showNotification(
            title: '${current.name} Installed',
            message: '${current.name} is installed and ready to open.',
          );
        }
      });
    }
  }

  /// Mark app as uninstalled
  Future<void> uninstallApp(String slug) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefInstalledPrefix$slug', false);

    final list = List<AppInstallState>.from(appsNotifier.value);
    final idx = list.indexWhere((a) => a.slug == slug);
    if (idx != -1) {
      list[idx] = list[idx].copyWith(isInstalled: false, hasUpdate: false);
      appsNotifier.value = list;
      _recomputePendingCount();
    }
  }

  /// Policy Settings
  Future<void> setAutoUpdateMaster(bool enabled) async {
    autoUpdateMaster = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefAutoUpdateMaster, enabled);
    _restartCronTimer();
  }

  Future<void> setCheckInterval(int minutes) async {
    checkIntervalMinutes = minutes;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefCheckInterval, minutes);
    _restartCronTimer();
  }

  Future<void> setSilentPatches(bool enabled) async {
    silentPatches = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefSilentPatches, enabled);
  }

  Future<void> setWifiOnly(bool enabled) async {
    wifiOnly = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefWifiOnly, enabled);
  }

  Future<void> toggleAppAutoUpdate(String slug, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefAppAutoUpdatePrefix$slug', enabled);

    final list = List<AppInstallState>.from(appsNotifier.value);
    final idx = list.indexWhere((a) => a.slug == slug);
    if (idx != -1) {
      list[idx] = list[idx].copyWith(autoUpdateEnabled: enabled);
      appsNotifier.value = list;
    }
  }
}
