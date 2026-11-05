import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/database_service.dart';
import '../data/document_api_service.dart';
import '../data/document_model.dart';
import 'document_state.dart';

final documentNotifierProvider =
    StateNotifierProvider<DocumentNotifier, DocumentState>((ref) {
  final apiService = ref.watch(documentApiServiceProvider);
  return DocumentNotifier(apiService);
});

class DocumentNotifier extends StateNotifier<DocumentState> {
  final DocumentApiService _apiService;

  DocumentNotifier(this._apiService) : super(const DocumentState()) {
    loadDocuments();
  }

  Future<void> loadDocuments() async {
    // 1. Instant offline read from local SQLite
    final cachedMaps = await DatabaseService.getCachedDocuments();
    if (cachedMaps.isNotEmpty) {
      state = state.copyWith(
        documentsList:
            cachedMaps.map((m) => FarmDocumentModel.fromSqlite(m)).toList(),
      );
    }

    // 2. Refresh from server & update SQLite cache
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final remoteDocs = await _apiService.getDocuments();
      await DatabaseService.cacheDocuments(
        remoteDocs.map((d) => d.toSqlite()).toList(),
      );
      state = state.copyWith(
        documentsList: remoteDocs,
        isLoading: false,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> createDocument({
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
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final created = await _apiService.createDocument(
        farmId: farmId,
        plotId: plotId,
        title: title,
        category: category,
        documentNumber: documentNumber,
        issuedBy: issuedBy,
        issueDate: issueDate,
        expiryDate: expiryDate,
        fileName: fileName,
        mimeType: mimeType,
        fileSizeBytes: fileSizeBytes,
        fileDataUrl: fileDataUrl,
        notes: notes,
      );

      final updated = [created, ...state.documentsList];
      await DatabaseService.cacheDocuments(
        updated.map((d) => d.toSqlite()).toList(),
      );
      state = state.copyWith(documentsList: updated, isLoading: false);
      return true;
    } on DioException catch (e) {
      final detail = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['message'] as String? ??
              e.response?.data['detail'] as String? ??
              e.message)
          : e.message;
      state = state.copyWith(isLoading: false, errorMessage: detail);
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to save document.',
      );
      return false;
    }
  }

  Future<bool> updateDocument({
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
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final updatedDoc = await _apiService.updateDocument(
        id: id,
        plotId: plotId,
        title: title,
        category: category,
        documentNumber: documentNumber,
        issuedBy: issuedBy,
        issueDate: issueDate,
        expiryDate: expiryDate,
        fileName: fileName,
        mimeType: mimeType,
        fileSizeBytes: fileSizeBytes,
        fileDataUrl: fileDataUrl,
        notes: notes,
      );

      final updatedList = state.documentsList
          .map((d) => d.id == updatedDoc.id ? updatedDoc : d)
          .toList();
      await DatabaseService.cacheDocuments(
        updatedList.map((d) => d.toSqlite()).toList(),
      );
      state = state.copyWith(documentsList: updatedList, isLoading: false);
      return true;
    } catch (_) {
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  Future<void> deleteDocument(String id) async {
    try {
      await _apiService.deleteDocument(id);
      final updatedList =
          state.documentsList.where((d) => d.id != id).toList();
      await DatabaseService.cacheDocuments(
        updatedList.map((d) => d.toSqlite()).toList(),
      );
      state = state.copyWith(documentsList: updatedList);
    } catch (_) {}
  }
}

