import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:gigflow/main.dart';
import 'package:gigflow/providers/user_profile_provider.dart';
import 'package:gigflow/utils/backend_api.dart';
import 'package:gigflow/screens/import/import_screen.dart';
import 'package:gigflow/screens/spending/spending_analysis_screen.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => UserProfileProvider(),
        child: const GigFlowApp(),
      ),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  test('BackendException message is readable', () {
    const e = BackendException('test error');
    expect(e.toString(), 'test error');
  });

  testWidgets('ImportScreen shows 4 option cards', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => UserProfileProvider(),
        child: const MaterialApp(home: ImportScreen()),
      ),
    );
    expect(find.text('Connect to Bank'), findsOneWidget);
    expect(find.text('Demo Mode'), findsOneWidget);
    expect(find.text('Enter Manually'), findsOneWidget);
    expect(find.text('Upload CSV'), findsOneWidget);
  });
}
