import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:linux_notes/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('bundled offline app launches', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await Store.load();
    await tester.pumpWidget(const App());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
