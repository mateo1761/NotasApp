import 'dart:io';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure.dart';
import '../../../core/utils/connectivity.dart';
import '../domain/note.dart';
import 'notes_api.dart';
import 'notes_local_db.dart';

class NotesRepository {
  final NotesApi _api;
  final NotesLocalDb _db;
  final String host;
  final int port;

  NotesRepository(DioClient client, this._db, {required this.host, this.port = 3000})
      : _api = NotesApi(client.dio);

  Future<List<Note>> listLocal() => _db.all();

  Future<void> createLocal(String title, String content) async {
    final n = Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      content: content,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _db.markDirty(n);
  }

  Future<void> updateLocal(String id, String title, String content) async {
    final n = Note(id: id, title: title, content: content, updatedAt: DateTime.now().millisecondsSinceEpoch);
    await _db.markDirty(n);
  }

  Future<void> deleteLocal(String id) async {
    await _db.markDeleted(id);
  }

  Future<bool> _canReachBackend() => Net.isOnline(host, port: port);

  Future<void> sync() async {
    if (!await _canReachBackend()) return;

    final dirty = await _db.dirtyRows();
    for (final r in dirty) {
      final id = r['id'] as String;
      final deleted = (r['deleted'] as int) == 1;
      if (deleted) {
        try { await _api.delete(id); } catch (_) {}
        continue;
      }
      try {
        await _api.update(id, r['title'] as String, r['content'] as String);
      } catch (_) {
        final created = await _api.create(r['title'] as String, r['content'] as String);
        await _db.upsert(created);
      }
    }

    final remote = await _api.list();
    await _db.clearAndInsert(remote);
  }
}