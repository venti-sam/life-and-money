import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_and_money/main.dart';

void main() {
  Widget app() => MaterialApp(
        home: HomeScreen(countFor: (table) async => table == 'meals' ? 3 : 0),
      );

  testWidgets('shows all five sections', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    for (final title in [
      'Diet',
      'Workouts',
      'Sleep',
      'Finances',
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

  testWidgets('tapping a section shows coming soon', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Diet'));
    await tester.pump();
    expect(find.text('Diet: coming soon'), findsOneWidget);
  });
}
