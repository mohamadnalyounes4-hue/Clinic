import 'package:dio/dio.dart';
import 'package:nabad/core/Cache/cache_helper.dart';

class ApiInterceptors extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = CacheHelper.getData(key: 'token');

    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    options.headers['Accept'] = 'application/json';

    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // ✅ static calls
      CacheHelper.removeData(key: 'token');
      CacheHelper.removeData(key: 'id');
      CacheHelper.removeData(key: 'role');
    }
    super.onError(err, handler);
  }
}