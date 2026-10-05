import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infortts_shared/infortts_shared.dart';

import 'auto_update_manager.dart';
import 'models.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WaptiaAutoUpdateManager.instance.initialize();
  runApp(const WaptiaStoreApp());
}

class WaptiaStoreApp extends StatelessWidget {
  const WaptiaStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Waptia Store',
      debugShowCheckedModeBanner: false,
      theme: AcousticTheme.darkTheme,
      home: ValueListenableBuilder<int>(
        valueListenable: WaptiaAutoUpdateManager.instance.pendingUpdatesCount,
        builder: (context, pendingCount, _) {
          return InforttsAppShell(
            appName: 'Waptia Store',
            appDescription: 'Sovereign Fleet App Store & Autonomous OTA Package Manager',
            appVersion: '1.2.0',
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
    return ValueListenableBuilder<List<AppInstallState>>(
      valueListenable: WaptiaAutoUpdateManager.instance.appsNotifier,
      builder: (context, apps, _) {
        final filtered = apps.where((app) {
          final matchesSearch = app.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              app.slug.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              app.packageName.toLowerCase().contains(_searchQuery.toLowerCase());
          final matchesCat = _selectedCategory == 'All' || app.category.toLowerCase() == _selectedCategory.toLowerCase();
          return matchesSearch && matchesCat;
        }).toList();

        return Column(
          children: [
            // Search & Category Header
            Container(
              padding: const EdgeInsets.all(16.0),
              color: AcousticColors.obsidian,
              child: Column(
                children: [
                  TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: GoogleFonts.outfit(color: AcousticColors.titanium),
                    decoration: InputDecoration(
                      hintText: 'Search 28 ecosystem applications...',
                      hintStyle: GoogleFonts.outfit(color: AcousticColors.steel),
                      prefixIcon: const Icon(Icons.search, color: AcousticColors.sonarCyan),
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
                        borderSide: const BorderSide(color: AcousticColors.sonarCyan),
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
              LinearProgressIndicator(
                value: app.downloadProgress > 0 ? app.downloadProgress : null,
                backgroundColor: const Color(0xFF0B0F19),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, AppInstallState app) {
    if (app.isDownloading) {
      return const SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8))),
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
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          child: ListView(
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B0F19),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF1F2937)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.network(
                      'https://cdn.infortts.site/icons/${app.slug}.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Center(
                        child: Text(
                          app.name.substring(0, app.name.length >= 2 ? 2 : 1).toUpperCase(),
                          style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF38BDF8)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(app.name, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFFF9FAFB))),
                        Text(app.packageName, style: GoogleFonts.jetBrainsMono(fontSize: 12, color: const Color(0xFF38BDF8))),
                        Text('Latest: v${app.latestVersion} (Build ${app.latestBuild})', style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF9CA3AF))),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
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
                        Navigator.pop(ctx);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
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
                  ],
                ),
              ),
              const SizedBox(height: 24),
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
                          Navigator.pop(ctx);
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
                            Navigator.pop(ctx);
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
                        label: Text('Download APK', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                        onPressed: () {
                          Navigator.pop(ctx);
                          WaptiaAutoUpdateManager.instance.installApp(app.slug);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
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
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. UPDATES TAB (F-Droid Style Batch Updater)
// ─────────────────────────────────────────────────────────────────────────────

class WaptiaUpdatesWorkspace extends StatelessWidget {
  const WaptiaUpdatesWorkspace({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<AppInstallState>>(
      valueListenable: WaptiaAutoUpdateManager.instance.appsNotifier,
      builder: (context, apps, _) {
        final pendingUpdates = apps.where((a) => a.isInstalled && a.hasUpdate).toList();
        final upToDateApps = apps.where((a) => a.isInstalled && !a.hasUpdate).toList();

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
                  TextButton.icon(
                    onPressed: () => WaptiaAutoUpdateManager.instance.checkAllUpdates(),
                    icon: const Icon(Icons.refresh, size: 14, color: AcousticColors.sonarCyan),
                    label: Text("Refresh", style: GoogleFonts.outfit(fontSize: 12, color: AcousticColors.sonarCyan)),
                  ),
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
                const Icon(Icons.bolt_rounded, color: AcousticColors.sonarCyan, size: 24),
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
          IconButton(
            icon: const Icon(Icons.refresh, color: AcousticColors.sonarCyan),
            onPressed: () => WaptiaAutoUpdateManager.instance.checkAllUpdates(),
          ),
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
                        const Icon(Icons.arrow_forward_rounded, size: 12, color: AcousticColors.sonarCyan),
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

class _WaptiaPolicyWorkspaceState extends State<WaptiaPolicyWorkspace> {
  @override
  Widget build(BuildContext context) {
    final mgr = WaptiaAutoUpdateManager.instance;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text("FLEET AUTO-UPDATE POLICY", style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: AcousticColors.sonarCyan, letterSpacing: 1.0)),
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
        Text("SYNC FREQUENCY", style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: AcousticColors.sonarCyan, letterSpacing: 1.0)),
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
        Text("CENTRAL REPOSITORY STATUS", style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: AcousticColors.sonarCyan, letterSpacing: 1.0)),
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