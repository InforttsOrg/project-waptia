import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:infortts_shared/infortts_shared.dart';
import 'package:waptia/auto_update_manager.dart';
import 'package:waptia/main.dart';

void main() {
  testWidgets('Store shell renders catalog with Store and Settings tabs',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'infortts_auth_userId': 'usr_test_001',
      'infortts_auth_email': 'tester@infortts.site',
      'infortts_auth_profile': '{"display_name":"TESTER"}',
    });
    await WaptiaAutoUpdateManager.instance.initialize(isTest: true);

    await tester.pumpWidget(const WaptiaStoreApp());
    await tester.pump(const Duration(milliseconds: 2600));

    expect(find.text('Cardiodictyon Mobile'), findsOneWidget);
    expect(find.text('Explore'), findsWidgets);
    expect(find.text('Updates'), findsWidgets);

    InforttsNotificationService.instance.dispose();
  });
}