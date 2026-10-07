import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waptia/auto_update_manager.dart';
import 'package:waptia/main.dart';
import 'package:waptia/models.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'infortts_auth_userId': 'usr_test_001',
      'infortts_auth_email': 'tester@infortts.site',
      'infortts_auth_token': 'test_token_123',
    });
    await WaptiaAutoUpdateManager.instance.initialize(isTest: true);
  });

  testWidgets('AppDetailsModal renders Available on more devices and Rate this app', (WidgetTester tester) async {
    const testApp = AppInstallState(
      slug: 'waptia',
      name: 'Waptia Store',
      packageName: 'com.infortts.waptia',
      installedVersion: '2.07.00',
      installedBuild: 20700,
      latestVersion: '2.07.01',
      latestBuild: 20701,
      latestPatch: 1,
      isInstalled: false,
      hasUpdate: false,
      releaseNotes: ['✓ Test release notes'],
      downloadUrl: 'https://update.infortts.site/download/waptia.apk',
      patchUrl: 'https://update.infortts.site/patches/waptia/patch_1.bin',
      rating: 4.9,
      ratingCount: 128,
    );

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppDetailsModal(app: testApp),
        ),
      ),
    );

    // Initial pump and wait for devices to load
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify App Name and Package Name
    expect(find.text('Waptia Store'), findsOneWidget);
    expect(find.text('com.infortts.waptia'), findsOneWidget);

    // Verify Google Play Store metrics bar
    expect(find.text('4.9'), findsOneWidget);
    expect(find.text('128 reviews'), findsOneWidget);

    // 1. Verify Available on more devices section
    expect(find.text('Available on more devices'), findsOneWidget);
    expect(find.text('Google Pixel 9 Pro'), findsOneWidget);
    expect(find.text('Phone'), findsWidgets);
    expect(find.text('Install'), findsWidgets);

    // 2. Verify Rate this app section
    expect(find.text('Rate this app'), findsOneWidget);
    expect(find.text('Tell others what you think'), findsOneWidget);
    expect(find.text('Write a review'), findsOneWidget);

    // 3. Test Rating interaction (tapping 5th star)
    final stars = find.byIcon(Icons.star_outline_rounded);
    expect(stars, findsNWidgets(5));
    await tester.tap(stars.last);
    await tester.pump();

    // Verify rating feedback
    expect(find.text('5 ★ Saved'), findsOneWidget);

    // Dismiss any SnackBars
    ScaffoldMessenger.of(tester.element(find.byType(AppDetailsModal))).clearSnackBars();
    await tester.pumpAndSettle();

    // 4. Test Write a review interaction
    final writeReviewFinder = find.text('Write a review');
    await tester.ensureVisible(writeReviewFinder);
    await tester.tap(writeReviewFinder);
    await tester.pump();

    expect(find.byType(TextField), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Infortts ecosystem is ultra-responsive!');
    await tester.pump();

    // Submit review
    final submitFinder = find.text('Submit to Infortts DB');
    await tester.ensureVisible(submitFinder);
    await tester.tap(submitFinder);
    await tester.pump();
    ScaffoldMessenger.of(tester.element(find.byType(AppDetailsModal))).clearSnackBars();
    await tester.pumpAndSettle();

    // 5. Test Remote Device Install button tap
    final installButtons = find.text('Install');
    await tester.ensureVisible(installButtons.first);
    await tester.tap(installButtons.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    // Verify device installation initiated
    expect(find.text('Installed'), findsWidgets);
  });

  testWidgets('AppDetailsModal displays Screenshots Gallery and opens Lightbox', (WidgetTester tester) async {
    const testApp = AppInstallState(
      slug: 'waptia',
      name: 'Waptia Store',
      packageName: 'com.infortts.waptia',
      installedVersion: '2.07.00',
      installedBuild: 20700,
      latestVersion: '2.07.01',
      latestBuild: 20701,
      latestPatch: 1,
      isInstalled: false,
      hasUpdate: false,
      releaseNotes: ['✓ Test release notes'],
      downloadUrl: 'https://update.infortts.site/download/waptia.apk',
      patchUrl: 'https://update.infortts.site/patches/waptia/patch_1.bin',
      rating: 4.9,
      ratingCount: 128,
      screenshots: [
        'https://waptia.infortts.site/screenshots/waptia_1.png',
        'https://waptia.infortts.site/screenshots/waptia_2.png',
        'https://waptia.infortts.site/screenshots/waptia_3.png',
      ],
    );

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppDetailsModal(app: testApp),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // 1. Verify App Preview & Features header
    final headerFinder = find.text('App Preview & Features');
    expect(headerFinder, findsOneWidget);
    await tester.ensureVisible(headerFinder);

    // 2. Verify feature captions exist
    expect(find.textContaining('Autonomous Sovereign App Distribution'), findsWidgets);

    // 3. Tap on a screenshot card to trigger Lightbox
    final firstScreenshotCard = find.textContaining('Autonomous Sovereign App Distribution').first;
    await tester.tap(firstScreenshotCard);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // 4. Verify Lightbox elements: Close button, page counter, app title
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(find.text('Screen 1 of 3'), findsOneWidget);

    // Close lightbox
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.close_rounded), findsNothing);
  });
}

