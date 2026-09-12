import 'package:dio/dio.dart';
import '../storage/secure_storage_service.dart';
import 'api_endpoints.dart';

class AuthInterceptor extends QueuedInterceptor {
  final Dio dio;
  final SecureStorageService storageService;

  AuthInterceptor({
    required this.dio,
    required this.storageService,
  });

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip adding auth header for auth endpoints
    final isAuthEndpoint = options.path.contains(ApiEndpoints.requestOtp) ||
        options.path.contains(ApiEndpoints.verifyOtp) ||
        options.path.contains(ApiEndpoints.refreshToken);

    if (!isAuthEndpoint) {
      final token = await storageService.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;

    // Check if error is 401 Unauthorized and not already refreshing
    final isRefreshRequest = err.requestOptions.path.contains(ApiEndpoints.refreshToken);
    if (response?.statusCode == 401 && !isRefreshRequest) {
      final refreshToken = await storageService.getRefreshToken();

      if (refreshToken != null && refreshToken.isNotEmpty) {
        try {
          // Attempt silent token refresh using dedicated Dio instance without interceptors
          final refreshDio = Dio(BaseOptions(
            baseUrl: ApiEndpoints.baseUrl,
            headers: {'Content-Type': 'application/json'},
          ));

          final refreshResponse = await refreshDio.post(
            ApiEndpoints.refreshToken,
            data: {'refreshToken': refreshToken},
          );

          if (refreshResponse.statusCode == 200 && refreshResponse.data != null) {
            final data = refreshResponse.data as Map<String, dynamic>;
            final newAccessToken = data['accessToken'] as String?;
            final newRefreshToken = data['refreshToken'] as String?;

            if (newAccessToken != null && newRefreshToken != null) {
              await storageService.saveTokens(
                accessToken: newAccessToken,
                refreshToken: newRefreshToken,
              );

              // Retry original request with new token
              final opts = err.requestOptions;
              opts.headers['Authorization'] = 'Bearer $newAccessToken';

              final retryResponse = await dio.fetch(opts);
              return handler.resolve(retryResponse);
            }
          }
        } catch (_) {
          // Token refresh failed, session is revoked
          await storageService.clearAll();
        }
      }
    }

    return handler.next(err);
  }
}
