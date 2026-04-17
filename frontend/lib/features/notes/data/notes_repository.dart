import 'package:flutter/foundation.dart';
import '../../../core/network/dio_client.dart';
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

  Future<void> createLocal(String title, String content, {String? location}) async {
    final n = Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      content: content,
      location: location,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _db.markDirty(n);
    debugPrint('NotesRepository.createLocal: Created note "$title"');
  }

  Future<void> updateLocal(String id, String title, String content, {String? location}) async {
    final n = Note(
      id: id,
      title: title,
      content: content,
      location: location,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _db.markDirty(n);
    debugPrint('NotesRepository.updateLocal: Updated note "$title"');
  }

  Future<void> deleteLocal(String id) async {
    await _db.markDeleted(id);
    debugPrint('NotesRepository.deleteLocal: Deleted note $id');
  }

  Future<bool> _canReachBackend() => Net.isOnline(host, port: port);

  Future<void> sync() async {
    debugPrint('NotesRepository.sync: Starting sync to $host:$port');
    
    final isReachable = await _canReachBackend();
    debugPrint('NotesRepository.sync: Backend reachable = $isReachable');
    
    if (!isReachable) {
      debugPrint('NotesRepository.sync: Backend not reachable, skipping sync');
      return;
    }

    final dirty = await _db.dirtyRows();
    debugPrint('NotesRepository.sync: Found ${dirty.length} dirty notes to upload');

    for (final r in dirty) {
      debugPrint('  Uploading: ${r['title']} (dirty=${r['dirty']})');
      final id = r['id'] as String;
      final deleted = (r['deleted'] as int) == 1;
      if (deleted) {
        try { 
          await _api.delete(id); 
          debugPrint('NotesRepository.sync: Deleted note $id on server');
        } catch (_) {}
        continue;
      }
      try {
        await _api.update(
          id,
          r['title'] as String,
          r['content'] as String,
          location: r['location'] as String?,
        );
        debugPrint('NotesRepository.sync: Updated: "${r['title']}"');
      } catch (_) {
        debugPrint('NotesRepository.sync: Create on server for "${r['title']}"');
        final created = await _api.create(
          r['title'] as String,
          r['content'] as String,
          location: r['location'] as String?,
        );
        await _db.upsert(created);
        debugPrint('NotesRepository.sync: Created: "${created.title}"');
      }
    }

    debugPrint('NotesRepository.sync: Downloading fresh notes from server');
    final serverNotes = await _api.list();
    await _db.clearAndInsert(serverNotes);
    debugPrint('NotesRepository.sync: Downloaded ${serverNotes.length} notes from server');
    debugPrint('NotesRepository.sync: Sync complete');
  }
}