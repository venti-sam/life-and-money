import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_and_money/database.dart';
import 'package:life_and_money/diet_screen.dart';
import 'package:life_and_money/finances_screen.dart';
import 'package:life_and_money/sleep_screen.dart';
import 'package:life_and_money/workouts_screen.dart';

void main() {
  setUp(AppDatabase.instance.resetForTesting);

  testWidgets('logging sleep saves an entry and lists it', (tester) async {
    await tester.pumpWidget(MaterialApp(home: sleepScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Nothing logged yet.'), findsOneWidget);

    await tester.tap(find.text('Log sleep'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Hours slept'), '7.5');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('7.5 hours'), findsOneWidget);
    expect(await AppDatabase.instance.count('sleep'), 1);
  });

  testWidgets('sleep keeps up to 2 decimals and ignores extra digits',
      (tester) async {
    await tester.pumpWidget(MaterialApp(home: sleepScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log sleep'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Hours slept'), '7.25');
    await tester.enterText(find.widgetWithText(TextField, 'Hours slept'), '7.256'); // rejected
    await tester.pump();
    expect(find.text('7.25'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('7.25 hours'), findsOneWidget);
  });

  testWidgets('sleep rejects invalid hours', (tester) async {
    await tester.pumpWidget(MaterialApp(home: sleepScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log sleep'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Hours slept'), '40');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(await AppDatabase.instance.count('sleep'), 0);
  });

  testWidgets('logging a workout saves type and minutes', (tester) async {
    await tester.pumpWidget(MaterialApp(home: workoutsScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Log workout'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Time (minutes)'), '45');
    await tester.enterText(
        find.widgetWithText(TextField, 'Notes (optional)'), 'Easy 5k, effort 6/10');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Running, 45 min'), findsOneWidget);
    expect(find.textContaining('effort 6/10'), findsOneWidget);
    expect(await AppDatabase.instance.count('workouts'), 1);
  });

  testWidgets('sleep notes are saved and shown', (tester) async {
    await tester.pumpWidget(MaterialApp(home: sleepScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log sleep'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextField, 'Hours slept'), '8');
    await tester.enterText(
        find.widgetWithText(TextField, 'Notes (optional)'), 'woke up once');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.textContaining('woke up once'), findsOneWidget);
  });

  testWidgets('deleting an entry removes it after confirming',
      (tester) async {
    await AppDatabase.instance.insert('sleep', {'night': '2026-10-20', 'hours': 6.0});
    await AppDatabase.instance.insert('sleep', {'night': '2026-10-21', 'hours': 8.0});
    await tester.pumpWidget(MaterialApp(home: sleepScreen()));
    await tester.pumpAndSettle();
    expect(find.text('6.0 hours'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete').last); // oldest entry (6.0)
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('6.0 hours'), findsNothing);
    expect(find.text('8.0 hours'), findsOneWidget);
    expect(await AppDatabase.instance.count('sleep'), 1);
  });

  testWidgets('cancelling delete keeps the entry', (tester) async {
    await AppDatabase.instance.insert('sleep', {'night': '2026-10-21', 'hours': 8.0});
    await tester.pumpWidget(MaterialApp(home: sleepScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(await AppDatabase.instance.count('sleep'), 1);
  });

  testWidgets('logging a meal by text saves and lists it', (tester) async {
    await tester.pumpWidget(MaterialApp(home: dietScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log meal'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextField, 'What did you eat?'), 'Chicken rice');
    await tester.enterText(
        find.widgetWithText(TextField, 'Calories (optional)'), '600');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Chicken rice'), findsOneWidget);
    expect(find.textContaining('600 kcal'), findsOneWidget);
  });

  testWidgets('an empty meal is not saved', (tester) async {
    await tester.pumpWidget(MaterialApp(home: dietScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log meal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(await AppDatabase.instance.count('meals'), 0);
  });

  testWidgets('logging a balance shows totals', (tester) async {
    await tester.pumpWidget(MaterialApp(home: financesScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log balance'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextField, 'Account name'), 'POSB savings');
    await tester.enterText(find.widgetWithText(TextField, 'Balance'), '1500.5');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('POSB savings: 1500.50'), findsOneWidget);
    expect(find.text('Total: 1500.50'), findsOneWidget);
  });
}
