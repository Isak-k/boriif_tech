import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_discovery/main.dart';
import 'package:app_discovery/providers/settings_provider.dart';
import 'package:app_discovery/features/home/screens/main_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Test MyApp pump mounts MainScreen properly', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final settingsProvider = SettingsProvider();
    await settingsProvider.init();

    await tester.pumpWidget(MyApp(settingsProvider: settingsProvider));
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(MainScreen), findsOneWidget);
  });
}
