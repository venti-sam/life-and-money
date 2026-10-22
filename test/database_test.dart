import 'package:flutter_test/flutter_test.dart';
import 'package:life_and_money/database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late AppDatabase appDb;

  setUp(() {
    appDb = AppDatabase.forPath(inMemoryDatabasePath);
  });

  test('creates all four tables, all empty', () async {
    for (final table in ['meals', 'workouts', 'sleep', 'balances']) {
      expect(await appDb.count(table), 0, reason: table);
    }
  });

  test('count reflects inserted rows', () async {
    final db = await appDb.db;
    await db.insert('sleep', {'night': '2026-10-21', 'hours': 7.5});
    await db.insert('sleep', {'night': '2026-10-22', 'hours': 6.0});
    expect(await appDb.count('sleep'), 2);
    expect(await appDb.count('meals'), 0);
  });
}
