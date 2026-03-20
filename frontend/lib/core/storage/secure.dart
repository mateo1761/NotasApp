import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStore {
  final _storage = const FlutterSecureStorage();
  static const _kTokenKey = 'access_token';

  Future<void> saveToken(String token) => _storage.write(key: _kTokenKey, value: token);
  Future<String?> readToken() => _storage.read(key: _kTokenKey);
  Future<void> clear() => _storage.delete(key: _kTokenKey);
}