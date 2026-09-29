class AppVersion {
  final String platform;
  final String version;
  final String downloadUrl;
  final String sha256;
  final int sizeBytes;
  final String releaseNotes;
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
    required this.tagline,
    required this.description,
    required this.iconUrl,
    required this.homepageUrl,
    required this.repoPath,
    required this.latest,
    required this.versions,
  });
}
