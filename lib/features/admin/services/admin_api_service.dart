import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../models/admin_models.dart';

final adminApiServiceProvider = Provider<AdminApiService>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(secureStorageProvider);
  return AdminApiService(dio: dio, storageService: storage);
});

class AdminApiService {
  final Dio dio;
  final SecureStorageService storageService;

  AdminApiService({
    required this.dio,
    required this.storageService,
  });

  Future<AdminAuthResponse> login(String username, String password) async {
    final response = await dio.post(
      ApiEndpoints.adminLogin,
      data: {
        'username': username.trim(),
        'password': password,
      },
    );

    final authRes = AdminAuthResponse.fromJson(response.data as Map<String, dynamic>);
    await storageService.saveAdminToken(authRes.accessToken);
    return authRes;
  }

  Future<void> logout() async {
    await storageService.clearAdminToken();
  }

  Future<AdminDashboardStats> getStats() async {
    final response = await dio.get(ApiEndpoints.adminDashboardStats);
    return AdminDashboardStats.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<AdminOrgSummary>> getOrganizations({String? query, String? status}) async {
    final response = await dio.get(
      ApiEndpoints.adminOrgs,
      queryParameters: {
        if (query != null && query.isNotEmpty) 'q': query,
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );
    final list = response.data as List<dynamic>;
    return list.map((e) => AdminOrgSummary.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> updateOrgStatus(String id, String status) async {
    await dio.put(
      '${ApiEndpoints.adminOrgs}/$id/status',
      data: {'status': status},
    );
  }

  Future<List<AdminUserSummary>> getUsers({String? query, String? status}) async {
    final response = await dio.get(
      ApiEndpoints.adminUsers,
      queryParameters: {
        if (query != null && query.isNotEmpty) 'q': query,
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );
    final list = response.data as List<dynamic>;
    return list.map((e) => AdminUserSummary.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> updateUserStatus(String id, String status) async {
    await dio.put(
      '${ApiEndpoints.adminUsers}/$id/status',
      data: {'status': status},
    );
  }

  Future<List<AdminFarmSummary>> getFarms({String? query}) async {
    final response = await dio.get(
      ApiEndpoints.adminFarms,
      queryParameters: {
        if (query != null && query.isNotEmpty) 'q': query,
      },
    );
    final list = response.data as List<dynamic>;
    return list.map((e) => AdminFarmSummary.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<AdminSession>> getSessions({String? status}) async {
    final response = await dio.get(
      ApiEndpoints.adminSessions,
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );
    final list = response.data as List<dynamic>;
    return list.map((e) => AdminSession.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> revokeSession(String id, String reason) async {
    await dio.post(
      '${ApiEndpoints.adminSessions}/$id/revoke',
      data: {'reason': reason},
    );
  }
}
