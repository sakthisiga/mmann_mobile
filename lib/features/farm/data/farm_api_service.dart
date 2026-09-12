import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import 'farm_model.dart';

final farmApiServiceProvider = Provider<FarmApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return FarmApiService(dio);
});

class FarmApiService {
  final Dio _dio;

  FarmApiService(this._dio);

  Future<List<Farm>> getFarms() async {
    final response = await _dio.get(ApiEndpoints.farms);
    if (response.data is List) {
      final list = response.data as List;
      return list
          .map((item) => Farm.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<Farm> createFarm({
    required String name,
    String? village,
    String? taluk,
    String? district,
    String? stateCode,
    String? pincode,
    double? enteredArea,
    String enteredUnit = 'acre',
    bool isPrimary = false,
    String? notes,
  }) async {
    final payload = <String, dynamic>{
      'name': name,
      'enteredUnit': enteredUnit,
      'isPrimary': isPrimary,
    };
    if (village != null && village.isNotEmpty) {
      payload['village'] = village;
    }
    if (taluk != null && taluk.isNotEmpty) {
      payload['taluk'] = taluk;
    }
    if (district != null && district.isNotEmpty) {
      payload['district'] = district;
    }
    if (stateCode != null) {
      payload['stateCode'] = stateCode;
    }
    if (pincode != null && pincode.isNotEmpty) {
      payload['pincode'] = pincode;
    }
    if (enteredArea != null) {
      payload['enteredArea'] = enteredArea;
    }
    if (notes != null && notes.isNotEmpty) {
      payload['notes'] = notes;
    }

    final response = await _dio.post(
      ApiEndpoints.farms,
      data: payload,
    );

    return Farm.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Farm> updateFarm({
    required String id,
    required String name,
    String? village,
    String? taluk,
    String? district,
    String? stateCode,
    String? pincode,
    double? enteredArea,
    String enteredUnit = 'acre',
    bool isPrimary = false,
    String? notes,
  }) async {
    final payload = <String, dynamic>{
      'name': name,
      'enteredUnit': enteredUnit,
      'isPrimary': isPrimary,
    };
    if (village != null && village.isNotEmpty) {
      payload['village'] = village;
    }
    if (taluk != null && taluk.isNotEmpty) {
      payload['taluk'] = taluk;
    }
    if (district != null && district.isNotEmpty) {
      payload['district'] = district;
    }
    if (stateCode != null) {
      payload['stateCode'] = stateCode;
    }
    if (pincode != null && pincode.isNotEmpty) {
      payload['pincode'] = pincode;
    }
    if (enteredArea != null) {
      payload['enteredArea'] = enteredArea;
    }
    if (notes != null && notes.isNotEmpty) {
      payload['notes'] = notes;
    }

    final response = await _dio.put(
      '${ApiEndpoints.farms}/$id',
      data: payload,
    );

    return Farm.fromJson(response.data as Map<String, dynamic>);
  }
}
