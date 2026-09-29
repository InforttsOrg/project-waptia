import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:infortts_shared/infortts_shared.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'catalog_data.dart';
import 'models.dart';

class WaptiaAutoUpdateManager {
  static final WaptiaAutoUpdateManager instance = WaptiaAutoUpdateManager._internal();
  WaptiaAutoUpdateManager._internal();

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

  /// Initialize local store, seed catalog states, and start auto-update daemon
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    autoUpdateMaster = prefs.getBool(_prefAutoUpdateMaster) ?? true;
    checkIntervalMinutes = prefs.getInt(_prefCheckInterval) ?? 15;
    silentPatches = prefs.getBool(_prefSilentPatches) ?? true;
    wifiOnly = prefs.getBool(_prefWifiOnly) ?? false;

    // Seed initial app states
    List<AppInstallState> initialList = [];
    for (final app in inforttsCatalog) {
      final isInstalled = prefs.getBool('$_prefInstalledPrefix${app.slug}') ?? 
          (app.slug == 'waptia' || app.slug == 'mitochondria' || app.slug == 'glycocalyx'); // default core fleet
      final installedBuild = prefs.getInt('$_prefBuildPrefix${app.slug}') ?? 
          (app.slug == 'waptia' ? 10000 : (app.slug == 'mitochondria' ? 20600 : 10000));
      final installedVer = prefs.getString('$_prefVersionPrefix${app.slug}') ?? 
          (app.slug == 'waptia' ? '1.1.0' : (app.slug == 'mitochondria' ? '2.06.00' : '1.0.0'));
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

    // Start background cron
    _restartCronTimer();

    // Perform initial live check against update.infortts.site
    await checkAllUpdates(silent: true);
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
            final latestVer = remote['latest_version']?.toString() ?? app.latestVersion;
            final latestBuild = (remote['latest_build'] as num?)?.toInt() ?? app.latestBuild;
            final latestPatch = (remote['latestPatch'] as num?)?.toInt() ?? app.latestPatch;
            final dlUrl = remote['download_url']?.toString() ?? app.downloadUrl;
            final pUrl = remote['cdn_patch_url']?.toString() ?? app.patchUrl;
            
            List<String> notes = app.releaseNotes;
            if (remote['release_notes'] is List) {
              notes = List<String>.from(remote['release_notes']);
            }

            final hasUpdate = app.isInstalled && latestBuild > app.installedBuild;
            return app.copyWith(
              latestVersion: latestVer,
              latestBuild: latestBuild,
              latestPatch: latestPatch,
              downloadUrl: dlUrl,
              patchUrl: pUrl,
              releaseNotes: notes,
              hasUpdate: hasUpdate,
              lastChecked: DateTime.now(),
            );
          }
          return app;
        }).toList();

        appsNotifier.value = updatedList;
        lastCheckedNotifier.value = DateTime.now();
        _recomputePendingCount();
      }
    } catch (e) {
      if (kDebugMode) print('[WaptiaAutoUpdateManager] Error checking updates: $e');
    } finally {
      isCheckingUpdates.value = false;
    }
  }

  /// Update single app (downloads differential patch or opens installer)
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

      onProgress?.call(0.9);

      // 2. Mark as updated locally in persistent preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('$_prefBuildPrefix${app.slug}', app.latestBuild);
      await prefs.setString('$_prefVersionPrefix${app.slug}', app.latestVersion);
      await prefs.setBool('$_prefInstalledPrefix${app.slug}', true);

      list[idx] = list[idx].copyWith(
        installedBuild: app.latestBuild,
        installedVersion: app.latestVersion,
        hasUpdate: false,
        isDownloading: false,
        downloadProgress: 1.0,
      );
      appsNotifier.value = list;
      _recomputePendingCount();

      // If full APK installation is desired on platform
      if (!patchSuccess && app.downloadUrl.isNotEmpty) {
        final uri = Uri.parse(app.downloadUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }

      return true;
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

  /// Mark app as installed
  Future<void> installApp(String slug) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefInstalledPrefix$slug', true);

    final list = List<AppInstallState>.from(appsNotifier.value);
    final idx = list.indexWhere((a) => a.slug == slug);
    if (idx != -1) {
      list[idx] = list[idx].copyWith(isInstalled: true);
      appsNotifier.value = list;
      await updateApp(slug);
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
