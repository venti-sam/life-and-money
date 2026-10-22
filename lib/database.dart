import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// On-device storage. Everything lives in one SQLite file on the phone;
/// nothing is sent anywhere.
///
/// Tables are created now so later steps (logging screens) can just use them.
class AppDatabase {
  AppDatabase._() : _pathOverride = null;
  static final AppDatabase instance = AppDatabase._();

  /// A separate database at [path] (e.g. `inMemoryDatabasePath`), for tests.
  AppDatabase.forPath(String path) : _pathOverride = path;

  final String? _pathOverride;

  Database? _db;

  Future<Database> get db async => _db ??= await _open();

  Future<Database> _open() async {
    final path =
        _pathOverride ?? p.join(await getDatabasesPath(), 'life_and_money.db');
    return openDatabase(path, version: 1, onCreate: _create);
  }

  Future<void> _create(Database db, int version) async {
    await db.execute('''
      CREATE TABLE meals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        logged_at TEXT NOT NULL,
        description TEXT,
        photo_path TEXT,
        calories INTEGER
      )''');
    await db.execute('''
      CREATE TABLE workouts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        logged_at TEXT NOT NULL,
        type TEXT NOT NULL,
        duration_minutes INTEGER,
        notes TEXT
      )''');
    await db.execute('''
      CREATE TABLE sleep (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        night TEXT NOT NULL,
        hours REAL NOT NULL
      )''');
    await db.execute('''
      CREATE TABLE balances (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recorded_at TEXT NOT NULL,
        account TEXT NOT NULL,
        kind TEXT NOT NULL,
        amount REAL NOT NULL
      )''');
  }

  /// Number of rows in a table, used by the home screen to show it works.
  Future<int> count(String table) async {
    final rows = await (await db).rawQuery('SELECT COUNT(*) AS c FROM $table');
    return Sqflite.firstIntValue(rows) ?? 0;
  }
}
