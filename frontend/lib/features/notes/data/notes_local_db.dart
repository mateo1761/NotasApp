import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../domain/note.dart';

class NotesLocalDb {
  static const _dbName = 'notes.db';
  static const _table = 'notes';
  Database? _db;

  Future<void> init() async {
    final base = await getDatabasesPath();
    final path = p.join(base, _dbName);
    _db = await openDatabase(
      path,
      version: 2,
      onCreate: (db, v) async {
        await db.execute('''
          CREATE TABLE $_table (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            location TEXT,
            updatedAt INTEGER NOT NULL,
            dirty INTEGER NOT NULL DEFAULT 0,
            deleted INTEGER NOT NULL DEFAULT 0
          );
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE $_table ADD COLUMN location TEXT');
        }
      },
    );
  }

  Future<List<Note>> all() async {
    final rows = await _db!.query(_table, where: 'deleted = 0', orderBy: 'updatedAt DESC');
    return rows.map((r) => Note(
      id: r['id'] as String,
      title: r['title'] as String,
      content: r['content'] as String,
      location: r['location'] as String?,
      updatedAt: r['updatedAt'] as int,
    )).toList();
  }

  Future<void> upsert(Note n, {bool dirty = false, bool deleted = false}) async {
    await _db!.insert(_table, {
      'id': n.id,
      'title': n.title,
      'content': n.content,
      'location': n.location,
      'updatedAt': n.updatedAt,
      'dirty': dirty ? 1 : 0,
      'deleted': deleted ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> markDirty(Note n) => upsert(n, dirty: true);
  Future<void> markDeleted(String id) async {
    await _db!.update(_table, {'deleted': 1, 'dirty': 1}, where: 'id = ?', whereArgs: [id]);
  }
  Future<void> markClean(String id) async {
    await _db!.update(_table, {'dirty': 0}, where: 'id = ?', whereArgs: [id]);
    debugPrint('NotesLocalDb.markClean: Set dirty=0 for id=$id');
  }

  Future<List<Map<String, dynamic>>> dirtyRows() async {
    return _db!.query(_table, where: 'dirty = 1');
  }

  Future<void> clearAndInsert(List<Note> list) async {
    final batch = _db!.batch();
    batch.delete(_table);
    for (final n in list) {
      batch.insert(_table, {
        'id': n.id,
        'title': n.title,
        'content': n.content,
        'location': n.location,
        'updatedAt': n.updatedAt,
        'dirty': 0,
        'deleted': 0,
      });
    }
    await batch.commit(noResult: true);
  }
}