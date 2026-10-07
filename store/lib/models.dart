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
  final bool superadminOnly;
  final double rating;
  final int ratingCount;
  final List<String> screenshots;

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
    this.superadminOnly = false,
    this.rating = 4.9,
    this.ratingCount = 128,
    this.screenshots = const [],
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
  final bool superadminOnly;
  final double rating;
  final int ratingCount;
  final int? userRating;
  final String? userReview;
  final List<String> screenshots;

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
    this.superadminOnly = false,
    this.rating = 4.9,
    this.ratingCount = 128,
    this.userRating,
    this.userReview,
    this.screenshots = const [],
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
    bool? superadminOnly,
    double? rating,
    int? ratingCount,
    int? userRating,
    String? userReview,
    List<String>? screenshots,
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
      superadminOnly: superadminOnly ?? this.superadminOnly,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      userRating: userRating ?? this.userRating,
      userReview: userReview ?? this.userReview,
      screenshots: screenshots ?? this.screenshots,
    );
  }
}

// ── Glycocalyx Ecosystem Connected Devices ─────────────────────────────────────

class GlycocalyxDevice {
  final String id;
  final String name;
  final String type; // e.g. "Phone", "Tablet", "Desktop", "TV"
  final String userAgent;
  final DateTime? lastActiveAt;
  final bool isCurrent;

  const GlycocalyxDevice({
    required this.id,
    required this.name,
    required this.type,
    this.userAgent = '',
    this.lastActiveAt,
    this.isCurrent = false,
  });

  factory GlycocalyxDevice.fromJson(Map<String, dynamic> json, {bool isCurrent = false}) {
    final rawType = (json['device_type'] as String? ?? 'phone').toLowerCase();
    String formattedType = 'Phone';
    if (rawType.contains('tablet') || rawType.contains('pad')) {
      formattedType = 'Tablet';
    } else if (rawType.contains('desktop') || rawType.contains('mac') || rawType.contains('pc') || rawType.contains('linux') || rawType.contains('windows')) {
      formattedType = 'Desktop';
    } else if (rawType.contains('tv')) {
      formattedType = 'TV';
    } else if (rawType.contains('phone') || rawType.contains('android') || rawType.contains('ios')) {
      formattedType = 'Phone';
    }

    return GlycocalyxDevice(
      id: json['id'] as String? ?? 'dev_unknown',
      name: json['device_name'] as String? ?? 'Google Pixel 9 Pro',
      type: formattedType,
      userAgent: json['user_agent'] as String? ?? '',
      lastActiveAt: json['last_active_at'] != null ? DateTime.tryParse(json['last_active_at'].toString()) : null,
      isCurrent: isCurrent,
    );
  }
}

// ── Infortts DB App Ratings & Reviews ─────────────────────────────────────────

class AppRatingReview {
  final String id;
  final String appSlug;
  final String userId;
  final String userName;
  final int rating;
  final String review;
  final String deviceName;
  final DateTime createdAt;

  const AppRatingReview({
    required this.id,
    required this.appSlug,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.review,
    required this.deviceName,
    required this.createdAt,
  });

  factory AppRatingReview.fromJson(Map<String, dynamic> json) {
    return AppRatingReview(
      id: json['id'] as String? ?? '',
      appSlug: json['app_slug'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      userName: json['user_name'] as String? ?? 'Infortts User',
      rating: (json['rating'] as num?)?.toInt() ?? 5,
      review: json['review'] as String? ?? '',
      deviceName: json['device_name'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class AppRatingSummary {
  final String appSlug;
  final double averageRating;
  final int totalRatings;
  final Map<String, int> ratingCounts;
  final List<AppRatingReview> recentReviews;

  const AppRatingSummary({
    required this.appSlug,
    required this.averageRating,
    required this.totalRatings,
    required this.ratingCounts,
    required this.recentReviews,
  });

  factory AppRatingSummary.fromJson(Map<String, dynamic> json) {
    final countsRaw = json['rating_counts'] as Map<String, dynamic>? ?? {};
    final counts = countsRaw.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
    final reviewsRaw = json['recent_reviews'] as List<dynamic>? ?? [];
    return AppRatingSummary(
      appSlug: json['app_slug'] as String? ?? '',
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 5.0,
      totalRatings: (json['total_ratings'] as num?)?.toInt() ?? 0,
      ratingCounts: counts,
      recentReviews: reviewsRaw.map((e) => AppRatingReview.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
    );
  }
}
