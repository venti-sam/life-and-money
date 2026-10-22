import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_and_money/database.dart';
import 'package:life_and_money/main.dart';

void main() {
  Widget app() => MaterialApp(
        home: HomeScreen(countFor: (table) async => table == 'meals' ? 3 : 0),
      );

  testWidgets('shows all sections', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    for (final title in [
      'Diet',
      'Workouts',
      'Sleep',
      'Finances',
      'Spending',
      'Recommendations',
    ]) {
      expect(find.text(title), findsOneWidget);
    }
  });

  testWidgets('shows entry count from storage', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.text('3 entries'), findsOneWidget);
  });

  setUp(AppDatabase.instance.resetForTesting);

  testWidgets('tapping a section opens its screen', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Diet'));
    await tester.pumpAndSettle();
    expect(find.text('Log meal'), findsOneWidget);
  });
}
