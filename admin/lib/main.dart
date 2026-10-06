import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infortts_shared/infortts_shared.dart';

import 'design_skin.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Design skin for this app (generated; see tools/design-pipeline).
  AppDesignSkin.boot();
  runApp(const WaptiaAdminApp());
}

class WaptiaAdminApp extends StatelessWidget {
  const WaptiaAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Waptia Admin Console',
      debugShowCheckedModeBanner: false,
      theme: AcousticTheme.themedDark(skin: AppDesignSkin.skin),
      home: InforttsAppShell(
        appName: 'Waptia Admin',
        appDescription: 'Central administration console for Infortts app fleet: manage releases, monitor internal test tracks, approve OTA patches, and audit telemetry.',
        appVersion: '2.05.00',
        showSplash: true,
        requireAuth: true,
        allowGuest: false,
        additionalTabs: [
          InforttsTab(
            label: 'Fleet Overview',
            icon: Icons.apps_rounded,
            builder: (_) => const FleetOverviewWorkspace(),
          ),
          InforttsTab(
            label: 'Releases & CI',
            icon: Icons.rocket_launch_outlined,
            builder: (_) => const ReleaseEngineeringWorkspace(),
          ),
          InforttsTab(
            label: 'OTA CDN Engine',
            icon: Icons.cloud_sync_outlined,
            builder: (_) => const OtaEngineWorkspace(),
          ),
          InforttsTab(
            label: 'RBAC Governance',
            icon: Icons.admin_panel_settings_outlined,
            builder: (_) => const RbacGovernanceWorkspace(),
          ),
        ],
        workspaceChild: const FleetOverviewWorkspace(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. FLEET OVERVIEW WORKSPACE
// ─────────────────────────────────────────────────────────────────────────────

class FleetOverviewWorkspace extends StatefulWidget {
  const FleetOverviewWorkspace({super.key});

  @override
  State<FleetOverviewWorkspace> createState() => _FleetOverviewWorkspaceState();
}

class _FleetOverviewWorkspaceState extends State<FleetOverviewWorkspace> {
  String _searchFilter = '';

  final List<Map<String, String>> _fleetApps = const [
    {"name": "Mitochondria", "package": "com.infortts.mitochondria", "version": "v2.07.08", "track": "Internal Live", "category": "Trading & FinTech", "domain": "mitochondria.infortts.site"},
    {"name": "Waptia Store", "package": "com.infortts.waptia", "version": "v2.05.00", "track": "Internal Live", "category": "App Store & OTA", "domain": "waptia.infortts.site"},
    {"name": "Waptia Admin", "package": "com.infortts.waptia.admin", "version": "v2.05.00", "track": "Internal Staged", "category": "Admin & IAM", "domain": "admin.waptia.infortts.site"},
    {"name": "Care4U Client", "package": "com.infortts.care4u", "version": "v2.03.01", "track": "Internal Live", "category": "Healthcare", "domain": "client.care4u.infortts.site"},
    {"name": "Care4U Partner", "package": "com.infortts.care4u.partner", "version": "v2.03.01", "track": "Internal Live", "category": "Healthcare", "domain": "partner.care4u.infortts.site"},
    {"name": "Cardiodictyon", "package": "com.infortts.cardiodictyon", "version": "v2.04.00", "track": "Internal Live", "category": "Telemetry & Control", "domain": "cardiodictyon.infortts.site"},
    {"name": "Cyclomedusa", "package": "com.infortts.cyclomedusa", "version": "v2.04.00", "track": "Internal Live", "category": "Visual Intelligence", "domain": "cyclomedusa.infortts.site"},
    {"name": "Dickinsonia", "package": "com.infortts.dickinsonia", "version": "v2.03.01", "track": "Internal Live", "category": "Memory & Storage", "domain": "dickinsonia.infortts.site"},
    {"name": "Ernietta", "package": "com.infortts.ernietta", "version": "v2.04.00", "track": "Internal Live", "category": "Network Fabric", "domain": "ernietta.infortts.site"},
    {"name": "Fractofusus", "package": "com.infortts.fractofusus", "version": "v2.04.00", "track": "Internal Live", "category": "Swarm Orchestration", "domain": "fractofusus.infortts.site"},
    {"name": "Ikaria", "package": "com.infortts.ikaria", "version": "v2.04.00", "track": "Internal Live", "category": "Core Substrate", "domain": "ikaria.infortts.site"},
    {"name": "Meeseeks", "package": "com.infortts.meeseeks", "version": "v2.05.00", "track": "Internal Live", "category": "Autonomous Agents", "domain": "meeseeks.infortts.site"},
    {"name": "Opabinia", "package": "com.infortts.opabinia", "version": "v2.04.00", "track": "Internal Live", "category": "Media Streamer", "domain": "opabinia.infortts.site"},
    {"name": "Orthrozanclus", "package": "com.infortts.orthrozanclus", "version": "v2.04.00", "track": "Internal Live", "category": "Cyber-Defense", "domain": "orthrozanclus.infortts.site"},
    {"name": "Tridrishti", "package": "com.infortts.tridrishti", "version": "v2.04.00", "track": "Internal Live", "category": "Tri-Cam Sensory", "domain": "tridrishti.infortts.site"},
    {"name": "Yorgia", "package": "com.infortts.yorgia", "version": "v2.04.00", "track": "Internal Live", "category": "Planar Compute", "domain": "yorgia.infortts.site"},
    {"name": "Glycocalyx", "package": "com.infortts.glycocalyx", "version": "v2.06.00", "track": "Internal Live", "category": "SSO Auth Gateway", "domain": "auth.infortts.site"},
    {"name": "Primata", "package": "com.infortts.primata", "version": "v2.01.00", "track": "Internal Staged", "category": "Automated Media", "domain": "primata.infortts.site"},
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _fleetApps.where((app) {
      final q = _searchFilter.toLowerCase();
      return app["name"]!.toLowerCase().contains(q) ||
          app["package"]!.toLowerCase().contains(q) ||
          app["category"]!.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: AcousticColors.obsidian,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "INFORTTS FLEET INVENTORY",
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                      color: AcousticColors.titanium,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AcousticColors.sonarCyan.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AcousticColors.sonarCyan.withOpacity(0.3)),
                    ),
                    child: Text(
                      "${_fleetApps.length} APPS ACTIVE",
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AcousticColors.sonarCyan,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                onChanged: (val) => setState(() => _searchFilter = val),
                style: GoogleFonts.outfit(fontSize: 12, color: AcousticColors.titanium),
                decoration: InputDecoration(
                  hintText: "Search apps by name, package ID, or category...",
                  hintStyle: GoogleFonts.outfit(fontSize: 12, color: AcousticColors.midGray),
                  prefixIcon: Icon(Icons.search, size: 18, color: AcousticColors.sonarCyan),
                  filled: true,
                  fillColor: AcousticColors.black,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, idx) {
              final app = filtered[idx];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AcousticColors.darkCarbon,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AcousticColors.midGray.withOpacity(0.12)),
                ),
                child: Row(
                  children: [
                    Infortts3DLogo(appName: app["name"]!.toLowerCase().replaceAll(' ', ''), size: 36, interactive: false),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                app["name"]!,
                                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AcousticColors.titanium),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AcousticColors.panelBg,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  app["version"]!,
                                  style: GoogleFonts.jetBrainsMono(fontSize: 9, color: AcousticColors.sonarCyan),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            app["package"]!,
                            style: GoogleFonts.jetBrainsMono(fontSize: 10, color: AcousticColors.midGray),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Domain: https://${app["domain"]}",
                            style: GoogleFonts.jetBrainsMono(fontSize: 9, color: AcousticColors.steel),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AcousticColors.sonarCyan.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AcousticColors.sonarCyan.withOpacity(0.2)),
                          ),
                          child: Text(
                            app["track"]!,
                            style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w600, color: AcousticColors.sonarCyan),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          app["category"]!,
                          style: GoogleFonts.outfit(fontSize: 9, color: AcousticColors.midGray),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. RELEASE ENGINEERING WORKSPACE
// ─────────────────────────────────────────────────────────────────────────────

class ReleaseEngineeringWorkspace extends StatelessWidget {
  const ReleaseEngineeringWorkspace({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          "RELEASE PIPELINE CONTROLS",
          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2.0, color: AcousticColors.titanium),
        ),
        const SizedBox(height: 6),
        Text(
          "Manage build gates, validate release scripts, and dispatch internal track bundles.",
          style: GoogleFonts.outfit(fontSize: 11, color: AcousticColors.midGray),
        ),
        const SizedBox(height: 20),
        _buildActionCard(
          title: "Run Swarm Version Synchronization",
          subtitle: "Executes calculate-version.sh against git success tags across all 45+ submodules.",
          actionLabel: "SYNC VERSIONS",
          icon: Icons.sync,
        ),
        const SizedBox(height: 14),
        _buildActionCard(
          title: "Validate Monorepo Release Gate",
          subtitle: "Runs validate-release.sh across all submodules (tests, linters, and clean compilation).",
          actionLabel: "RUN AUDIT",
          icon: Icons.verified_user_outlined,
        ),
        const SizedBox(height: 14),
        _buildActionCard(
          title: "Google Play Internal Track Fastlane Rollout",
          subtitle: "Packages AAB signed bundles and pushes via automated Google Cloud Service Account API.",
          actionLabel: "TRIGGER ROLLOUT",
          icon: Icons.android_rounded,
        ),
        const SizedBox(height: 14),
        _buildActionCard(
          title: "Cloudflare Pages Multi-Site CDN Deploy",
          subtitle: "Builds Web matrix targets and deploys to Cloudflare Pages edge distribution.",
          actionLabel: "DEPLOY WEB HUBS",
          icon: Icons.public_rounded,
        ),
      ],
    );
  }

  Widget _buildActionCard({required String title, required String subtitle, required String actionLabel, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AcousticColors.darkCarbon,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AcousticColors.midGray.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 28, color: AcousticColors.sonarCyan),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: AcousticColors.titanium)),
                const SizedBox(height: 4),
                Text(subtitle, style: GoogleFonts.outfit(fontSize: 10, color: AcousticColors.midGray)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AcousticColors.sonarCyan.withOpacity(0.1),
              foregroundColor: AcousticColors.sonarCyan,
              side: BorderSide(color: AcousticColors.sonarCyan, width: 0.8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: Text(actionLabel, style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. OTA CDN ENGINE WORKSPACE
// ─────────────────────────────────────────────────────────────────────────────

class OtaEngineWorkspace extends StatelessWidget {
  const OtaEngineWorkspace({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          "INFORTTS R2 CDN OTA ENGINE",
          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2.0, color: AcousticColors.titanium),
        ),
        const SizedBox(height: 6),
        Text(
          "Autonomous hot-patch delivery bypassing app store review cycles.",
          style: GoogleFonts.outfit(fontSize: 11, color: AcousticColors.midGray),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AcousticColors.darkCarbon,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AcousticColors.sonarCyan.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.cloud_done_rounded, color: AcousticColors.sonarCyan, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "OTA MANIFEST REGISTRY (R2 CLOUD)",
                    style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AcousticColors.sonarCyan),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                "Endpoint: https://update.infortts.site/api/v1/ota/manifest.json\nStatus: LIVE 200 OK\nStorage: Cloudflare R2 Sovereign Storage Bucket\nSecurity: SHA-256 Signatures & Infortts RSA-4096 Verification",
                style: GoogleFonts.jetBrainsMono(fontSize: 10, color: AcousticColors.steel, height: 1.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. RBAC GOVERNANCE WORKSPACE
// ─────────────────────────────────────────────────────────────────────────────

class RbacGovernanceWorkspace extends StatelessWidget {
  const RbacGovernanceWorkspace({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          "GLYCOCALYX RBAC & IAM GOVERNANCE",
          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2.0, color: AcousticColors.titanium),
        ),
        const SizedBox(height: 6),
        Text(
          "Enterprise Role-Based Access Control enforcing profile-bound resource segregation.",
          style: GoogleFonts.outfit(fontSize: 11, color: AcousticColors.midGray),
        ),
        const SizedBox(height: 20),
        _buildRoleRow("Superadmin", "Full cluster root, CI/CD pipelines, DNS, and database administrative rights", AcousticColors.sonarCyan),
        _buildRoleRow("Engineer", "Code commits, branch merges, test runs, and OTA build triggers", AcousticColors.steel),
        _buildRoleRow("Trader", "Mitochondria terminal, MT5 account binding, and algo execution controls", AcousticColors.sonarCyan),
        _buildRoleRow("Partner", "Care4U provider/doctor appointments and dropship vendor catalog", Colors.amber),
        _buildRoleRow("Client", "End-user apps (Care4U patient booking, Waptia store browsing)", AcousticColors.midGray),
      ],
    );
  }

  Widget _buildRoleRow(String role, String desc, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AcousticColors.darkCarbon,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AcousticColors.midGray.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color.withOpacity(0.4)),
            ),
            child: Text(
              role.toUpperCase(),
              style: GoogleFonts.jetBrainsMono(fontSize: 10, fontWeight: FontWeight.bold, color: color),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              desc,
              style: GoogleFonts.outfit(fontSize: 11, color: AcousticColors.titanium),
            ),
          ),
        ],
      ),
    );
  }
}
