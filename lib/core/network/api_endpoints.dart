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
}
