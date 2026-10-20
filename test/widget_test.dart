import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:linux_notes/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Store.load();
  });

  testWidgets('Linux Notes app diagnostic', (tester) async {
    debugPrint('STEP 1: Before pumpWidget');

    await tester.pumpWidget(const App());

    debugPrint('STEP 2: After pumpWidget');

    expect(find.byType(MaterialApp), findsOneWidget);

    debugPrint('STEP 3: Assertion passed');
  });
}
