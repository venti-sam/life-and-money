import 'package:flutter_test/flutter_test.dart';
import 'package:life_and_money/database.dart';

void main() {
  final db = AppDatabase.instance;

  // The same behaviour must hold for the in-memory test store and for the
  // real sembast store (IndexedDB in the browser).
  final setups = {
    'in-memory store': db.resetForTesting,
    'sembast store': db.resetForTestingWithSembast,
  };

  for (final entry in setups.entries) {
    group(entry.key, () {
      setUp(entry.value);

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
        expect(rows.last['night'], '2026-10-22');
      });

      test('deleteAt and deleteById remove the right record', () async {
        await db.insertAll('t', [
          {'n': 1},
          {'n': 2},
          {'n': 3},
        ]);
        await db.deleteAt('t', 0);
        var rows = await db.all('t');
        expect(rows.map((r) => r['n']), [2, 3]);
        await db.deleteById('t', rows.last['_id'] as int);
        rows = await db.all('t');
        expect(rows.map((r) => r['n']), [2]);
      });

      test('upsert replaces a record with the same field value', () async {
        await db.upsert('rules', 'key', {'key': 'A', 'category': 'Food'});
        await db.upsert('rules', 'key', {'key': 'B', 'category': 'Shopping'});
        await db.upsert('rules', 'key', {'key': 'A', 'category': 'Travel'});
        final rows = await db.all('rules');
        expect(rows, hasLength(2));
        expect(rows.firstWhere((r) => r['key'] == 'A')['category'], 'Travel');
      });
    });
  }
}
