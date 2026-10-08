import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infortts_shared/infortts_shared.dart';

import 'auto_update_manager.dart';
import 'models.dart';
import 'app_screens_meta.dart';

import 'design_skin.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WaptiaAutoUpdateManager.instance.initialize();
  // Design skin for this app (generated; see tools/design-pipeline).
  AppDesignSkin.boot();
  runApp(const WaptiaStoreApp());
}

class WaptiaStoreApp extends StatelessWidget {
  const WaptiaStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return InforttsThemeProvider(
      skin: AppDesignSkin.skin,
      child: Builder(
        builder: (context) {
          final themeData = InforttsThemeProvider.of(context);
          return MaterialApp(
            title: 'Waptia Store',
            debugShowCheckedModeBanner: false,
            theme: themeData.lightTheme,
            darkTheme: themeData.darkTheme,
            themeMode: themeData.themeMode,
            home: ValueListenableBuilder<int>(
              valueListenable: WaptiaAutoUpdateManager.instance.pendingUpdatesCount,
              builder: (context, pendingCount, _) {
                return InforttsAppShell(
                  appName: 'Waptia Store',
                  appDescription: 'Sovereign Fleet App Store & Autonomous OTA Package Manager',
                  appVersion: '2.09.01',
                  requireAuth: false,
                  allowGuest: true,
                  auth: GlycocalyxAuth(),
                  additionalTabs: [
                    InforttsTab(
                      label: 'Explore',
                      icon: Icons.storefront_outlined,
                      builder: (_) => const WaptiaExploreWorkspace(),
                    ),
                    InforttsTab(
                      label: pendingCount > 0 ? 'Updates ($pendingCount)' : 'Updates',
                      icon: Icons.system_update_alt_rounded,
                      builder: (_) => const WaptiaUpdatesWorkspace(),
                    ),
                    InforttsTab(
                      label: 'Auto-Update Policy',
                      icon: Icons.tune_rounded,
                      builder: (_) => const WaptiaPolicyWorkspace(),
                    ),
                  ],
                  workspaceChild: const WaptiaExploreWorkspace(),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. EXPLORE TAB (Fleet App Browser & Search)
// ─────────────────────────────────────────────────────────────────────────────

class WaptiaExploreWorkspace extends StatefulWidget {
  const WaptiaExploreWorkspace({super.key});

  @override
  State<WaptiaExploreWorkspace> createState() => _WaptiaExploreWorkspaceState();
}

class _WaptiaExploreWorkspaceState extends State<WaptiaExploreWorkspace> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _sortBy = 'A-Z';

  final List<String> _categories = [
    'All',
    'Trading & FinTech',
    'Security & IAM',
    'Multi-Agent AI',
    'Healthcare',
    'Creative & Media',
    'Analytics',
    'Infrastructure',
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AuthSession?>(
      valueListenable: InforttsAuthManager.instance.sessionNotifier,
      builder: (context, session, _) {
        final isSuperadmin = session?.isSuperadmin ?? false;
        return ValueListenableBuilder<List<AppInstallState>>(
          valueListenable: WaptiaAutoUpdateManager.instance.appsNotifier,
          builder: (context, apps, _) {
            final filtered = apps.where((app) {
              if (app.superadminOnly && !isSuperadmin) {
                return false;
              }
              final matchesSearch = app.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  app.slug.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  app.packageName.toLowerCase().contains(_searchQuery.toLowerCase());
              final matchesCat = _selectedCategory == 'All' || app.category.toLowerCase() == _selectedCategory.toLowerCase();
              return matchesSearch && matchesCat;
            }).toList();

            if (_sortBy == 'A-Z') {
              filtered.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
            } else if (_sortBy == 'Z-A') {
              filtered.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
            } else if (_sortBy == 'Rating') {
              filtered.sort((a, b) {
                final rA = a.userRating != null ? a.userRating!.toDouble() : 4.9;
                final rB = b.userRating != null ? b.userRating!.toDouble() : 4.9;
                if (rA != rB) return rB.compareTo(rA);
                return a.name.compareTo(b.name);
              });
            } else if (_sortBy == 'Updates') {
              filtered.sort((a, b) {
                if (a.hasUpdate != b.hasUpdate) {
                  return a.hasUpdate ? -1 : 1;
                }
                return a.name.compareTo(b.name);
              });
            } else if (_sortBy == 'Installed') {
              filtered.sort((a, b) {
                if (a.isInstalled != b.isInstalled) {
                  return a.isInstalled ? -1 : 1;
                }
                return a.name.compareTo(b.name);
              });
            }

        return Column(
          children: [
            // Search & Category Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              color: AcousticColors.obsidian,
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'WAPTIA FLEET STORE',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                            color: AcousticColors.titanium,
                          ),
                        ),
                      ),
                      _buildNotificationIcon(context),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: GoogleFonts.outfit(color: AcousticColors.titanium),
                    decoration: InputDecoration(
                      hintText: 'Search 28 ecosystem applications...',
                      hintStyle: GoogleFonts.outfit(color: AcousticColors.steel),
                      prefixIcon: Icon(Icons.search, color: AcousticColors.sonarCyan),
                      filled: true,
                      fillColor: AcousticColors.darkCarbon,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AcousticColors.steel.withValues(alpha: 0.2)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AcousticColors.steel.withValues(alpha: 0.2)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AcousticColors.sonarCyan),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 34,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, idx) {
                        final cat = _categories[idx];
                        final isSel = _selectedCategory == cat;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategory = cat),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSel ? AcousticColors.sonarCyan : AcousticColors.darkCarbon,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSel ? AcousticColors.sonarCyan : AcousticColors.steel.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Text(
                              cat,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                color: isSel ? Colors.black : AcousticColors.steel,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.sort_rounded, size: 14, color: AcousticColors.sonarCyan),
                      const SizedBox(width: 6),
                      Text(
                        'SORT:',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: AcousticColors.steel,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildSortPill('A-Z', 'A-Z (Name)'),
                              const SizedBox(width: 6),
                              _buildSortPill('Z-A', 'Z-A (Name)'),
                              const SizedBox(width: 6),
                              _buildSortPill('Updates', 'Updates Pending'),
                              const SizedBox(width: 6),
                              _buildSortPill('Installed', 'Installed'),
                              const SizedBox(width: 6),
                              _buildSortPill('Rating', 'Top Rated ★'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // App List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final app = filtered[index];
                  return _buildAppCard(context, app);
                },
              ),
            ),
          ],
        );
      },
    );
  },
);
}

  Widget _buildSortPill(String sortKey, String label) {
    final isSelected = _sortBy == sortKey;
    return GestureDetector(
      onTap: () => setState(() => _sortBy = sortKey),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AcousticColors.sonarCyan.withValues(alpha: 0.15) : AcousticColors.darkCarbon,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AcousticColors.sonarCyan : AcousticColors.steel.withValues(alpha: 0.25),
            width: isSelected ? 1.0 : 0.8,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AcousticColors.sonarCyan : AcousticColors.steel,
          ),
        ),
      ),
    );
  }

  Widget _buildAppCard(BuildContext context, AppInstallState app) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: app.hasUpdate
              ? const Color(0xFF38BDF8).withValues(alpha: 0.4)
              : const Color(0xFF1F2937),
        ),
      ),
      child: InkWell(
        onTap: () => _showAppDetailsModal(context, app),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B0F19),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1F2937)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.network(
                    'https://cdn.infortts.site/icons/${app.slug}.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Center(
                      child: Text(
                        app.name.substring(0, app.name.length >= 2 ? 2 : 1).toUpperCase(),
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF38BDF8),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              app.name,
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFF9FAFB),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (app.superadminOnly) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
                              ),
                              child: Text(
                                'SUPERADMIN',
                                style: GoogleFonts.outfit(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFF59E0B),
                                ),
                              ),
                            ),
                          ],
                          if (app.hasUpdate) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                'UPDATE',
                                style: GoogleFonts.outfit(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF38BDF8),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        app.packageName,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          color: const Color(0xFF38BDF8),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'v${app.installedVersion} • Build ${app.installedBuild}',
                        style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF9CA3AF)),
                      ),
                    ],
                  ),
                ),
                _buildActionButton(context, app),
              ],
            ),
            if (app.isDownloading) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOutCubic,
                  tween: Tween<double>(
                    begin: 0.0,
                    end: app.downloadProgress.clamp(0.0, 1.0),
                  ),
                  builder: (context, value, _) {
                    return LinearProgressIndicator(
                      value: value > 0 ? value : (app.downloadProgress > 0 ? app.downloadProgress : null),
                      minHeight: 6,
                      backgroundColor: const Color(0xFF0B0F19),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
                    );
                  },
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    app.totalMb > 0
                        ? '${app.downloadedMb.toStringAsFixed(1)} MB / ${app.totalMb.toStringAsFixed(1)} MB (${(app.downloadProgress * 100).toInt()}%)'
                        : (app.downloadProgress > 0
                            ? '${(app.downloadProgress * 100).toInt()}% • ${app.downloadStatus.isNotEmpty ? app.downloadStatus : "Updating"}'
                            : 'Connecting...'),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  if (app.downloadSpeed.isNotEmpty)
                    Text(
                      app.downloadSpeed,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF38BDF8),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, AppInstallState app) {
    if (app.isDownloading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
        ),
        child: Text(
          '${(app.downloadProgress * 100).toInt()}%',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF38BDF8),
          ),
        ),
      );
    }

    if (!app.isInstalled) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        onPressed: () => WaptiaAutoUpdateManager.instance.installApp(app.slug),
        child: Text('Install', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12)),
      );
    }

    if (app.hasUpdate) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF10B981),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        onPressed: () => WaptiaAutoUpdateManager.instance.updateApp(app.slug),
        child: Text('Update', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12)),
      );
    }

    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1F2937),
        foregroundColor: const Color(0xFF38BDF8),
        side: const BorderSide(color: Color(0xFF38BDF8), width: 1),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
      icon: const Icon(Icons.play_arrow_rounded, size: 16, color: Color(0xFF38BDF8)),
      onPressed: () => WaptiaAutoUpdateManager.instance.openApp(app.packageName),
      label: Text('Open', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  void _showAppDetailsModal(BuildContext context, AppInstallState app) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111827),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => AppDetailsModal(app: app),
    );
  }

  Widget _buildNotificationIcon(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: WaptiaAutoUpdateManager.instance.pendingUpdatesCount,
      builder: (context, pendingCount, _) {
        return FutureBuilder<bool>(
          future: WaptiaAutoUpdateManager.instance.isNotificationPermissionGranted(),
          builder: (context, snapshot) {
            final isGranted = snapshot.data ?? true;
            return InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _showNotificationSheet(context, isGranted, pendingCount),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AcousticColors.darkCarbon,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: !isGranted
                        ? const Color(0xFFF59E0B).withValues(alpha: 0.5)
                        : AcousticColors.steel.withValues(alpha: 0.25),
                  ),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      !isGranted ? Icons.notifications_outlined : Icons.notifications_active_outlined,
                      size: 20,
                      color: !isGranted
                          ? const Color(0xFFF59E0B)
                          : (pendingCount > 0 ? AcousticColors.sonarCyan : AcousticColors.titanium),
                    ),
                    if (pendingCount > 0 || !isGranted)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: !isGranted ? const Color(0xFFF59E0B) : AcousticColors.sonarCyan,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
                          child: pendingCount > 0
                              ? Text(
                                  '$pendingCount',
                                  style: GoogleFonts.outfit(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                  textAlign: TextAlign.center,
                                )
                              : null,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showNotificationSheet(BuildContext context, bool isGranted, int pendingCount) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111827),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.notifications_active_outlined, color: AcousticColors.sonarCyan, size: 22),
                          const SizedBox(width: 10),
                          Text(
                            'WAPTIA NOTIFICATIONS',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              color: AcousticColors.titanium,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AcousticColors.obsidian,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isGranted ? const Color(0xFF10B981).withValues(alpha: 0.3) : const Color(0xFFF59E0B).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isGranted ? const Color(0xFF10B981).withValues(alpha: 0.15) : const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isGranted ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                isGranted ? 'ACTIVE' : 'PERMISSION REQUIRED',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isGranted ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          isGranted
                              ? 'Waptia Store dispatches system notifications solely when:\n• In-app APK downloads complete\n• Ecosystem applications finish installing\n• New version updates are discovered on the cluster'
                              : 'Notification permission is required so Waptia Store can alert you when APK downloads complete, apps finish installing, or new releases become available.',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: AcousticColors.titanium,
                            height: 1.5,
                          ),
                        ),
                        if (!isGranted) ...[
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AcousticColors.sonarCyan,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.check_circle_outline, size: 18),
                              label: Text(
                                'GRANT NOTIFICATION ACCESS',
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              onPressed: () async {
                                await WaptiaAutoUpdateManager.instance.requestNotificationPermission();
                                final granted = await WaptiaAutoUpdateManager.instance.isNotificationPermissionGranted();
                                setSheetState(() {
                                  isGranted = granted;
                                });
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AcousticColors.obsidian,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AcousticColors.steel.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pendingCount > 0 ? '$pendingCount Updates Available' : 'All Apps Up to Date',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: pendingCount > 0 ? AcousticColors.sonarCyan : AcousticColors.titanium,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Fleet OTA CDN: update.infortts.site',
                              style: GoogleFonts.jetBrainsMono(fontSize: 10, color: AcousticColors.steel),
                            ),
                          ],
                        ),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AcousticColors.sonarCyan,
                            side: BorderSide(color: AcousticColors.sonarCyan.withValues(alpha: 0.5)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: Text('Check', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600)),
                          onPressed: () async {
                            await WaptiaAutoUpdateManager.instance.checkAllUpdates();
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _WaptiaSpinningRefreshButton extends StatefulWidget {
  const _WaptiaSpinningRefreshButton();

  @override
  State<_WaptiaSpinningRefreshButton> createState() => _WaptiaSpinningRefreshButtonState();
}

class _WaptiaSpinningRefreshButtonState extends State<_WaptiaSpinningRefreshButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    WaptiaAutoUpdateManager.instance.isCheckingUpdates.addListener(_onStateChange);
    if (WaptiaAutoUpdateManager.instance.isCheckingUpdates.value) {
      _controller.repeat();
    }
  }

  void _onStateChange() {
    if (WaptiaAutoUpdateManager.instance.isCheckingUpdates.value) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    WaptiaAutoUpdateManager.instance.isCheckingUpdates.removeListener(_onStateChange);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: WaptiaAutoUpdateManager.instance.isCheckingUpdates,
      builder: (context, isChecking, _) {
        return TextButton.icon(
          onPressed: isChecking
              ? null
              : () => WaptiaAutoUpdateManager.instance.checkAllUpdates(),
          icon: RotationTransition(
            turns: _controller,
            child: Icon(
              Icons.refresh_rounded,
              size: 15,
              color: AcousticColors.sonarCyan,
            ),
          ),
          label: Text(
            isChecking ? "Refreshing..." : "Refresh",
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AcousticColors.sonarCyan,
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. UPDATES TAB (F-Droid Style Batch Updater)
// ─────────────────────────────────────────────────────────────────────────────

class WaptiaUpdatesWorkspace extends StatelessWidget {
  const WaptiaUpdatesWorkspace({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AuthSession?>(
      valueListenable: InforttsAuthManager.instance.sessionNotifier,
      builder: (context, session, _) {
        final isSuperadmin = session?.isSuperadmin ?? false;
        return ValueListenableBuilder<List<AppInstallState>>(
          valueListenable: WaptiaAutoUpdateManager.instance.appsNotifier,
          builder: (context, apps, _) {
            final visibleApps = apps.where((a) => !a.superadminOnly || isSuperadmin).toList();
            final pendingUpdates = visibleApps.where((a) => a.isInstalled && a.hasUpdate).toList();
            final upToDateApps = visibleApps.where((a) => a.isInstalled && !a.hasUpdate).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Status Banner Header
            _buildHeaderBanner(context, pendingUpdates.length),
            const SizedBox(height: 20),

            // Pending Updates Section
            if (pendingUpdates.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "PENDING UPDATES (${pendingUpdates.length})",
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AcousticColors.sonarCyan,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const _WaptiaSpinningRefreshButton(),
                ],
              ),
              const SizedBox(height: 8),
              ...pendingUpdates.map((app) => _buildUpdateCard(context, app)),
              const SizedBox(height: 24),
            ],

            // Up-to-date Installed Apps Section
            Row(
              children: [
                Text(
                  "UP TO DATE (${upToDateApps.length})",
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AcousticColors.steel,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (upToDateApps.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AcousticColors.darkCarbon,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text("No installed apps found yet.", style: GoogleFonts.outfit(color: AcousticColors.steel)),
                ),
              )
            else
              ...upToDateApps.map((app) => _buildUpToDateCard(app)),
          ],
        );
      },
    );
  },
);
}

  Widget _buildHeaderBanner(BuildContext context, int pendingCount) {
    if (pendingCount > 0) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AcousticColors.sonarCyan.withValues(alpha: 0.15),
              AcousticColors.darkCarbon,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AcousticColors.sonarCyan.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bolt_rounded, color: AcousticColors.sonarCyan, size: 24),
                const SizedBox(width: 10),
                Text(
                  "$pendingCount Updates Available",
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AcousticColors.titanium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              "Differential patches and APK packages ready on update.infortts.site",
              style: GoogleFonts.outfit(fontSize: 12, color: AcousticColors.steel),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ValueListenableBuilder<bool>(
                    valueListenable: WaptiaAutoUpdateManager.instance.isBatchUpdating,
                    builder: (context, isBatch, _) {
                      return ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AcousticColors.sonarCyan,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: isBatch
                            ? null
                            : () async {
                                final updated = await WaptiaAutoUpdateManager.instance.updateAllPending();
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("✓ Successfully updated $updated applications from update.infortts.site"),
                                    backgroundColor: AcousticColors.obsidian,
                                  ),
                                );
                              },
                        icon: isBatch
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                            : const Icon(Icons.update_rounded, size: 18),
                        label: Text(
                          isBatch ? 'Updating Fleet...' : 'Update All ($pendingCount Apps)',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AcousticColors.darkCarbon,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "All Applications Up to Date",
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AcousticColors.titanium),
                ),
                Text(
                  "Synchronized with Infortts Single-Domain OTA Node (update.infortts.site)",
                  style: GoogleFonts.outfit(fontSize: 12, color: AcousticColors.steel),
                ),
              ],
            ),
          ),
          const _WaptiaSpinningRefreshButton(),
        ],
      ),
    );
  }

  Widget _buildUpdateCard(BuildContext context, AppInstallState app) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AcousticColors.darkCarbon,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AcousticColors.sonarCyan.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AcousticColors.obsidian,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AcousticColors.sonarCyan.withValues(alpha: 0.4)),
                ),
                child: Center(
                  child: Text(
                    app.name.substring(0, app.name.length >= 2 ? 2 : 1).toUpperCase(),
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AcousticColors.sonarCyan),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(app.name, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AcousticColors.titanium)),
                    Row(
                      children: [
                        Text('v${app.installedVersion}', style: GoogleFonts.outfit(fontSize: 12, color: AcousticColors.steel)),
                        Icon(Icons.arrow_forward_rounded, size: 12, color: AcousticColors.sonarCyan),
                        Text('v${app.latestVersion} (Build ${app.latestBuild})', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AcousticColors.sonarCyan)),
                      ],
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AcousticColors.sonarCyan,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: app.isDownloading ? null : () => WaptiaAutoUpdateManager.instance.updateApp(app.slug),
                child: app.isDownloading
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : Text('Update', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          if (app.isDownloading) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOutCubic,
                tween: Tween<double>(
                  begin: 0.0,
                  end: app.downloadProgress.clamp(0.0, 1.0),
                ),
                builder: (context, value, _) {
                  return LinearProgressIndicator(
                    value: value > 0 ? value : (app.downloadProgress > 0 ? app.downloadProgress : null),
                    minHeight: 6,
                    backgroundColor: AcousticColors.obsidian,
                    valueColor: AlwaysStoppedAnimation<Color>(AcousticColors.sonarCyan),
                  );
                },
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  app.totalMb > 0
                      ? '${app.downloadedMb.toStringAsFixed(1)} MB / ${app.totalMb.toStringAsFixed(1)} MB (${(app.downloadProgress * 100).toInt()}%)'
                      : (app.downloadProgress > 0
                          ? '${(app.downloadProgress * 100).toInt()}% • ${app.downloadStatus.isNotEmpty ? app.downloadStatus : "Updating"}'
                          : 'Connecting...'),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AcousticColors.steel,
                  ),
                ),
                if (app.downloadSpeed.isNotEmpty)
                  Text(
                    app.downloadSpeed,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AcousticColors.sonarCyan,
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AcousticColors.obsidian,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: app.releaseNotes.map((r) => Text(r, style: GoogleFonts.outfit(fontSize: 11, color: AcousticColors.titanium))).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpToDateCard(AppInstallState app) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AcousticColors.darkCarbon,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AcousticColors.steel.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AcousticColors.obsidian,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                app.name.substring(0, app.name.length >= 2 ? 2 : 1).toUpperCase(),
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AcousticColors.steel, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(app.name, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AcousticColors.titanium)),
                Text('${app.packageName} • v${app.installedVersion}', style: GoogleFonts.outfit(fontSize: 11, color: AcousticColors.steel)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('Up to date', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1F2937),
              foregroundColor: const Color(0xFF38BDF8),
              side: const BorderSide(color: Color(0xFF38BDF8), width: 1),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            icon: const Icon(Icons.play_arrow_rounded, size: 14, color: Color(0xFF38BDF8)),
            onPressed: () => WaptiaAutoUpdateManager.instance.openApp(app.packageName),
            label: Text('Open', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. AUTO-UPDATE POLICY & SETTINGS TAB
// ─────────────────────────────────────────────────────────────────────────────

class WaptiaPolicyWorkspace extends StatefulWidget {
  const WaptiaPolicyWorkspace({super.key});

  @override
  State<WaptiaPolicyWorkspace> createState() => _WaptiaPolicyWorkspaceState();
}

class _WaptiaPolicyWorkspaceState extends State<WaptiaPolicyWorkspace> with WidgetsBindingObserver {
  bool _canInstallPackages = false;
  bool _notificationGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshPermissions();
    }
  }

  Future<void> _refreshPermissions() async {
    final canInst = await WaptiaAutoUpdateManager.instance.canRequestPackageInstalls();
    final notif = await WaptiaAutoUpdateManager.instance.isNotificationPermissionGranted();
    if (mounted) {
      setState(() {
        _canInstallPackages = canInst;
        _notificationGranted = notif;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mgr = WaptiaAutoUpdateManager.instance;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. SYSTEM PERMISSIONS & PACKAGE INSTALLATION (Direct access to Android Unknown App Sources)
        Text(
          "SYSTEM PERMISSIONS & INSTALLATION",
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AcousticColors.sonarCyan,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),

        Container(
          decoration: BoxDecoration(
            color: AcousticColors.darkCarbon,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AcousticColors.steel.withValues(alpha: 0.15)),
          ),
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _canInstallPackages
                        ? Colors.green.withValues(alpha: 0.15)
                        : const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _canInstallPackages ? Icons.verified_user_rounded : Icons.security_rounded,
                    color: _canInstallPackages ? Colors.greenAccent : const Color(0xFFF59E0B),
                    size: 22,
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Install Unknown Apps",
                        style: GoogleFonts.outfit(
                          color: AcousticColors.titanium,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _canInstallPackages
                            ? Colors.green.withValues(alpha: 0.2)
                            : const Color(0xFFF59E0B).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _canInstallPackages ? "Configured" : "Action Required",
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _canInstallPackages ? Colors.greenAccent : const Color(0xFFF59E0B),
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    "Allow Waptia Store to install APKs & updates directly without redirecting to a browser.",
                    style: GoogleFonts.outfit(color: AcousticColors.steel, fontSize: 12),
                  ),
                ),
                trailing: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canInstallPackages ? AcousticColors.darkCarbon : AcousticColors.sonarCyan,
                    foregroundColor: _canInstallPackages ? AcousticColors.sonarCyan : Colors.black,
                    side: BorderSide(color: AcousticColors.sonarCyan, width: 1),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.tune_rounded, size: 14),
                  label: Text("Configure", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12)),
                  onPressed: () async {
                    await mgr.requestInstallPermission();
                    await Future.delayed(const Duration(milliseconds: 500));
                    _refreshPermissions();
                  },
                ),
              ),
              Divider(height: 1, color: AcousticColors.obsidian),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _notificationGranted
                        ? Colors.green.withValues(alpha: 0.15)
                        : AcousticColors.sonarCyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _notificationGranted ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                    color: _notificationGranted ? Colors.greenAccent : AcousticColors.sonarCyan,
                    size: 22,
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "System Notifications",
                        style: GoogleFonts.outfit(
                          color: AcousticColors.titanium,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _notificationGranted
                            ? Colors.green.withValues(alpha: 0.2)
                            : AcousticColors.steel.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _notificationGranted ? "Enabled" : "Disabled",
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _notificationGranted ? Colors.greenAccent : AcousticColors.steel,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    "Receive alerts when package downloads complete, apps finish installing, or updates are ready.",
                    style: GoogleFonts.outfit(color: AcousticColors.steel, fontSize: 12),
                  ),
                ),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _notificationGranted ? AcousticColors.darkCarbon : const Color(0xFF1F2937),
                    foregroundColor: _notificationGranted ? AcousticColors.steel : AcousticColors.sonarCyan,
                    side: BorderSide(
                      color: _notificationGranted
                          ? AcousticColors.steel.withValues(alpha: 0.3)
                          : AcousticColors.sonarCyan,
                      width: 1,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    await mgr.requestNotificationPermission();
                    await Future.delayed(const Duration(milliseconds: 500));
                    _refreshPermissions();
                  },
                  child: Text(
                    _notificationGranted ? "Granted" : "Enable",
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // 2. FLEET AUTO-UPDATE POLICY
        Text(
          "FLEET AUTO-UPDATE POLICY",
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AcousticColors.sonarCyan,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),

        Container(
          decoration: BoxDecoration(
            color: AcousticColors.darkCarbon,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AcousticColors.steel.withValues(alpha: 0.15)),
          ),
          child: Column(
            children: [
              SwitchListTile(
                title: Text("Automatic Fleet Updates", style: GoogleFonts.outfit(color: AcousticColors.titanium, fontWeight: FontWeight.bold)),
                subtitle: Text("Check update.infortts.site and automatically install patches in background like F-Droid", style: GoogleFonts.outfit(color: AcousticColors.steel, fontSize: 12)),
                value: mgr.autoUpdateMaster,
                activeTrackColor: AcousticColors.sonarCyan,
                onChanged: (val) async {
                  await mgr.setAutoUpdateMaster(val);
                  setState(() {});
                },
              ),
              Divider(height: 1, color: AcousticColors.obsidian),
              SwitchListTile(
                title: Text("Silent Differential OTA Patches", style: GoogleFonts.outfit(color: AcousticColors.titanium, fontWeight: FontWeight.bold)),
                subtitle: Text("Apply instant bytecode patches without prompting for APK reinstall", style: GoogleFonts.outfit(color: AcousticColors.steel, fontSize: 12)),
                value: mgr.silentPatches,
                activeTrackColor: AcousticColors.sonarCyan,
                onChanged: (val) async {
                  await mgr.setSilentPatches(val);
                  setState(() {});
                },
              ),
              Divider(height: 1, color: AcousticColors.obsidian),
              SwitchListTile(
                title: Text("Download Over Wi-Fi Only", style: GoogleFonts.outfit(color: AcousticColors.titanium, fontWeight: FontWeight.bold)),
                subtitle: Text("Preserve mobile cellular data during large APK downloads", style: GoogleFonts.outfit(color: AcousticColors.steel, fontSize: 12)),
                value: mgr.wifiOnly,
                activeTrackColor: AcousticColors.sonarCyan,
                onChanged: (val) async {
                  await mgr.setWifiOnly(val);
                  setState(() {});
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // 3. SYNC FREQUENCY
        Text(
          "SYNC FREQUENCY",
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AcousticColors.sonarCyan,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AcousticColors.darkCarbon,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AcousticColors.steel.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Background Update Check Interval", style: GoogleFonts.outfit(color: AcousticColors.titanium, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [15, 60, 360, 1440].map((mins) {
                  final isSel = mgr.checkIntervalMinutes == mins;
                  final label = mins == 15 ? '15 Minutes' : (mins == 60 ? '1 Hour' : (mins == 360 ? '6 Hours' : 'Daily'));
                  return ChoiceChip(
                    label: Text(label),
                    selected: isSel,
                    selectedColor: AcousticColors.sonarCyan,
                    backgroundColor: AcousticColors.obsidian,
                    labelStyle: GoogleFonts.outfit(
                      color: isSel ? Colors.black : AcousticColors.steel,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                    ),
                    onSelected: (selected) async {
                      if (selected) {
                        await mgr.setCheckInterval(mins);
                        setState(() {});
                      }
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // 4. CENTRAL REPOSITORY STATUS
        Text(
          "CENTRAL REPOSITORY STATUS",
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AcousticColors.sonarCyan,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AcousticColors.obsidian,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AcousticColors.steel.withValues(alpha: 0.15)),
          ),
          child: Column(
            children: [
              _buildStatusRow("Distribution Server", "https://update.infortts.site"),
              const SizedBox(height: 8),
              _buildStatusRow("Protocol", "Infortts Quantum OTA V1"),
              const SizedBox(height: 8),
              _buildStatusRow("Fleet Catalog", "28 Verified Ecosystem Applications"),
              const SizedBox(height: 8),
              _buildStatusRow("Signatures", "Native SHA-256 Fingerprint Validation"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow(String label, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.outfit(color: AcousticColors.steel, fontSize: 12)),
        Text(val, style: GoogleFonts.jetBrainsMono(color: AcousticColors.sonarCyan, fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. APP DETAILS MODAL (Available on more devices & Infortts DB Ratings)
// ─────────────────────────────────────────────────────────────────────────────

class AppDetailsModal extends StatefulWidget {
  final AppInstallState app;
  const AppDetailsModal({super.key, required this.app});

  @override
  State<AppDetailsModal> createState() => _AppDetailsModalState();
}

class _AppDetailsModalState extends State<AppDetailsModal> {
  bool _devicesExpanded = true;
  List<GlycocalyxDevice> _devices = [];
  bool _loadingDevices = true;
  final Set<String> _installingDevices = {};
  final Set<String> _installedDevices = {};

  int _selectedRating = 0;
  String? _userReviewText;
  bool _submittingRating = false;
  bool _showReviewInput = false;
  final TextEditingController _reviewController = TextEditingController();

  AppRatingSummary? _ratingSummary;

  @override
  void initState() {
    super.initState();
    _selectedRating = widget.app.userRating ?? 0;
    _userReviewText = widget.app.userReview;
    if (_userReviewText != null && _userReviewText!.isNotEmpty) {
      _reviewController.text = _userReviewText!;
    }
    _loadDevices();
    _loadRatingsSummary();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _loadDevices() async {
    final devs = await WaptiaAutoUpdateManager.instance.fetchGlycocalyxDevices();
    if (mounted) {
      setState(() {
        _devices = devs;
        _loadingDevices = false;
      });
    }
  }

  Future<void> _loadRatingsSummary() async {
    final summary = await WaptiaAutoUpdateManager.instance.fetchAppRatings(widget.app.slug);
    if (mounted) {
      setState(() {
        _ratingSummary = summary;
      });
    }
  }

  Future<void> _submitRating(int rating, {String? review}) async {
    setState(() {
      _selectedRating = rating;
      _submittingRating = true;
    });

    final rev = review ?? _reviewController.text.trim();
    await WaptiaAutoUpdateManager.instance.submitAppRating(
      widget.app.slug,
      rating,
      rev,
    );

    if (mounted) {
      setState(() {
        _submittingRating = false;
        if (rev.isNotEmpty) {
          _userReviewText = rev;
          _showReviewInput = false;
        }
      });
      _loadRatingsSummary();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✓ Rating ($rating★) saved to Infortts DB',
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFF10B981),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _installOnRemoteDevice(GlycocalyxDevice dev) async {
    setState(() {
      _installingDevices.add(dev.id);
    });

    await WaptiaAutoUpdateManager.instance.installOnDevice(dev.id, widget.app.slug);

    if (mounted) {
      setState(() {
        _installingDevices.remove(dev.id);
        _installedDevices.add(dev.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✓ Installation initiated on ${dev.name} via Glycocalyx',
            style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          backgroundColor: AcousticColors.sonarCyan,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  IconData _getDeviceIcon(String type) {
    switch (type.toLowerCase()) {
      case 'tablet':
        return Icons.tablet_android_rounded;
      case 'desktop':
        return Icons.laptop_chromebook_rounded;
      case 'tv':
        return Icons.tv_rounded;
      default:
        return Icons.phone_android_rounded;
    }
  }

  Widget _buildMetricBadge(String label, String sublabel, {IconData? icon}) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: const Color(0xFFFBBF24)),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AcousticColors.titanium),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          sublabel,
          style: GoogleFonts.outfit(fontSize: 11, color: AcousticColors.steel),
        ),
      ],
    );
  }

  Widget _buildRow(String label, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.outfit(color: AcousticColors.steel, fontSize: 12)),
        Text(val, style: GoogleFonts.jetBrainsMono(color: AcousticColors.titanium, fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('health') || cat.contains('medic')) {
      return Icons.health_and_safety_rounded;
    } else if (cat.contains('financ') || cat.contains('trad') || cat.contains('money')) {
      return Icons.candlestick_chart_rounded;
    } else if (cat.contains('secur') || cat.contains('auth')) {
      return Icons.shield_rounded;
    } else if (cat.contains('ai') || cat.contains('intellig')) {
      return Icons.psychology_rounded;
    } else if (cat.contains('audio') || cat.contains('music')) {
      return Icons.graphic_eq_rounded;
    } else if (cat.contains('ar') || cat.contains('vr') || cat.contains('vision')) {
      return Icons.view_in_ar_rounded;
    } else if (cat.contains('iot') || cat.contains('sensor')) {
      return Icons.sensors_rounded;
    } else if (cat.contains('comm') || cat.contains('chat')) {
      return Icons.chat_bubble_rounded;
    } else if (cat.contains('edu') || cat.contains('learn')) {
      return Icons.school_rounded;
    }
    return Icons.hub_rounded;
  }

  void _showScreenshotLightbox(
    BuildContext context,
    List<String> screenshots,
    int initialIndex,
    String appName,
    List<AppScreenMeta> screens,
  ) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (ctx) {
        int currentIndex = initialIndex;
        final pageController = PageController(initialPage: initialIndex);

        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final activeScreen = screens[currentIndex % screens.length];

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                children: [
                  // Lightbox Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appName,
                            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          Text(
                            'Screen ${currentIndex + 1} of ${screenshots.length} • ${activeScreen.badge}',
                            style: GoogleFonts.jetBrainsMono(fontSize: 12, color: AcousticColors.sonarCyan),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Screenshot Carousel
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PageView.builder(
                          controller: pageController,
                          itemCount: screenshots.length,
                          onPageChanged: (idx) {
                            setDialogState(() {
                              currentIndex = idx;
                            });
                          },
                          itemBuilder: (context, idx) {
                            final screen = screens[idx % screens.length];
                            return Center(
                              child: Container(
                                constraints: const BoxConstraints(maxWidth: 420),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AcousticColors.sonarCyan.withValues(alpha: 0.3)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.6),
                                      blurRadius: 24,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Image.network(
                                  screenshots[idx],
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => _buildMockupScreenshot(
                                    idx,
                                    screen,
                                    isExpanded: true,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        // Left/Right Controls
                        if (currentIndex > 0)
                          Positioned(
                            left: 0,
                            child: IconButton(
                              style: IconButton.styleFrom(backgroundColor: Colors.black54),
                              icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 36),
                              onPressed: () {
                                pageController.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                            ),
                          ),
                        if (currentIndex < screenshots.length - 1)
                          Positioned(
                            right: 0,
                            child: IconButton(
                              style: IconButton.styleFrom(backgroundColor: Colors.black54),
                              icon: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 36),
                              onPressed: () {
                                pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Feature Caption Bar
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111827),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AcousticColors.steel.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          activeScreen.title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            color: AcousticColors.titanium,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          activeScreen.badge,
                          style: GoogleFonts.jetBrainsMono(
                            color: AcousticColors.sonarCyan,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMockupScreenshot(int index, AppScreenMeta screen, {bool isExpanded = false}) {
    final domainIcon = _getCategoryIcon(widget.app.category);
    return Container(
      width: isExpanded ? 360 : 175,
      height: isExpanded ? 580 : 285,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0F172A),
            Color(0xFF020617),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AcousticColors.steel.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Device status bar mockup
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('12:00', style: GoogleFonts.jetBrainsMono(fontSize: 9, color: AcousticColors.steel)),
              Row(
                children: [
                  Icon(Icons.wifi_rounded, size: 10, color: AcousticColors.steel),
                  const SizedBox(width: 4),
                  Icon(Icons.battery_5_bar_rounded, size: 10, color: AcousticColors.steel),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Domain Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AcousticColors.sonarCyan.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AcousticColors.sonarCyan.withValues(alpha: 0.4)),
            ),
            child: Text(
              screen.badge,
              style: GoogleFonts.jetBrainsMono(
                fontSize: isExpanded ? 9 : 7,
                fontWeight: FontWeight.bold,
                color: AcousticColors.sonarCyan,
              ),
            ),
          ),
          const Spacer(),

          // Centered Domain Icon & Visual Wireframe
          Center(
            child: Container(
              width: isExpanded ? 64 : 44,
              height: isExpanded ? 64 : 44,
              decoration: BoxDecoration(
                color: AcousticColors.obsidian,
                shape: BoxShape.circle,
                border: Border.all(color: AcousticColors.sonarCyan.withValues(alpha: 0.6)),
              ),
              child: Icon(
                domainIcon,
                color: AcousticColors.sonarCyan,
                size: isExpanded ? 32 : 22,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Visual Mock Wireframe dependent on screen type
          if (screen.type == 'chart') ...[
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [16, 28, 20, 36, 24, 32].map((h) => Container(
                  width: isExpanded ? 8 : 4,
                  height: (h * (isExpanded ? 1.5 : 0.8)),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: AcousticColors.sonarCyan.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(2),
                  ),
                )).toList(),
              ),
            ),
          ] else if (screen.type == 'flow') ...[
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
                  Container(width: 16, height: 2, color: AcousticColors.steel),
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: AcousticColors.sonarCyan, shape: BoxShape.circle)),
                  Container(width: 16, height: 2, color: AcousticColors.steel),
                  Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFF38BDF8), shape: BoxShape.circle)),
                ],
              ),
            ),
          ] else ...[
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_outlined, size: 10, color: AcousticColors.sonarCyan),
                    const SizedBox(width: 4),
                    Text(
                      widget.app.category.toUpperCase(),
                      style: GoogleFonts.jetBrainsMono(fontSize: 8, color: AcousticColors.titanium),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 10),
          Center(
            child: Text(
              widget.app.name,
              style: GoogleFonts.outfit(
                fontSize: isExpanded ? 15 : 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2),
          Center(
            child: Text(
              screen.title,
              style: GoogleFonts.outfit(
                fontSize: isExpanded ? 12 : 9,
                color: AcousticColors.titanium,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Spacer(),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: AcousticColors.sonarCyan.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified_rounded, size: 10, color: AcousticColors.sonarCyan),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Verified Infortts',
                    style: GoogleFonts.outfit(fontSize: 8, color: AcousticColors.sonarCyan, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final avgRating = _ratingSummary?.averageRating ?? app.rating;
    final totalRatings = _ratingSummary?.totalRatings ?? app.ratingCount;
    final screens = getAppScreens(app.slug, app.category, app.name);
    final isGuest = InforttsAuthManager.instance.isGuest || !InforttsAuthManager.instance.isAuthenticated;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.90),
      child: ListView(
        children: [
          // App Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFF0B0F19),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF1F2937)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.network(
                  'https://cdn.infortts.site/icons/${app.slug}.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Center(
                    child: Text(
                      app.name.substring(0, app.name.length >= 2 ? 2 : 1).toUpperCase(),
                      style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF38BDF8)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(app.name, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFFF9FAFB))),
                    const SizedBox(height: 2),
                    Text(app.packageName, style: GoogleFonts.jetBrainsMono(fontSize: 11, color: AcousticColors.sonarCyan)),
                    const SizedBox(height: 4),
                    Text('v${app.latestVersion} (Build ${app.latestBuild}) • Infortts Ecosystem',
                        style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF9CA3AF))),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Google Play Store Metrics Summary Bar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: AcousticColors.obsidian,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AcousticColors.steel.withValues(alpha: 0.15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricBadge(
                  avgRating.toStringAsFixed(1),
                  '$totalRatings reviews',
                  icon: Icons.star_rounded,
                ),
                Container(height: 24, width: 1, color: AcousticColors.steel.withValues(alpha: 0.2)),
                _buildMetricBadge('55 MB', 'Direct APK'),
                Container(height: 24, width: 1, color: AcousticColors.steel.withValues(alpha: 0.2)),
                _buildMetricBadge('Rated for 3+', 'Sovereign', icon: Icons.verified_user_rounded),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── App Screenshots & Domain Feature Highlights ───────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.photo_library_outlined, size: 18, color: AcousticColors.sonarCyan),
                      const SizedBox(width: 8),
                      Text(
                        'App Preview & Features',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AcousticColors.titanium,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${screens.length} Screens',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      color: AcousticColors.sonarCyan,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 285,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: app.screenshots.isNotEmpty ? app.screenshots.length : screens.length,
                  itemBuilder: (context, index) {
                    final screen = screens[index % screens.length];
                    final url = app.screenshots.isNotEmpty
                        ? app.screenshots[index]
                        : 'https://waptia.infortts.site/screenshots/${app.slug}_${index + 1}.png';

                    return GestureDetector(
                      onTap: () {
                        final list = app.screenshots.isNotEmpty
                            ? app.screenshots
                            : List.generate(screens.length, (i) => 'https://waptia.infortts.site/screenshots/${app.slug}_${i + 1}.png');
                        _showScreenshotLightbox(context, list, index, app.name, screens);
                      },
                      child: Container(
                        width: 170,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: AcousticColors.obsidian,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AcousticColors.steel.withValues(alpha: 0.2)),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              url,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildMockupScreenshot(index, screen),
                            ),
                            // Gradient caption overlay
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.85),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      screen.title,
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      screen.badge,
                                      style: GoogleFonts.jetBrainsMono(
                                        color: AcousticColors.sonarCyan,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Expand hint icon
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.fullscreen_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Available on more devices (Glycocalyx Cross-Device Integration) ────
          Container(
            decoration: BoxDecoration(
              color: AcousticColors.obsidian,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AcousticColors.steel.withValues(alpha: 0.2)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () {
                    setState(() {
                      _devicesExpanded = !_devicesExpanded;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Icon(Icons.devices_rounded, size: 20, color: AcousticColors.sonarCyan),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Available on more devices',
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AcousticColors.titanium,
                            ),
                          ),
                        ),
                        Icon(
                          _devicesExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          color: AcousticColors.steel,
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_devicesExpanded) ...[
                  Divider(height: 1, color: AcousticColors.steel.withValues(alpha: 0.15)),
                  // 1. Current Device Tile
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AcousticColors.steel.withValues(alpha: 0.1)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.phone_android_rounded,
                            color: AcousticColors.sonarCyan,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'This Device',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFF9FAFB),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                app.isInstalled ? 'Installed • v${app.installedVersion}' : 'Not installed on this device',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: app.isInstalled ? const Color(0xFF10B981) : AcousticColors.steel,
                                  fontWeight: app.isInstalled ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (app.isInstalled)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
                              const SizedBox(width: 4),
                              Text('Installed', style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF10B981), fontWeight: FontWeight.w600)),
                            ],
                          )
                        else
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AcousticColors.sonarCyan,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              elevation: 0,
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              WaptiaAutoUpdateManager.instance.installApp(app.slug);
                            },
                            child: Text('Install', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                  ),

                  // 2. Remote devices or Guest Sign-in prompt
                  if (isGuest) ...[
                    Container(
                      margin: const EdgeInsets.all(12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AcousticColors.sonarCyan.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.cloud_sync_rounded, color: AcousticColors.sonarCyan, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cross-Device Fleet Sync',
                                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Sign in to remotely push ${app.name} across your connected tablets, workstations, and nodes.',
                                  style: GoogleFonts.outfit(color: AcousticColors.steel, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              showInforttsAuthBottomSheet(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AcousticColors.sonarCyan,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text('Sign In', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 11)),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Authenticated: Render real Glycocalyx remote devices
                    if (_loadingDevices)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF38BDF8)),
                          ),
                        ),
                      )
                    else if (_devices.where((d) => !d.isCurrent && d.id != 'current_device').isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'No other devices connected to this account.',
                          style: GoogleFonts.outfit(color: AcousticColors.steel, fontSize: 12),
                        ),
                      )
                    else
                      ..._devices.where((d) => !d.isCurrent && d.id != 'current_device').map((device) {
                        final isInstalling = _installingDevices.contains(device.id);
                        final isInstalled = _installedDevices.contains(device.id);

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: AcousticColors.steel.withValues(alpha: 0.1)),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  _getDeviceIcon(device.type),
                                  color: AcousticColors.sonarCyan,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      device.name,
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFFF9FAFB),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      device.type,
                                      style: GoogleFonts.outfit(fontSize: 12, color: AcousticColors.steel),
                                    ),
                                  ],
                                ),
                              ),
                              if (isInstalling)
                                const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF38BDF8)),
                                )
                              else if (isInstalled)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
                                    const SizedBox(width: 4),
                                    Text('Installed', style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF10B981), fontWeight: FontWeight.w600)),
                                  ],
                                )
                              else
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AcousticColors.sonarCyan,
                                    side: BorderSide(color: AcousticColors.sonarCyan.withValues(alpha: 0.8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  ),
                                  onPressed: () => _installOnRemoteDevice(device),
                                  child: Text('Install', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                        );
                      }),
                  ],
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Rate this app (Infortts DB Ratings & Reviews) ─────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AcousticColors.obsidian,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AcousticColors.steel.withValues(alpha: 0.2)),
            ),
            child: isGuest
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ratings & Reviews',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AcousticColors.titanium,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Sovereign Infortts Ecosystem',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: AcousticColors.steel,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 18),
                              const SizedBox(width: 4),
                              Text(
                                avgRating.toStringAsFixed(1),
                                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AcousticColors.titanium),
                              ),
                              Text(' ($totalRatings)', style: GoogleFonts.outfit(fontSize: 12, color: AcousticColors.steel)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AcousticColors.steel.withValues(alpha: 0.15)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sign in to rate & review this app',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Ratings and reviews are restricted to verified Infortts accounts to preserve cryptographic trust and auditability.',
                              style: GoogleFonts.outfit(fontSize: 11, color: AcousticColors.steel),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AcousticColors.sonarCyan,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  elevation: 0,
                                ),
                                icon: const Icon(Icons.login_rounded, size: 16),
                                label: Text(
                                  'Sign in with Glycocalyx IAM',
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                  showInforttsAuthBottomSheet(context);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Rate this app',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AcousticColors.titanium,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Tell others in the ecosystem what you think',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: AcousticColors.steel,
                                ),
                              ),
                            ],
                          ),
                          if (_selectedRating > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$_selectedRating ★ Saved',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF10B981),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // 5 interactive stars
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(5, (index) {
                          final starNum = index + 1;
                          final isFilled = starNum <= _selectedRating;
                          return InkWell(
                            onTap: () => _submitRating(starNum),
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                                size: 38,
                                color: isFilled ? const Color(0xFFFBBF24) : AcousticColors.steel.withValues(alpha: 0.6),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 8),
                      // Write a review toggle / text
                      if (!_showReviewInput && (_userReviewText == null || _userReviewText!.isEmpty))
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _showReviewInput = true;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              'Write a review',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AcousticColors.sonarCyan,
                              ),
                            ),
                          ),
                        )
                      else if (_userReviewText != null && _userReviewText!.isNotEmpty && !_showReviewInput)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0B0F19),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AcousticColors.steel.withValues(alpha: 0.15)),
                              ),
                              child: Text(
                                '“$_userReviewText”',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: AcousticColors.titanium,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _showReviewInput = true;
                                });
                              },
                              child: Text(
                                'Edit your review',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AcousticColors.sonarCyan,
                                ),
                              ),
                            ),
                          ],
                        ),

                      // Review input field
                      if (_showReviewInput) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: _reviewController,
                          maxLines: 3,
                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Describe your experience with ${app.name}...',
                            hintStyle: GoogleFonts.outfit(color: AcousticColors.steel, fontSize: 12),
                            filled: true,
                            fillColor: const Color(0xFF0B0F19),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AcousticColors.steel.withValues(alpha: 0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AcousticColors.sonarCyan),
                            ),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _showReviewInput = false;
                                });
                              },
                              child: Text('Cancel', style: GoogleFonts.outfit(color: AcousticColors.steel)),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AcousticColors.sonarCyan,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                              onPressed: _submittingRating ? null : () => _submitRating(_selectedRating > 0 ? _selectedRating : 5),
                              child: Text(
                                _submittingRating ? 'Saving...' : 'Submit to Infortts DB',
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
          ),

          const SizedBox(height: 20),

          // Automatic Updates Setting
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AcousticColors.obsidian,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AcousticColors.steel.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Automatic OTA Updates", style: GoogleFonts.outfit(color: AcousticColors.titanium, fontSize: 13, fontWeight: FontWeight.w600)),
                Switch(
                  value: app.autoUpdateEnabled,
                  activeTrackColor: AcousticColors.sonarCyan,
                  onChanged: (val) {
                    WaptiaAutoUpdateManager.instance.toggleAppAutoUpdate(app.slug, val);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Release Notes
          Text("RELEASE NOTES", style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: AcousticColors.sonarCyan, letterSpacing: 1.0)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AcousticColors.obsidian,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AcousticColors.steel.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: app.releaseNotes.map((note) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text(note, style: GoogleFonts.outfit(fontSize: 13, color: AcousticColors.titanium)),
              )).toList(),
            ),
          ),

          const SizedBox(height: 20),

          // Distribution & Verification
          Text("DISTRIBUTION & VERIFICATION", style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: AcousticColors.sonarCyan, letterSpacing: 1.0)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AcousticColors.obsidian,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _buildRow("OTA Cluster", "https://update.infortts.site"),
                const SizedBox(height: 8),
                _buildRow("Direct APK", "update.infortts.site/download/${app.slug}.apk"),
                const SizedBox(height: 8),
                _buildRow("Integrity", "SHA-256 Verified Signature"),
                const SizedBox(height: 8),
                _buildRow("Infortts DB", "postgresql://infortts/ratings"),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Install / Open / Update Action Buttons
          if (app.isInstalled) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AcousticColors.sonarCyan,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.launch_rounded, size: 20),
                    label: Text('Open App', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.pop(context);
                      WaptiaAutoUpdateManager.instance.openApp(app.packageName);
                    },
                  ),
                ),
                if (app.hasUpdate) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.system_update_alt_rounded, size: 18),
                      label: Text('Update to v${app.latestVersion}', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.pop(context);
                        WaptiaAutoUpdateManager.instance.updateApp(app.slug);
                      },
                    ),
                  ),
                ],
              ],
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AcousticColors.sonarCyan,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: Text('Install (In-App)', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.pop(context);
                      WaptiaAutoUpdateManager.instance.installApp(app.slug);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AcousticColors.sonarCyan,
                    side: BorderSide(color: AcousticColors.sonarCyan),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.launch_rounded, size: 18),
                  label: Text('Open', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.pop(context);
                    WaptiaAutoUpdateManager.instance.openApp(app.packageName);
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}