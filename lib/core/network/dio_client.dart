import 'package:dio/dio.dart';
import '../env.dart';
import '../storage/secure.dart';

class DioClient {
  final Dio dio;

  DioClient._(this.dio);

    factory DioClient(SecureStore secure) {
    final dio = Dio(BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
      validateStatus: (_) => true,
      headers: {'Accept': 'application/json'},
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (opts, handler) async {
        final token = await secure.readToken();
        if (token != null) opts.headers['Authorization'] = 'Bearer $token';
        handler.next(opts);
      },
    ));

    return DioClient._(dio);
  }
}