import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:waptia/main.dart';

void main() {
  testWidgets('Store shell renders catalog with Store and Settings tabs',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'infortts_auth_userId': 'usr_test_001',
      'infortts_auth_email': 'tester@infortts.site',
      'infortts_auth_profile': '{"display_name":"TESTER"}',
    });

    await tester.pumpWidget(const WaptiaStoreApp());
    await tester.pump(const Duration(milliseconds: 2600));

    expect(find.text('Cardiodictyon Mobile'), findsOneWidget);
    expect(find.text('Store'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pump();
    expect(find.text('SETTINGS & CONFIGURATION'), findsOneWidget);
  });
}