import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import 'plot_model.dart';

final plotApiServiceProvider = Provider<PlotApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return PlotApiService(dio);
});

class PlotApiService {
  final Dio _dio;

  PlotApiService(this._dio);

  Future<List<PlotModel>> getPlots({String? farmId}) async {
    final response = await _dio.get(
      ApiEndpoints.plots,
      queryParameters: farmId != null ? {'farmId': farmId} : null,
    );
    if (response.data is List) {
      return (response.data as List)
          .map((item) => PlotModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<PlotModel> createPlot({
    required String farmId,
    required String name,
    String? surveyNumber,
    String? subDivisionNumber,
    String? pattaNumber,
    double? enteredArea,
    String enteredUnit = 'cent',
    String? soilType,
    String? irrigationSource,
    String tenureType = 'owned',
    String? lessorName,
    double? annualRentInr,
    double? cropSharePct,
    String? notes,
  }) async {
    final payload = <String, dynamic>{
      'farmId': farmId,
      'name': name,
      'enteredUnit': enteredUnit,
      'tenureType': tenureType,
    };
    if (surveyNumber != null && surveyNumber.isNotEmpty) {
      payload['surveyNumber'] = surveyNumber;
    }
    if (subDivisionNumber != null && subDivisionNumber.isNotEmpty) {
      payload['subDivisionNumber'] = subDivisionNumber;
    }
    if (pattaNumber != null && pattaNumber.isNotEmpty) {
      payload['pattaNumber'] = pattaNumber;
    }
    if (enteredArea != null) {
      payload['enteredArea'] = enteredArea;
    }
    if (soilType != null) {
      payload['soilType'] = soilType;
    }
    if (irrigationSource != null) {
      payload['irrigationSource'] = irrigationSource;
    }
    if (lessorName != null && lessorName.isNotEmpty) {
      payload['lessorName'] = lessorName;
    }
    if (annualRentInr != null) {
      payload['annualRentInr'] = annualRentInr;
    }
    if (cropSharePct != null) {
      payload['cropSharePct'] = cropSharePct;
    }
    if (notes != null && notes.isNotEmpty) {
      payload['notes'] = notes;
    }

    final response = await _dio.post(ApiEndpoints.plots, data: payload);
    return PlotModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PlotModel> updatePlot({
    required String id,
    required String name,
    String? surveyNumber,
    String? subDivisionNumber,
    String? pattaNumber,
    double? enteredArea,
    String enteredUnit = 'cent',
    String? soilType,
    String? irrigationSource,
    String tenureType = 'owned',
    String? lessorName,
    double? annualRentInr,
    double? cropSharePct,
    String? notes,
  }) async {
    final payload = <String, dynamic>{
      'name': name,
      'enteredUnit': enteredUnit,
      'tenureType': tenureType,
    };
    if (surveyNumber != null) payload['surveyNumber'] = surveyNumber;
    if (subDivisionNumber != null) {
      payload['subDivisionNumber'] = subDivisionNumber;
    }
    if (pattaNumber != null) payload['pattaNumber'] = pattaNumber;
    if (enteredArea != null) payload['enteredArea'] = enteredArea;
    if (soilType != null) payload['soilType'] = soilType;
    if (irrigationSource != null) {
      payload['irrigationSource'] = irrigationSource;
    }
    if (lessorName != null) payload['lessorName'] = lessorName;
    if (annualRentInr != null) payload['annualRentInr'] = annualRentInr;
    if (cropSharePct != null) payload['cropSharePct'] = cropSharePct;
    if (notes != null) payload['notes'] = notes;

    final response =
        await _dio.put('${ApiEndpoints.plots}/$id', data: payload);
    return PlotModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deletePlot(String id) async {
    await _dio.delete('${ApiEndpoints.plots}/$id');
  }

  Future<List<StateLandPortalModel>> getLandPortals({String? stateCode}) async {
    final response = await _dio.get(
      ApiEndpoints.landPortals,
      queryParameters: stateCode != null ? {'stateCode': stateCode} : null,
    );
    if (response.data is List) {
      return (response.data as List)
          .map((item) =>
              StateLandPortalModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}

