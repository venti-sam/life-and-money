import 'dart:convert';

import 'package:sembast/sembast_memory.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'db_factory.dart';
import 'table_store.dart';

/// On-device storage. In the browser it lives in IndexedDB, so it can hold
/// far more than simple browser storage (hundreds of transactions, photos).
/// Data never leaves the device.
///
/// Each "table" is a list of records (maps). Records come back in the order
/// they were inserted, each with an `_id` you can use to delete it.
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  TableStore? _direct; // set in tests; avoids awaiting a future from another zone
  Future<TableStore>? _store;

  Future<TableStore> get _s async => _direct ?? await (_store ??= _open());

  Future<TableStore> _open() async {
    final db = await platformDatabaseFactory.openDatabase('life_and_money.db');
    final store = SembastTableStore(db);
    await _migrateFromBrowserStorage(store);
    return store;
  }

  /// Use a fresh, empty in-memory store. For tests.
  void resetForTesting() {
    _direct = MemoryTableStore();
    _store = null;
  }

  /// Use a fresh sembast database (in memory). For tests of the real store.
  void resetForTestingWithSembast() {
    _direct = null;
    _store = newDatabaseFactoryMemory()
        .openDatabase('test.db')
        .then((db) => SembastTableStore(db));
  }

  Future<List<Map<String, Object?>>> all(String table) async =>
      (await _s).all(table);

  Future<void> insert(String table, Map<String, Object?> record) async =>
      (await _s).insertAll(table, [record]);

  Future<void> insertAll(
          String table, List<Map<String, Object?>> records) async =>
      (await _s).insertAll(table, records);

  /// Replaces the record whose [field] equals the new record's, or adds it.
  Future<void> upsert(
          String table, String field, Map<String, Object?> record) async =>
      (await _s).upsert(table, field, record);

  /// Removes the record at [index] (position in insertion order).
  Future<void> deleteAt(String table, int index) async =>
      (await _s).deleteAt(table, index);

  Future<void> deleteById(String table, int id) async =>
      (await _s).deleteById(table, id);

  /// Number of records in a table, used by the home screen.
  Future<int> count(String table) async => (await _s).count(table);

  /// Earlier versions kept tables as JSON in simple browser storage. Move
  /// them over once.
  Future<void> _migrateFromBrowserStorage(TableStore store) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final key in prefs.getKeys().where((k) => k.startsWith('table_'))) {
        final table = key.substring('table_'.length);
        final raw = prefs.getString(key);
        if (raw != null && await store.count(table) == 0) {
          final rows = (jsonDecode(raw) as List).cast<Map<String, Object?>>();
          await store.insertAll(table, rows);
        }
        await prefs.remove(key);
      }
    } catch (_) {
      // Nothing to migrate, or browser storage unavailable.
    }
  }
}
