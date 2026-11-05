import '../data/document_model.dart';

class DocumentState {
  final List<FarmDocumentModel> documentsList;
  final bool isLoading;
  final String? errorMessage;

  const DocumentState({
    this.documentsList = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  List<FarmDocumentModel> documentsForFarm(String? farmId) {
    if (farmId == null || farmId.isEmpty) return documentsList;
    return documentsList.where((d) => d.farmId == farmId).toList();
  }

  int expiringCountForFarm(String? farmId) {
    return documentsForFarm(farmId)
        .where((d) =>
            d.renewalStatus == 'EXPIRING_SOON' || d.renewalStatus == 'EXPIRED')
        .length;
  }

  int landDocsCountForFarm(String? farmId) {
    return documentsForFarm(farmId)
        .where((d) =>
            d.category == 'patta_chitta' ||
            d.category == 'adangal_rtc' ||
            d.category == 'fmb_sketch' ||
            d.category == 'lease_agreement')
        .length;
  }

  DocumentState copyWith({
    List<FarmDocumentModel>? documentsList,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DocumentState(
      documentsList: documentsList ?? this.documentsList,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

