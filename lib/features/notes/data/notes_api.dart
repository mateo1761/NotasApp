import 'package:dio/dio.dart';
import '../domain/note.dart';
class NotesApi {
  final Dio dio;
  NotesApi(this.dio);

  Future<List<Note>> list() async {
    final res = await dio.get('/notes');
    if (res.statusCode == 200) {
      final list = (res.data as List).cast<Map<String, dynamic>>();
      return list.map((e) => Note.fromJson(e)).toList();
    }
    throw Exception('List failed [${res.statusCode}]: ${res.data}');
  }

  Future<Note> create(String title, String content) async {
    final res = await dio.post('/notes', data: {'title': title, 'content': content});
    if (res.statusCode == 201) return Note.fromJson(res.data as Map<String, dynamic>);
    throw Exception('Create failed [${res.statusCode}]: ${res.data}');
  }

  Future<Note> update(String id, String title, String content) async {
    final res = await dio.put('/notes/$id', data: {'title': title, 'content': content});
    if (res.statusCode == 200) return Note.fromJson(res.data as Map<String, dynamic>);
    throw Exception('Update failed [${res.statusCode}]: ${res.data}');
  }

  Future<void> delete(String id) async {
    final res = await dio.delete('/notes/$id');
    if (res.statusCode == 204) return;
    throw Exception('Delete failed [${res.statusCode}]: ${res.data}');
  }
}