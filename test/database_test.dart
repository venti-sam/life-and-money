import 'package:flutter_test/flutter_test.dart';
import 'package:life_and_money/database.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final db = AppDatabase.instance;

  test('tables start empty', () async {
    for (final table in ['meals', 'workouts', 'sleep', 'balances']) {
      expect(await db.count(table), 0, reason: table);
    }
  });

  test('inserted records are stored and counted per table', () async {
    await db.insert('sleep', {'night': '2026-10-21', 'hours': 7.5});
    await db.insert('sleep', {'night': '2026-10-22', 'hours': 6.0});
    expect(await db.count('sleep'), 2);
    expect(await db.count('meals'), 0);
    final rows = await db.all('sleep');
    expect(rows.first['hours'], 7.5);
  });
}
