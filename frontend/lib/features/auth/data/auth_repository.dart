import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure.dart';
import 'auth_api.dart';

class AuthRepository {
  final AuthApi _api;
  final SecureStore _secure;

  AuthRepository(DioClient client, this._secure) : _api = AuthApi(client.dio);

  Future<void> register(String name, String email, String password) =>
      _api.register(name, email, password);

  Future<void> login(String email, String password) async {
    final token = await _api.login(email, password);
    await _secure.saveToken(token);
  }

  Future<void> logout() => _secure.clear();
}