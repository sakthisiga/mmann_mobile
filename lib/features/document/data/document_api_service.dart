import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import 'document_model.dart';

final documentApiServiceProvider = Provider<DocumentApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return DocumentApiService(dio);
});

class DocumentApiService {
  final Dio _dio;

  DocumentApiService(this._dio);

  Future<List<FarmDocumentModel>> getDocuments({
    String? farmId,
    String? plotId,
    String? category,
  }) async {
    final params = <String, dynamic>{};
    if (farmId != null) params['farmId'] = farmId;
    if (plotId != null) params['plotId'] = plotId;
    if (category != null) params['category'] = category;

    final response = await _dio.get(
      ApiEndpoints.documents,
      queryParameters: params,
    );
    final list = response.data as List;
    return list
        .map((e) => FarmDocumentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<FarmDocumentModel> createDocument({
    required String farmId,
    String? plotId,
    required String title,
    required String category,
    String? documentNumber,
    String? issuedBy,
    String? issueDate,
    String? expiryDate,
    String? fileName,
    String? mimeType,
    int? fileSizeBytes,
    String? fileDataUrl,
    String? notes,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.documents,
      data: {
        'farmId': farmId,
        if (plotId != null && plotId.isNotEmpty) 'plotId': plotId,
        'title': title,
        'category': category,
        if (documentNumber != null && documentNumber.isNotEmpty)
          'documentNumber': documentNumber,
        if (issuedBy != null && issuedBy.isNotEmpty) 'issuedBy': issuedBy,
        if (issueDate != null && issueDate.isNotEmpty) 'issueDate': issueDate,
        if (expiryDate != null && expiryDate.isNotEmpty)
          'expiryDate': expiryDate,
        if (fileName != null && fileName.isNotEmpty) 'fileName': fileName,
        if (mimeType != null && mimeType.isNotEmpty) 'mimeType': mimeType,
        'fileSizeBytes': ?fileSizeBytes,
        if (fileDataUrl != null && fileDataUrl.isNotEmpty)
          'fileDataUrl': fileDataUrl,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
    return FarmDocumentModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<FarmDocumentModel> updateDocument({
    required String id,
    String? plotId,
    required String title,
    required String category,
    String? documentNumber,
    String? issuedBy,
    String? issueDate,
    String? expiryDate,
    String? fileName,
    String? mimeType,
    int? fileSizeBytes,
    String? fileDataUrl,
    String? notes,
  }) async {
    final response = await _dio.put(
      '${ApiEndpoints.documents}/$id',
      data: {
        if (plotId != null && plotId.isNotEmpty) 'plotId': plotId,
        'title': title,
        'category': category,
        if (documentNumber != null && documentNumber.isNotEmpty)
          'documentNumber': documentNumber,
        if (issuedBy != null && issuedBy.isNotEmpty) 'issuedBy': issuedBy,
        if (issueDate != null && issueDate.isNotEmpty) 'issueDate': issueDate,
        if (expiryDate != null && expiryDate.isNotEmpty)
          'expiryDate': expiryDate,
        if (fileName != null && fileName.isNotEmpty) 'fileName': fileName,
        if (mimeType != null && mimeType.isNotEmpty) 'mimeType': mimeType,
        'fileSizeBytes': ?fileSizeBytes,
        if (fileDataUrl != null && fileDataUrl.isNotEmpty)
          'fileDataUrl': fileDataUrl,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
    return FarmDocumentModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteDocument(String id) async {
    await _dio.delete('${ApiEndpoints.documents}/$id');
  }
}
