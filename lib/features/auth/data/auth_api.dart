import 'package:dio/dio.dart';

class AuthApi {
  final Dio dio;
  AuthApi(this.dio);

  Future<void> register(String name, String email, String password) async {
    final res = await dio.post('/auth/register', data: {
      'name': name, 'email': email, 'password': password,
    });
    if (res.statusCode != 201) {
      throw Exception(res.data is Map ? (res.data['message'] ?? 'Register failed') : 'Register failed');
    }
  }

  Future<String> login(String email, String password) async {
    final res = await dio.post('/auth/login', data: {
      'email': email, 'password': password,
    });
    if (res.statusCode == 200 && res.data is Map && res.data['accessToken'] != null) {
      return res.data['accessToken'] as String;
    }
    throw Exception(res.data is Map ? (res.data['message'] ?? 'Login failed') : 'Login failed');
  }
}