import 'package:flutter/material.dart';
import 'package:infortts_shared/infortts_shared.dart';

import 'catalog_data.dart';

void main() {
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
      home: InforttsAppShell(
        appName: 'Waptia by Infortts',
        appDescription: 'Infortts App Store — Download and update Infortts apps',
        appVersion: '1.2.0',
        additionalTabs: [
          InforttsTab(
            label: 'Store',
            icon: Icons.storefront_outlined,
            builder: (_) => const StoreWorkspace(),
          ),
        ],
        workspaceChild: const StoreWorkspace(),
      ),
    );
  }
}

class StoreWorkspace extends StatefulWidget {
  const StoreWorkspace({super.key});

  @override
  State<StoreWorkspace> createState() => _StoreWorkspaceState();
}

class _StoreWorkspaceState extends State<StoreWorkspace> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredApps = inforttsCatalog.where((app) {
      final q = _searchQuery.toLowerCase();
      return app.name.toLowerCase().contains(q) ||
          app.slug.toLowerCase().contains(q) ||
          app.tagline.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Search ${inforttsCatalog.length} ecosystem applications...',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF21E6D0)),
              filled: true,
              fillColor: const Color(0xFF161B22),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF30363D)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF30363D)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF21E6D0)),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: filteredApps.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final app = filteredApps[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF30363D)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF21262D),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFF21E6D0).withValues(alpha: 0.3)),
                      ),
                      child: const Icon(Icons.hub_rounded,
                          color: Color(0xFF21E6D0)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            app.name,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            app.tagline,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.white70),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'com.infortts.${app.slug}',
                            style: const TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                                color: Color(0xFF21E6D0)),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF21E6D0),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Downloading ${app.name} APK from update.infortts.site...'),
                            backgroundColor: const Color(0xFF161B22),
                          ),
                        );
                      },
                      child: const Text('APK',
                          style: TextStyle(fontWeight: FontWeight.bold)),
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