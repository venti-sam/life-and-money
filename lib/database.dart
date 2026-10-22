import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// On-device storage that works on both the web (browser storage) and
/// Android. Data never leaves the device.
///
/// Each "table" is a list of records (maps). Known tables, used by later
/// logging screens: meals, workouts, sleep, balances.
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static const _prefix = 'table_';

  Future<List<Map<String, Object?>>> all(String table) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$table');
    if (raw == null) return [];
    return (jsonDecode(raw) as List).cast<Map<String, Object?>>();
  }

  Future<void> insert(String table, Map<String, Object?> record) async {
    final rows = await all(table);
    rows.add(record);
    await _save(table, rows);
  }

  /// Removes the record at [index] (position in insertion order).
  Future<void> deleteAt(String table, int index) async {
    final rows = await all(table);
    if (index < 0 || index >= rows.length) return;
    rows.removeAt(index);
    await _save(table, rows);
  }

  Future<void> _save(String table, List<Map<String, Object?>> rows) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefix$table', jsonEncode(rows));
  }

  /// Number of records in a table, used by the home screen.
  Future<int> count(String table) async => (await all(table)).length;
}
