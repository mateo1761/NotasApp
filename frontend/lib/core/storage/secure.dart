import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStore {
  final _storage = const FlutterSecureStorage();
  static const _kTokenKey = 'access_token';

  Future<void> saveToken(String token) => _storage.write(key: _kTokenKey, value: token);
  Future<String?> readToken() => _storage.read(key: _kTokenKey);
  Future<void> clear() => _storage.delete(key: _kTokenKey);

  Future<Map<String, dynamic>?> readTokenPayload() async {
    final token = await readToken();
    if (token == null) return null;

    final parts = token.split('.');
    if (parts.length != 3) return null;

    final payload = parts[1];
    final normalized = base64Url.normalize(payload);
    final decoded = utf8.decode(base64Url.decode(normalized));
    return json.decode(decoded) as Map<String, dynamic>;
  }
}