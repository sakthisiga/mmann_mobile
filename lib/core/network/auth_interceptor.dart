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
    final isAdminPath = options.path.contains('/v1/admin/');
    final isAdminLogin = options.path.contains(ApiEndpoints.adminLogin);

    if (isAdminPath) {
      if (!isAdminLogin) {
        final adminToken = await storageService.getAdminToken();
        if (adminToken != null && adminToken.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $adminToken';
        }
      }
      return handler.next(options);
    }

    // Skip adding auth header for farmer public auth endpoints
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
    final isAdminPath = err.requestOptions.path.contains('/v1/admin/');

    if (isAdminPath) {
      if (response?.statusCode == 401) {
        await storageService.clearAdminToken();
      }
      return handler.next(err);
    }

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

          if (refreshResponse.statusCode == 200) {
            final data = refreshResponse.data;
            final newAccessToken = data['accessToken'] as String;
            final newRefreshToken = data['refreshToken'] as String;

            // Persist the rotated tokens
            await storageService.saveTokens(
              accessToken: newAccessToken,
              refreshToken: newRefreshToken,
            );

            // Retry original request with the fresh access token
            final retryOptions = err.requestOptions;
            retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';

            final retryResponse = await dio.fetch(retryOptions);
            return handler.resolve(retryResponse);
          }
        } catch (refreshErr) {
          // Token refresh failed completely — clear tokens to force user re-login
          await storageService.clearAll();
        }
      } else {
        await storageService.clearAll();
      }
    }

    return handler.next(err);
  }
}
