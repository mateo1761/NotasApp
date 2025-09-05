import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure.dart';
import '../domain/note.dart';
import 'notes_api.dart';

class NotesRepository {
  final NotesApi _api;
  NotesRepository(DioClient client) : _api = NotesApi(client.dio);

  Future<List<Note>> list() => _api.list();
  Future<Note> create(String title, String content) => _api.create(title, content);
  Future<Note> update(String id, String title, String content) => _api.update(id, title, content);
  Future<void> delete(String id) => _api.delete(id);
}