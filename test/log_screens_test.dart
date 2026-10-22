import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_and_money/database.dart';
import 'package:life_and_money/sleep_screen.dart';
import 'package:life_and_money/workouts_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('logging sleep saves an entry and lists it', (tester) async {
    await tester.pumpWidget(MaterialApp(home: sleepScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Nothing logged yet.'), findsOneWidget);

    await tester.tap(find.text('Log sleep'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '7.5');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('7.5 hours'), findsOneWidget);
    expect(await AppDatabase.instance.count('sleep'), 1);
  });

  testWidgets('sleep rejects invalid hours', (tester) async {
    await tester.pumpWidget(MaterialApp(home: sleepScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log sleep'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '40');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(await AppDatabase.instance.count('sleep'), 0);
  });

  testWidgets('logging a workout saves type and minutes', (tester) async {
    await tester.pumpWidget(MaterialApp(home: workoutsScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Log workout'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Minutes'), '45');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Running, 45 min'), findsOneWidget);
    expect(await AppDatabase.instance.count('workouts'), 1);
  });
}
