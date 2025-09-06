import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure.dart';
import '../../../core/utils/connectivity.dart';
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
    _db = NotesLocalDb();
    await _db.init();
    _repo = NotesRepository(DioClient(secure), _db, host: host, port: port);
    await loadLocal();
    await sync();
  }

  Future<void> loadLocal() async {
    _setBusy(true);
    _items = await _repo.listLocal();
    _setBusy(false);
  }

  Future<void> sync() async {
    _setBusy(true);
    try {
      await _repo.sync();
      _items = await _repo.listLocal();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> add(String title, String content) async {
    await _repo.createLocal(title, content);
    await loadLocal();
    // Intento de sync si hay red
    await sync();
    return true;
  }

  Future<bool> edit(String id, String title, String content) async {
    await _repo.updateLocal(id, title, content);
    await loadLocal();
    await sync();
    return true;
  }

  Future<bool> remove(String id) async {
    await _repo.deleteLocal(id);
    await loadLocal();
    await sync();
    return true;
  }

  void _setBusy(bool v) { _busy = v; notifyListeners(); }
}