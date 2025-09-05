import 'package:flutter/foundation.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure.dart';
import '../data/notes_repository.dart';
import '../domain/note.dart';
class NotesViewModel extends ChangeNotifier {
  late final NotesRepository _repo;

  bool _busy = false;
  String? _error;
  List<Note> _items = [];

  bool get busy => _busy;
  String? get error => _error;
  List<Note> get items => _items;

  NotesViewModel(SecureStore secure) {
    _repo = NotesRepository(DioClient(secure));
  }

  Future<void> load() async {
    _setBusy(true);
    _error = null;
    try {
      _items = await _repo.list();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> add(String title, String content) async {
    _setBusy(true);
    try {
      final created = await _repo.create(title, content);
      _items = [created, ..._items];
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> edit(String id, String title, String content) async {
    _setBusy(true);
    try {
      final updated = await _repo.update(id, title, content);
      _items = _items.map((n) => n.id == id ? updated : n).toList();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> remove(String id) async {
    _setBusy(true);
    try {
      await _repo.delete(id);
      _items = _items.where((n) => n.id != id).toList();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> refresh() => load();

  void _setBusy(bool v) { _busy = v; notifyListeners(); }
}