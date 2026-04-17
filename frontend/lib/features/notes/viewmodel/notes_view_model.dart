import 'package:flutter/foundation.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure.dart';
import '../data/notes_local_db.dart';
import '../data/notes_repository.dart';
import '../domain/note.dart';

class NotesViewModel extends ChangeNotifier {
  late final NotesLocalDb _db;
  late final NotesRepository _repo;

  bool _busy = false;
  String? _error;
  List<Note> _items = [];

  bool get busy => _busy;
  String? get error => _error;
  List<Note> get items => _items;

  Future<void> init(SecureStore secure, {required String host, int port = 3000}) async {
    try {
      _db = NotesLocalDb();
      await _db.init();
      debugPrint('Database initialized');
      _repo = NotesRepository(DioClient(secure), _db, host: host, port: port);
      await loadLocal();
      debugPrint('Local notes loaded: ${_items.length}');
      await sync();
    } catch (e) {
      debugPrint('Init error: $e');
      _error = e.toString();
    }
  }

  Future<void> loadLocal() async {
    _setBusy(true);
    try {
      _items = await _repo.listLocal();
      debugPrint('Loaded ${_items.length} notes from local DB');
    } catch (e) {
      debugPrint('LoadLocal error: $e');
      _error = e.toString();
    } finally {
      _setBusy(false);
    }
  }

  Future<void> sync() async {
    _setBusy(true);
    try {
      await _repo.sync();
      _items = await _repo.listLocal();
      debugPrint('Sync complete, ${_items.length} notes');
    } catch (e) {
      debugPrint('Sync error (keeping local): $e');
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> add(String title, String content, {String? location}) async {
    try {
      await _repo.createLocal(title, content, location: location);
      debugPrint('NotesViewModel.add: Created locally: $title');
      await loadLocal();
      await sync();
      debugPrint('NotesViewModel.add: Complete');
      return true;
    } catch (e) {
      debugPrint('NotesViewModel.add error: $e');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> edit(String id, String title, String content, {String? location}) async {
    try {
      await _repo.updateLocal(id, title, content, location: location);
      debugPrint('NotesViewModel.edit: Updated locally: $title');
      await loadLocal();
      await sync();
      return true;
    } catch (e) {
      debugPrint('NotesViewModel.edit error: $e');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> remove(String id) async {
    try {
      await _repo.deleteLocal(id);
      debugPrint('NotesViewModel.remove: Deleted locally: $id');
      await loadLocal();
      await sync();
      return true;
    } catch (e) {
      debugPrint('Remove error: $e');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void _setBusy(bool v) { _busy = v; notifyListeners(); }
}