import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:linux_notes/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads bundled offline chapters without preferences', () async {
    SharedPreferences.setMockInitialValues({});
    await Store.load();
    expect(Store.data.length, 236);
    expect(Store.allNotes().length, 1096);
  });

  test('recovers from corrupt saved preferences without deleting them', () async {
    SharedPreferences.setMockInitialValues({
      'mynotes': '{broken',
      'folders': '[wrong]',
      'stats': '{broken',
      'theme': 999,
      'scale': 99.0,
      'quiz_scores_v1': '{broken',
    });
    await Store.load();
    expect(Store.data.length, 236);
    expect(Store.myNotes, isEmpty);
    expect(Store.folders, isEmpty);
    expect(Store.stats, isEmpty);
    expect(Store.quizScores, isEmpty);
    expect(Store.theme.value, ThemeMode.system);
    expect(Store.scale.value, 1.0);
    expect(Store.p.getString('mynotes'), '{broken');
  });

  test('preserves valid personal notes and progress', () async {
    SharedPreferences.setMockInitialValues({
      'mynotes': jsonEncode([{'title': 'Personal', 'body': 'Offline'}]),
      'completed_labs_v1': ['lab-one'],
    });
    await Store.load();
    expect(Store.myNotes.first['title'], 'Personal');
    expect(Store.completedLabs, contains('lab-one'));
  });
}
