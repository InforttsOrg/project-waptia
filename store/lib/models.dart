class AppVersion {
  final String platform;
  final String version;
  final String downloadUrl;
  final String sha256;
  final int sizeBytes;
  final List<String> releaseNotes;
  final String publishedAt;
  final int buildNumber;

  const AppVersion({
    required this.platform,
    required this.version,
    required this.downloadUrl,
    required this.sha256,
    required this.sizeBytes,
    required this.releaseNotes,
    required this.publishedAt,
    required this.buildNumber,
  });
}

class AppInfo {
  final String slug;
  final String name;
  final String packageName;
  final String category;
  final String tagline;
  final String description;
  final String iconUrl;
  final String homepageUrl;
  final String repoPath;
  final Map<String, String> latest;
  final List<AppVersion> versions;

  const AppInfo({
    required this.slug,
    required this.name,
    required this.packageName,
    this.category = 'Productivity',
    required this.tagline,
    required this.description,
    required this.iconUrl,
    required this.homepageUrl,
    required this.repoPath,
    required this.latest,
    required this.versions,
  });
}

class AppInstallState {
  final String slug;
  final String name;
  final String packageName;
  final String category;
  final String installedVersion;
  final int installedBuild;
  final String latestVersion;
  final int latestBuild;
  final int latestPatch;
  final bool isInstalled;
  final bool hasUpdate;
  final bool isDownloading;
  final double downloadProgress;
  final List<String> releaseNotes;
  final String downloadUrl;
  final String patchUrl;
  final bool autoUpdateEnabled;
  final DateTime? lastChecked;

  const AppInstallState({
    required this.slug,
    required this.name,
    required this.packageName,
    this.category = 'Ecosystem',
    required this.installedVersion,
    required this.installedBuild,
    required this.latestVersion,
    required this.latestBuild,
    required this.latestPatch,
    required this.isInstalled,
    required this.hasUpdate,
    this.isDownloading = false,
    this.downloadProgress = 0.0,
    required this.releaseNotes,
    required this.downloadUrl,
    required this.patchUrl,
    this.autoUpdateEnabled = true,
    this.lastChecked,
  });

  AppInstallState copyWith({
    String? installedVersion,
    int? installedBuild,
    String? latestVersion,
    int? latestBuild,
    int? latestPatch,
    bool? isInstalled,
    bool? hasUpdate,
    bool? isDownloading,
    double? downloadProgress,
    List<String>? releaseNotes,
    String? downloadUrl,
    String? patchUrl,
    bool? autoUpdateEnabled,
    DateTime? lastChecked,
  }) {
    return AppInstallState(
      slug: slug,
      name: name,
      packageName: packageName,
      category: category,
      installedVersion: installedVersion ?? this.installedVersion,
      installedBuild: installedBuild ?? this.installedBuild,
      latestVersion: latestVersion ?? this.latestVersion,
      latestBuild: latestBuild ?? this.latestBuild,
      latestPatch: latestPatch ?? this.latestPatch,
      isInstalled: isInstalled ?? this.isInstalled,
      hasUpdate: hasUpdate ?? this.hasUpdate,
      isDownloading: isDownloading ?? this.isDownloading,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      releaseNotes: releaseNotes ?? this.releaseNotes,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      patchUrl: patchUrl ?? this.patchUrl,
      autoUpdateEnabled: autoUpdateEnabled ?? this.autoUpdateEnabled,
      lastChecked: lastChecked ?? this.lastChecked,
    );
  }
}
