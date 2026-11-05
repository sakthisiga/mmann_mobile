import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiEndpoints {
  static const String port = String.fromEnvironment('API_PORT', defaultValue: '8088');

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:$port';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:$port';
    }
    return 'http://localhost:$port';
  }

  static const String checkMobile = '/v1/auth/check-mobile';
  static const String requestOtp = '/v1/auth/request-otp';
  static const String verifyOtp = '/v1/auth/verify-otp';
  static const String refreshToken = '/v1/auth/refresh';
  static const String me = '/v1/auth/me';
  static const String updateProfile = '/v1/auth/profile';
  static const String farms = '/v1/farms';
  static const String plots = '/v1/plots';
  static const String landPortals = '/v1/plots/land-portals';
  static const String documents = '/v1/documents';

  // Super Admin Endpoints (M1 Identity, Org & Access)
  static const String adminLogin = '/v1/admin/auth/login';
  static const String adminDashboardStats = '/v1/admin/dashboard/stats';
  static const String adminOrgs = '/v1/admin/orgs';
  static const String adminUsers = '/v1/admin/users';
  static const String adminMemberships = '/v1/admin/memberships';
  static const String adminFarms = '/v1/admin/farms';
  static const String adminSessions = '/v1/admin/sessions';
  static const String adminConsents = '/v1/admin/consents';
}
