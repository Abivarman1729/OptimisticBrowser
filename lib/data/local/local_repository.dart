import 'package:sqflite/sqflite.dart';

import 'app_database.dart';

class LocalRepository {
  const LocalRepository();

  Future<void> addHistory({required String title, required String url}) async {
    if (url.isEmpty) return;
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final recent = await db.query(
      'history',
      columns: ['visited_at'],
      where: 'url = ?',
      whereArgs: [url],
      orderBy: 'visited_at DESC',
      limit: 1,
    );
    if (recent.isNotEmpty) {
      final last = recent.first['visited_at'] as int;
      if (now - last < 5000) return;
    }
    await db.insert('history', {
      'title': title.isEmpty ? 'Untitled' : title,
      'url': url,
      'visited_at': now,
    });
  }

  Future<void> clearHistory() async {
    final db = await AppDatabase.instance.database;
    await db.delete('history');
  }

  Future<void> addBookmark({
    required String title,
    required String url,
    String folder = '',
    String tags = '',
  }) async {
    final db = await AppDatabase.instance.database;
    await db.insert(
      'bookmarks',
      {
        'title': title.isEmpty ? 'Untitled' : title,
        'url': url,
        'folder': folder,
        'tags': tags,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, Object?>>> bookmarks({String query = ''}) async {
    final db = await AppDatabase.instance.database;
    final q = query.trim();
    return db.query(
      'bookmarks',
      where: q.isEmpty ? null : 'title LIKE ? OR url LIKE ? OR tags LIKE ?',
      whereArgs: q.isEmpty ? null : ['%$q%', '%$q%', '%$q%'],
      orderBy: 'created_at DESC',
    );
  }

  Future<List<Map<String, Object?>>> history({String query = ''}) async {
    final db = await AppDatabase.instance.database;
    final q = query.trim();
    return db.query(
      'history',
      where: q.isEmpty ? null : 'title LIKE ? OR url LIKE ?',
      whereArgs: q.isEmpty ? null : ['%$q%', '%$q%'],
      orderBy: 'visited_at DESC',
      limit: 200,
    );
  }

  Future<void> deleteBookmark(int id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('bookmarks', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> saveNote({
    int? id,
    required String title,
    required String body,
    String tags = '',
  }) async {
    final db = await AppDatabase.instance.database;
    final data = {
      'title': title.isEmpty ? 'Untitled' : title,
      'body': body,
      'tags': tags,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    };
    if (id == null) {
      await db.insert('notes', data);
    } else {
      await db.update('notes', data, where: 'id = ?', whereArgs: [id]);
    }
  }

  Future<List<Map<String, Object?>>> notes({String query = ''}) async {
    final db = await AppDatabase.instance.database;
    final q = query.trim();
    return db.query(
      'notes',
      where: q.isEmpty ? null : 'title LIKE ? OR body LIKE ? OR tags LIKE ?',
      whereArgs: q.isEmpty ? null : ['%$q%', '%$q%', '%$q%'],
      orderBy: 'updated_at DESC',
    );
  }

  Future<void> deleteNote(int id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }
}
