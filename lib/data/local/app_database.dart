import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();
  Database? _database;

  Future<Database> get database async {
    final existing = _database;
    if (existing != null) return existing;

    final root = await getDatabasesPath();
    final dbPath = join(root, 'optimistic_browser.db');
    final db = await openDatabase(
      dbPath,
      version: 2,
      onCreate: (database, version) => _createSchema(database),
      onUpgrade: (database, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await database.execute(
            'ALTER TABLE bookmarks ADD COLUMN folder TEXT NOT NULL DEFAULT \'\'',
          );
          await database.execute(
            'ALTER TABLE bookmarks ADD COLUMN tags TEXT NOT NULL DEFAULT \'\'',
          );
          await database.execute(
            'ALTER TABLE notes ADD COLUMN tags TEXT NOT NULL DEFAULT \'\'',
          );
        }
      },
    );
    _database = db;
    return db;
  }

  static Future<void> _createSchema(Database database) async {
    await database.execute('''
      CREATE TABLE bookmarks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        url TEXT NOT NULL UNIQUE,
        folder TEXT NOT NULL DEFAULT '',
        tags TEXT NOT NULL DEFAULT '',
        created_at INTEGER NOT NULL
      )
    ''');
    await database.execute('''
      CREATE TABLE history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        url TEXT NOT NULL,
        visited_at INTEGER NOT NULL
      )
    ''');
    await database.execute('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        tags TEXT NOT NULL DEFAULT '',
        updated_at INTEGER NOT NULL
      )
    ''');
  }
}
