import 'package:flutter/foundation.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure.dart';
import '../data/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final SecureStore _secure;
  late final AuthRepository _repo;

  bool _busy = false;
  String? _error;
  bool _isAuth = false;
  bool _initialized = false;

  bool get busy => _busy;
  String? get error => _error;
  bool get isAuthenticated => _isAuth;
  bool get isInitialized => _initialized;

  AuthViewModel(this._secure) {
    _repo = AuthRepository(DioClient(_secure), _secure);
  }

  Future<void> init() async {
    try {
      final String? token = await _secure.readToken();
      _isAuth = token != null && token.isNotEmpty;
    } catch (e) {
      debugPrint('AuthViewModel.init error: $e');
      _isAuth = false;
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> register(String name, String email, String password) async {
    _setBusy(true);
    _error = null;
    try {
      await _repo.register(name, email, password);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setBusy(false);
    }
  }

  Future<void> login(String email, String password) async {
    _setBusy(true);
    _error = null;
    try {
      await _repo.login(email, password);
      _isAuth = true;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setBusy(false);
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    _isAuth = false;
    notifyListeners();
  }

  void _setBusy(bool v) { _busy = v; notifyListeners(); }
}