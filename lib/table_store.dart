import 'package:sembast/sembast_memory.dart';

/// Where tables are kept. [SembastTableStore] is the real one (IndexedDB in
/// the browser); [MemoryTableStore] is a plain in-memory version for tests.
abstract class TableStore {
  Future<List<Map<String, Object?>>> all(String table);
  Future<void> insertAll(String table, List<Map<String, Object?>> records);
  Future<void> upsert(String table, String field, Map<String, Object?> record);
  Future<void> deleteAt(String table, int index);
  Future<void> deleteById(String table, int id);
  Future<int> count(String table);
}

class SembastTableStore implements TableStore {
  SembastTableStore(this._db);
  final Database _db;

  StoreRef<int, Map<String, Object?>> _store(String table) =>
      intMapStoreFactory.store(table);

  @override
  Future<List<Map<String, Object?>>> all(String table) async {
    final snapshots = await _store(table).find(_db);
    return [
      for (final s in snapshots) {...s.value, '_id': s.key},
    ];
  }

  @override
  Future<void> insertAll(
      String table, List<Map<String, Object?>> records) async {
    if (records.isEmpty) return;
    await _store(table).addAll(_db, records);
  }

  @override
  Future<void> upsert(
      String table, String field, Map<String, Object?> record) async {
    final store = _store(table);
    final existing = await store.findFirst(_db,
        finder: Finder(filter: Filter.equals(field, record[field])));
    if (existing == null) {
      await store.add(_db, record);
    } else {
      await store.record(existing.key).put(_db, record);
    }
  }

  @override
  Future<void> deleteAt(String table, int index) async {
    final keys = await _store(table).findKeys(_db);
    if (index < 0 || index >= keys.length) return;
    await _store(table).record(keys[index]).delete(_db);
  }

  @override
  Future<void> deleteById(String table, int id) async {
    await _store(table).record(id).delete(_db);
  }

  @override
  Future<int> count(String table) => _store(table).count(_db);
}

class MemoryTableStore implements TableStore {
  final Map<String, List<Map<String, Object?>>> _tables = {};
  int _nextId = 1;

  List<Map<String, Object?>> _rows(String table) =>
      _tables.putIfAbsent(table, () => []);

  @override
  Future<List<Map<String, Object?>>> all(String table) async =>
      [for (final r in _rows(table)) {...r}];

  @override
  Future<void> insertAll(
      String table, List<Map<String, Object?>> records) async {
    for (final r in records) {
      _rows(table).add({...r, '_id': _nextId++});
    }
  }

  @override
  Future<void> upsert(
      String table, String field, Map<String, Object?> record) async {
    final rows = _rows(table);
    final i = rows.indexWhere((r) => r[field] == record[field]);
    if (i < 0) {
      rows.add({...record, '_id': _nextId++});
    } else {
      rows[i] = {...record, '_id': rows[i]['_id']};
    }
  }

  @override
  Future<void> deleteAt(String table, int index) async {
    final rows = _rows(table);
    if (index >= 0 && index < rows.length) rows.removeAt(index);
  }

  @override
  Future<void> deleteById(String table, int id) async =>
      _rows(table).removeWhere((r) => r['_id'] == id);

  @override
  Future<int> count(String table) async => _rows(table).length;
}
