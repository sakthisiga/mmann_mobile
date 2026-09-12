import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import 'auth_models.dart';

final authApiServiceProvider = Provider<AuthApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthApiService(dio);
});

class AuthApiService {
  final Dio _dio;

  AuthApiService(this._dio);

  Future<bool> checkMobile(String mobile) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.checkMobile,
        queryParameters: {'mobile': mobile},
      );
      if (response.statusCode == 200 && response.data is Map) {
        return (response.data['exists'] as bool?) ?? false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestOtp({
    required String mobile,
    required String language,
    bool? isRegistration,
  }) async {
    // Map simple locale codes ('ta', 'te') to backend expected language code ('ta-IN')
    final langCode = language.contains('-') ? language : '$language-IN';

    final data = <String, dynamic>{
      'mobile': mobile,
      'language': langCode,
    };
    if (isRegistration != null) {
      data['isRegistration'] = isRegistration;
    }

    final response = await _dio.post(
      ApiEndpoints.requestOtp,
      data: data,
    );

    return response.statusCode == 200;
  }

  Future<AuthResponse> verifyOtp({
    required String mobile,
    required String otp,
    String? displayName,
    String? stateCode,
    String? language,
    String? deviceId,
    int? age,
    String? village,
    String? taluk,
    String? district,
    bool? isRegistration,
  }) async {
    final langCode = language != null
        ? (language.contains('-') ? language : '$language-IN')
        : null;

    final payload = <String, dynamic>{
      'mobile': mobile,
      'otp': otp,
    };
    if (displayName != null && displayName.isNotEmpty) {
      payload['displayName'] = displayName;
    }
    if (stateCode != null) {
      payload['stateCode'] = stateCode;
    }
    if (langCode != null) {
      payload['language'] = langCode;
    }
    if (deviceId != null) {
      payload['deviceId'] = deviceId;
    }
    if (age != null) {
      payload['age'] = age;
    }
    if (village != null && village.isNotEmpty) {
      payload['village'] = village;
    }
    if (taluk != null && taluk.isNotEmpty) {
      payload['taluk'] = taluk;
    }
    if (district != null && district.isNotEmpty) {
      payload['district'] = district;
    }
    if (isRegistration != null) {
      payload['isRegistration'] = isRegistration;
    }

    final response = await _dio.post(
      ApiEndpoints.verifyOtp,
      data: payload,
    );

    return AuthResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getMe() async {
    final response = await _dio.get(ApiEndpoints.me);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProfile({
    required String displayName,
    int? age,
    String? stateCode,
    String? language,
    String? district,
    String? taluk,
    String? village,
  }) async {
    final langCode = language != null
        ? (language.contains('-') ? language : '$language-IN')
        : null;

    final payload = <String, dynamic>{
      'displayName': displayName,
      'age': ?age,
      'stateCode': ?stateCode,
      'language': ?langCode,
      'district': ?district,
      'taluk': ?taluk,
      'village': ?village,
    };

    final response = await _dio.put(
      ApiEndpoints.updateProfile,
      data: payload,
    );

    return response.data as Map<String, dynamic>;
  }
}
