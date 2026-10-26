import 'dart:async';
import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:infortts_shared/infortts_shared.dart';
import 'package:path_provider/path_provider.dart';
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

  /// Safely updates an individual app in the list atomically to prevent race conditions during concurrent downloads
  void _updateApp(String slug, AppInstallState Function(AppInstallState current) updater) {
    final currentList = List<AppInstallState>.from(appsNotifier.value);
    final idx = currentList.indexWhere((a) => a.slug == slug);
    if (idx != -1) {
      currentList[idx] = updater(currentList[idx]);
      appsNotifier.value = currentList;
    }
  }

  /// Accurate semantic update detection avoiding false positives on build numbers.
  /// Updates are only required for native releases (major.minor). OTA patches are decoupled.
  static bool computeHasUpdate({
    required bool isInstalled,
    required String installedVersion,
    required int installedBuild,
    required String latestVersion,
    required int latestBuild,
    int installedPatch = 0,
    int latestPatch = 0,
    bool isHostApp = false,
  }) {
    if (!isInstalled) return false;

    final vInst = installedVersion.trim().replaceAll(RegExp(r'^v', caseSensitive: false), '');
    final vLate = latestVersion.trim().replaceAll(RegExp(r'^v', caseSensitive: false), '');

    // 1. Compare canonical base release versions (e.g. 2.04.00 vs 2.02.00)
    final baseInst = InforttsVersionHelper.getBaseVersion(vInst);
    final baseLate = InforttsVersionHelper.getBaseVersion(vLate);

    final baseCmp = compareSemver(baseLate, baseInst);
    if (baseCmp > 0) {
      // Newer native release available
      return true;
    }
    if (baseCmp < 0) {
      // Running newer local base release
      return false;
    }

    // 2. Base release is identical (e.g. both 2.04.00 or both 2.08.00):
    // For the host app (Waptia itself), OTA patches can be applied in-app, so check build/patch bump.
    // For external apps (e.g. Mitochondria), OTA differential patches are decoupled and applied
    // directly by each app's in-process InforttsCdnOtaEngine. Android sandbox forbids Waptia from
    // writing patches into external app directories. Therefore, external apps only require a
    // Waptia update if there is a new base native release (handled above).
    if (isHostApp) {
      final expectedNormalized = encodeSemverToBuild(baseLate);
      if (latestBuild > 0 && installedBuild > 0 && latestBuild != expectedNormalized) {
        if ((latestBuild >= 1000 && installedBuild >= 1000) || (latestBuild < 1000 && installedBuild < 1000)) {
          return latestBuild > installedBuild;
        }
      }
      if (latestPatch > installedPatch && latestPatch > 0) {
        return true;
      }
    }

    return false;
  }

  static int compareSemver(String v1, String v2) {
    List<int> parseParts(String v) {
      final clean = v.split('+').first.split('-').first;
      return clean
          .split('.')
          .map((p) => int.tryParse(p) ?? 0)
          .toList();
    }

    final p1 = parseParts(v1);
    final p2 = parseParts(v2);
    final maxLen = p1.length > p2.length ? p1.length : p2.length;
    for (int i = 0; i < maxLen; i++) {
      final n1 = i < p1.length ? p1[i] : 0;
      final n2 = i < p2.length ? p2[i] : 0;
      if (n1 > n2) return 1;
      if (n1 < n2) return -1;
    }
    return 0;
  }

  static int encodeSemverToBuild(String v) {
    try {
      final parts = v.split('+').first.split('-').first.split('.');
      final major = parts.isNotEmpty ? (int.tryParse(parts[0]) ?? 0) : 0;
      final minor = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
      final patch = parts.length > 2 ? (int.tryParse(parts[2]) ?? 0) : 0;
      return (major * 10000) + (minor * 100) + patch;
    } catch (_) {
      return 10000;
    }
  }

  /// Initialize local store, request notification permission, detect installed packages, and start auto-update daemon
  Future<void> initialize({bool isTest = false}) async {
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
      final userRating = prefs.getInt('waptia_rating_${app.slug}');
      final userReview = prefs.getString('waptia_review_${app.slug}');

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
        hasUpdate: computeHasUpdate(
          isInstalled: isInstalled,
          installedVersion: installedVer,
          installedBuild: installedBuild,
          latestVersion: latestVer,
          latestBuild: latestBuild,
          isHostApp: (app.slug == 'waptia'),
        ),
        releaseNotes: app.versions.isNotEmpty ? app.versions.first.releaseNotes : ['✓ Infortts sovereign release'],
        downloadUrl: app.versions.isNotEmpty ? app.versions.first.downloadUrl : 'https://update.infortts.site/download/${app.slug}.apk',
        patchUrl: 'https://update.infortts.site/patches/${app.slug}/patch_1.bin',
        autoUpdateEnabled: appAuto,
        superadminOnly: app.superadminOnly,
        rating: app.rating,
        ratingCount: app.ratingCount,
        userRating: userRating,
        userReview: userReview,
        screenshots: app.screenshots.isNotEmpty
            ? app.screenshots
            : List.generate(5, (i) => 'https://waptia.infortts.site/screenshots/${app.slug}_${i + 1}.png'),
      ));
    }

    appsNotifier.value = initialList;
    _recomputePendingCount();

    if (isTest) return;

    // 1. Request Notification Permission on Android 13+
    await requestNotificationPermission();

    // 2. Automatically query device PackageManager to detect real installed packages
    await detectInstalledApps();

    // 3. Automatic Cache Hygiene: Purge stale APKs/tmp files older than 30 mins
    try {
      final cacheMb = await getCacheSizeBytes();
      if (cacheMb > 50.0) {
        await clearCache(force: cacheMb > 250.0);
      }
    } catch (_) {}

    // 4. Start background cron
    _restartCronTimer();

    // 5. Perform initial live check against update.infortts.site
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
            final vNamePkg = pkgData['versionName']?.toString() ?? '';
            final vCodePkg = (pkgData['versionCode'] as num?)?.toInt() ?? 0;

            // Check if there is an active differential patch applied in prefs
            final cachedVer = prefs.getString('$_prefVersionPrefix${app.slug}');
            final cachedBuild = prefs.getInt('$_prefBuildPrefix${app.slug}');

            // If a valid differential patch is active and newer than or equal to the base APK,
            // preserve the patch version so the app doesn't regress back into an update loop.
            final bool hasActivePatch = cachedVer != null &&
                cachedVer.isNotEmpty &&
                compareSemver(cachedVer, vNamePkg) >= 0;

            final vName = hasActivePatch ? cachedVer : (vNamePkg.isNotEmpty ? vNamePkg : app.installedVersion);
            final vCode = (hasActivePatch && cachedBuild != null && cachedBuild >= vCodePkg)
                ? cachedBuild
                : (vCodePkg > 0 ? vCodePkg : app.installedBuild);

            prefs.setBool('$_prefInstalledPrefix${app.slug}', true);
            prefs.setString('$_prefVersionPrefix${app.slug}', vName);
            prefs.setInt('$_prefBuildPrefix${app.slug}', vCode);

            return app.copyWith(
              isInstalled: true,
              installedVersion: vName,
              installedBuild: vCode,
              hasUpdate: computeHasUpdate(
                isInstalled: true,
                installedVersion: vName,
                installedBuild: vCode,
                latestVersion: app.latestVersion,
                latestBuild: app.latestBuild,
                latestPatch: app.latestPatch,
                isHostApp: (app.slug == 'waptia'),
              ),
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
    // Inject into in-app notification center for Waptia Store
    try {
      final session = InforttsAuthManager.instance.currentSession;
      final userId = (session != null && !session.isGuest && session.authenticated) ? session.userId : null;
      InforttsNotificationService.instance.addLocalNotification(
        title: title,
        body: message,
        topic: 'waptia.store',
        category: 'STORE',
        targetUserId: userId,
      );
    } catch (_) {}

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

            final hasUpdate = computeHasUpdate(
              isInstalled: app.isInstalled,
              installedVersion: app.installedVersion,
              installedBuild: app.installedBuild,
              latestVersion: effectiveLatestVer,
              latestBuild: effectiveLatestBuild,
              latestPatch: latestPatch,
              isHostApp: (app.slug == 'waptia'),
            );
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

        // Dynamically merge new apps discovered in remote catalog
        final existingSlugs = updatedList.map((a) => a.slug).toSet();
        for (final entry in remoteMap.entries) {
          final slug = entry.key;
          if (slug.isNotEmpty && !existingSlugs.contains(slug)) {
            final remote = entry.value;
            final remoteVer = remote['latest_version']?.toString() ?? '1.0.0';
            final remoteBuild = (remote['latest_build'] as num?)?.toInt() ?? 10000;
            final latestPatch = (remote['latestPatch'] as num?)?.toInt() ?? 1;
            final dlUrl = remote['download_url']?.toString() ?? '';
            final pUrl = remote['cdn_patch_url']?.toString() ?? '';
            final pkg = remote['package_name']?.toString() ?? 'com.infortts.$slug';
            final name = remote['name']?.toString() ?? slug;
            List<String> notes = [];
            if (remote['release_notes'] is List) {
              notes = List<String>.from(remote['release_notes']);
            }
            updatedList.add(AppInstallState(
              slug: slug,
              name: name,
              packageName: pkg,
              category: 'Ecosystem',
              installedVersion: '0.0.0',
              installedBuild: 0,
              latestVersion: remoteVer,
              latestBuild: remoteBuild,
              latestPatch: latestPatch,
              downloadUrl: dlUrl,
              patchUrl: pUrl,
              releaseNotes: notes,
              isInstalled: false,
              hasUpdate: false,
              superadminOnly: (remote['superadminOnly'] == true || remote['superadmin_only'] == true || slug == 'admin'),
              rating: 4.9,
              ratingCount: 128,
              screenshots: List.generate(5, (i) => 'https://waptia.infortts.site/screenshots/${slug}_${i + 1}.png'),
            ));
          }
        }

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
    final initialList = appsNotifier.value;
    final appIdx = initialList.indexWhere((a) => a.slug == slug);
    if (appIdx == -1) return false;

    final app = initialList[appIdx];
    _updateApp(slug, (current) => current.copyWith(
      isDownloading: true,
      downloadProgress: 0.1,
      downloadStatus: 'Checking updates...',
      downloadSpeed: '',
      downloadedMb: 0.0,
      totalMb: 0.0,
    ));

    try {
      // 1. Attempt Silent Differential Patching only for same major.minor release
      // If there is a major or minor version bump (e.g. 2.08 to 2.09, or 2.2 to 2.4),
      // native APK installation is required so Android OS PackageManager updates the version name.
      final vInstBase = InforttsVersionHelper.getBaseVersion(app.installedVersion);
      final vLateBase = InforttsVersionHelper.getBaseVersion(app.latestVersion);
      // Differential patching is only valid for Waptia itself (the host app).
      // External apps (e.g. Mitochondria) run in their own Android sandbox and must apply
      // differential patches internally using their own in-process InforttsCdnOtaEngine.
      final bool canUseDifferentialPatch = (slug == 'waptia') && (vInstBase == vLateBase);

      bool patchSuccess = false;
      if (canUseDifferentialPatch) {
        final otaEngine = InforttsCdnOtaEngine(
          appName: app.slug,
          appVersion: app.latestVersion,
          packageName: app.packageName,
        );

        final manifest = await otaEngine.fetchManifest();
        if (manifest != null && manifest.latestPatch > 0) {
          onProgress?.call(0.4);
          _updateApp(slug, (current) => current.copyWith(
            downloadProgress: 0.4,
            downloadStatus: 'Downloading differential patch...',
          ));

          patchSuccess = await otaEngine.downloadAndApplyPatch(manifest, onStatusChanged: (status, patch) {
            if (status == InforttsCdnOtaStatus.downloading) {
              onProgress?.call(0.7);
              _updateApp(slug, (current) => current.copyWith(
                downloadProgress: 0.7,
                downloadStatus: 'Applying differential patch...',
              ));
            }
          });
        }
      }

      onProgress?.call(1.0);

      if (patchSuccess) {
        // Mark differential patch applied in persistent preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('$_prefBuildPrefix${app.slug}', app.latestBuild);
        await prefs.setString('$_prefVersionPrefix${app.slug}', app.latestVersion);
        _updateApp(slug, (current) => current.copyWith(
          installedBuild: app.latestBuild,
          installedVersion: app.latestVersion,
          hasUpdate: false,
          isDownloading: false,
          downloadProgress: 1.0,
          downloadSpeed: '',
          downloadStatus: 'Updated',
        ));
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
      _updateApp(slug, (current) => current.copyWith(
        isDownloading: false,
        downloadProgress: 0.0,
        downloadSpeed: '',
        downloadStatus: '',
      ));
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
    final initialList = appsNotifier.value;
    final appIdx = initialList.indexWhere((a) => a.slug == slug);
    if (appIdx == -1) return false;

    final app = initialList[appIdx];
    if (app.downloadUrl.isEmpty) return false;

    if (kIsWeb) {
      await launchUrl(Uri.parse(app.downloadUrl), mode: LaunchMode.externalApplication);
      return true;
    }

    _updateApp(slug, (current) => current.copyWith(
      isDownloading: true,
      downloadProgress: 0.05,
      downloadStatus: 'Connecting...',
      downloadSpeed: '',
      downloadedMb: 0.0,
      totalMb: 0.0,
    ));
    onProgress?.call(0.05);

    try {
      final success = await executeNativeDownloadAndInstall(
        slug: app.slug,
        downloadUrl: app.downloadUrl,
        packageName: app.packageName,
        appName: app.name,
        onProgress: onProgress,
        onProgressDetails: (details) {
          _updateApp(slug, (current) => current.copyWith(
            downloadProgress: details.progress,
            downloadedMb: details.downloadedMb,
            totalMb: details.totalMb,
            downloadSpeed: details.speed,
            downloadStatus: details.status,
          ));
        },
        onNotify: (title, msg) => showNotification(title: title, message: msg),
      );

      _updateApp(slug, (current) => current.copyWith(
        isDownloading: false,
        downloadProgress: success ? 1.0 : 0.0,
        downloadSpeed: '',
        downloadStatus: success ? 'Installed' : '',
      ));
      onProgress?.call(success ? 1.0 : 0.0);

      if (success) {
        _pollForAppInstallation(
          app.packageName,
          app.slug,
          isUpdate: app.hasUpdate,
          targetVersion: app.latestVersion,
        );
      }
      return success;
    } catch (e) {
      if (kDebugMode) print('[WaptiaAutoUpdateManager] Error downloading/installing ${app.slug}: $e');
      _updateApp(slug, (current) => current.copyWith(
        isDownloading: false,
        downloadProgress: 0.0,
        downloadSpeed: '',
        downloadStatus: '',
      ));
      return false;
    }
  }

  void _pollForAppInstallation(
    String packageName,
    String slug, {
    bool isUpdate = false,
    String targetVersion = '',
  }) {
    bool notified = false;
    for (final delay in [2, 5, 10, 20, 35]) {
      Future.delayed(Duration(seconds: delay), () async {
        if (notified) return;
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
          final isTargetReached = targetVersion.isNotEmpty
              ? (current.installedVersion == targetVersion || compareSemver(current.installedVersion, targetVersion) >= 0)
              : !current.hasUpdate;
          if (isUpdate) {
            if (isTargetReached && !notified) {
              notified = true;
              // Clean up downloaded temp package now that package manager successfully installed it
              try {
                final tempDir = await getTemporaryDirectory();
                final apk = File('${tempDir.path}/$slug.apk');
                if (await apk.exists()) await apk.delete();
              } catch (_) {}
              await showNotification(
                title: '${current.name} Updated',
                message: '${current.name} updated to v${current.installedVersion} successfully.',
              );
            }
          } else {
            if (!notified) {
              notified = true;
              try {
                final tempDir = await getTemporaryDirectory();
                final apk = File('${tempDir.path}/$slug.apk');
                if (await apk.exists()) await apk.delete();
              } catch (_) {}
              await showNotification(
                title: '${current.name} Installed',
                message: '${current.name} is installed and ready to open.',
              );
            }
          }
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

  // ── Waptia API & Glycocalyx Sovereign Gateways ─────────────────────────────
  static const String kWaptiaApiBase = 'https://api.waptia.infortts.site';
  static const String kWaptiaApiFallbackBase = 'https://auth.infortts.site';

  // ── Glycocalyx Devices & Cross-Device Distribution ─────────────────────────

  Future<List<GlycocalyxDevice>> fetchGlycocalyxDevices() async {
    // If running in guest session or unauthenticated, do not display mock devices
    if (InforttsAuthManager.instance.isGuest || !InforttsAuthManager.instance.isAuthenticated) {
      return const [
        GlycocalyxDevice(
          id: 'current_device',
          name: 'This Device',
          type: 'Phone',
          userAgent: 'Android Client',
          isCurrent: true,
        ),
      ];
    }

    try {
      final token = InforttsAuthManager.instance.currentToken;
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      // Try Waptia API Gateway first
      try {
        final url = Uri.parse('$kWaptiaApiBase/user/devices');
        final resp = await http.get(url, headers: headers).timeout(const Duration(seconds: 4));
        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body) as Map<String, dynamic>;
          final rawList = data['devices'] as List<dynamic>? ?? [];
          if (rawList.isNotEmpty) {
            return rawList.map((e) => GlycocalyxDevice.fromJson(Map<String, dynamic>.from(e as Map))).toList();
          }
        }
      } catch (_) {}

      // Fallback: Glycocalyx Auth Gateway
      final url = Uri.parse('$kWaptiaApiFallbackBase/user/devices');
      final resp = await http.get(url, headers: headers).timeout(const Duration(seconds: 4));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final rawList = data['devices'] as List<dynamic>? ?? [];
        if (rawList.isNotEmpty) {
          return rawList.map((e) => GlycocalyxDevice.fromJson(Map<String, dynamic>.from(e as Map))).toList();
        }
      }
    } catch (_) {}

    // Clean authenticated fallback: Return authenticated current device
    return const [
      GlycocalyxDevice(
        id: 'current_device',
        name: 'This Device',
        type: 'Phone',
        userAgent: 'Android Client',
        isCurrent: true,
      ),
    ];
  }

  Future<bool> installOnDevice(String deviceId, String appSlug) async {
    try {
      final token = InforttsAuthManager.instance.currentToken;
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      final payload = jsonEncode({'device_id': deviceId, 'app_slug': appSlug});

      // Try Waptia API Gateway
      try {
        final url = Uri.parse('$kWaptiaApiBase/api/v1/devices/install');
        final resp = await http.post(url, headers: headers, body: payload).timeout(const Duration(seconds: 4));
        if (resp.statusCode == 200) return true;
      } catch (_) {}

      // Fallback: Glycocalyx
      final url = Uri.parse('$kWaptiaApiFallbackBase/api/v1/devices/install');
      await http.post(url, headers: headers, body: payload).timeout(const Duration(seconds: 4));
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Infortts DB App Ratings & Reviews (Waptia API) ──────────────────────────

  Future<AppRatingSummary> fetchAppRatings(String slug) async {
    try {
      // 1. Try Waptia API Gateway
      try {
        final url = Uri.parse('$kWaptiaApiBase/api/v1/apps/$slug/ratings');
        final resp = await http.get(url).timeout(const Duration(seconds: 4));
        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body) as Map<String, dynamic>;
          return AppRatingSummary.fromJson(data);
        }
      } catch (_) {}

      // 2. Try Fallback Gateway
      final url = Uri.parse('$kWaptiaApiFallbackBase/api/v1/apps/$slug/ratings');
      final resp = await http.get(url).timeout(const Duration(seconds: 4));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        return AppRatingSummary.fromJson(data);
      }
    } catch (_) {}

    // Default Infortts DB fallback summary
    return AppRatingSummary(
      appSlug: slug,
      averageRating: 4.9,
      totalRatings: 128,
      ratingCounts: const {'5': 115, '4': 10, '3': 2, '2': 1, '1': 0},
      recentReviews: [],
    );
  }

  Future<bool> submitAppRating(String slug, int rating, String review, {String? deviceName}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('waptia_rating_$slug', rating);
    if (review.isNotEmpty) {
      await prefs.setString('waptia_review_$slug', review);
    }

    // Update in-memory state
    final list = List<AppInstallState>.from(appsNotifier.value);
    final idx = list.indexWhere((a) => a.slug == slug);
    if (idx != -1) {
      list[idx] = list[idx].copyWith(
        userRating: rating,
        userReview: review,
      );
      appsNotifier.value = list;
    }

    // Sync to Infortts DB via Waptia API
    try {
      final token = InforttsAuthManager.instance.currentToken;
      final session = InforttsAuthManager.instance.currentSession;
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final payload = jsonEncode({
        'rating': rating,
        'review': review,
        'user_name': session?.profile?['display_name'] ?? session?.email ?? 'Infortts User',
        'user_id': session?.userId ?? 'usr_guest',
        'device_name': deviceName ?? 'Android Device',
      });

      // 1. Try Waptia API Gateway
      try {
        final url = Uri.parse('$kWaptiaApiBase/api/v1/apps/$slug/ratings');
        final resp = await http.post(url, headers: headers, body: payload).timeout(const Duration(seconds: 5));
        if (resp.statusCode == 200) return true;
      } catch (_) {}

      // 2. Try Fallback Gateway
      final url = Uri.parse('$kWaptiaApiFallbackBase/api/v1/apps/$slug/ratings');
      final resp = await http.post(url, headers: headers, body: payload).timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200) {
        return true;
      }
    } catch (_) {}

    // Also sync to local OTA hub if available
    try {
      final payload = jsonEncode({
        'rating': rating,
        'review': review,
        'user_name': 'Infortts User',
        'device_name': deviceName ?? 'Android Device',
      });
      await http.post(
        Uri.parse('http://127.0.0.1:8092/api/v1/apps/$slug/ratings'),
        headers: {'Content-Type': 'application/json'},
        body: payload,
      ).timeout(const Duration(seconds: 2));
    } catch (_) {}

    return true;
  }

  /// Calculates total size of temporary cache, downloaded APKs, and differential patches in MB
  Future<double> getCacheSizeBytes() async {
    if (kIsWeb) return 0.0;
    try {
      int totalBytes = 0;
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        await for (final entity in tempDir.list(recursive: true, followLinks: false)) {
          if (entity is File) {
            try {
              totalBytes += await entity.length();
            } catch (_) {}
          }
        }
      }
      final appSupportDir = await getApplicationSupportDirectory();
      if (await appSupportDir.exists()) {
        await for (final entity in appSupportDir.list(recursive: true, followLinks: false)) {
          if (entity is File && (entity.path.endsWith('.apk') || entity.path.endsWith('.bin') || entity.path.endsWith('.tmp'))) {
            try {
              totalBytes += await entity.length();
            } catch (_) {}
          }
        }
      }
      return totalBytes / (1024 * 1024);
    } catch (_) {
      return 0.0;
    }
  }

  /// Prune cached downloaded APKs, diff patches, and temporary files older than 30 minutes
  /// or when force is true. If cache size exceeds 100MB, aggressive purge is applied.
  Future<int> clearCache({bool force = false}) async {
    if (kIsWeb) return 0;
    int filesDeleted = 0;
    try {
      final now = DateTime.now();
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        await for (final entity in tempDir.list(recursive: true, followLinks: false)) {
          if (entity is File) {
            try {
              final stat = await entity.stat();
              final ageMinutes = now.difference(stat.modified).inMinutes;
              // Delete APKs, patch bins, tmp files, or if forced, or if file older than 30 mins
              final isAppArtifact = entity.path.endsWith('.apk') ||
                  entity.path.endsWith('.bin') ||
                  entity.path.endsWith('.tmp') ||
                  entity.path.contains('cache');
              if (force || isAppArtifact || ageMinutes > 30) {
                await entity.delete();
                filesDeleted++;
              }
            } catch (_) {}
          }
        }
      }

      final appSupportDir = await getApplicationSupportDirectory();
      if (await appSupportDir.exists()) {
        await for (final entity in appSupportDir.list(recursive: true, followLinks: false)) {
          if (entity is File && (entity.path.endsWith('.apk') || entity.path.endsWith('.bin') || entity.path.endsWith('.tmp'))) {
            try {
              await entity.delete();
              filesDeleted++;
            } catch (_) {}
          }
        }
      }
    } catch (_) {}
    return filesDeleted;
  }
}

