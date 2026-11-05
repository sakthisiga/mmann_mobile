class FarmDocumentModel {
  final String id;
  final String farmId;
  final String? plotId;
  final String title;
  final String category;
  final String? documentNumber;
  final String? issuedBy;
  final String? issueDate;
  final String? expiryDate;
  final String renewalStatus;
  final int? daysUntilExpiry;
  final String? fileName;
  final String? mimeType;
  final int? fileSizeBytes;
  final String? fileDataUrl;
  final String? notes;
  final int rev;
  final String? updatedAt;

  const FarmDocumentModel({
    required this.id,
    required this.farmId,
    this.plotId,
    required this.title,
    required this.category,
    this.documentNumber,
    this.issuedBy,
    this.issueDate,
    this.expiryDate,
    this.renewalStatus = 'NO_EXPIRY',
    this.daysUntilExpiry,
    this.fileName,
    this.mimeType,
    this.fileSizeBytes,
    this.fileDataUrl,
    this.notes,
    this.rev = 1,
    this.updatedAt,
  });

  factory FarmDocumentModel.fromJson(Map<String, dynamic> json) {
    return FarmDocumentModel(
      id: json['id']?.toString() ?? '',
      farmId: json['farmId']?.toString() ?? '',
      plotId: json['plotId']?.toString(),
      title: json['title']?.toString() ?? '',
      category: json['category']?.toString() ?? 'patta_chitta',
      documentNumber: json['documentNumber']?.toString(),
      issuedBy: json['issuedBy']?.toString(),
      issueDate: json['issueDate']?.toString(),
      expiryDate: json['expiryDate']?.toString(),
      renewalStatus: json['renewalStatus']?.toString() ?? 'NO_EXPIRY',
      daysUntilExpiry: (json['daysUntilExpiry'] as num?)?.toInt(),
      fileName: json['fileName']?.toString(),
      mimeType: json['mimeType']?.toString(),
      fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt(),
      fileDataUrl: json['fileDataUrl']?.toString(),
      notes: json['notes']?.toString(),
      rev: (json['rev'] as num?)?.toInt() ?? 1,
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  factory FarmDocumentModel.fromSqlite(Map<String, dynamic> map) {
    return FarmDocumentModel(
      id: map['id'] as String,
      farmId: map['farm_id'] as String,
      plotId: map['plot_id'] as String?,
      title: map['title'] as String,
      category: map['category'] as String? ?? 'patta_chitta',
      documentNumber: map['document_number'] as String?,
      issuedBy: map['issued_by'] as String?,
      issueDate: map['issue_date'] as String?,
      expiryDate: map['expiry_date'] as String?,
      renewalStatus: map['renewal_status'] as String? ?? 'NO_EXPIRY',
      daysUntilExpiry: (map['days_until_expiry'] as num?)?.toInt(),
      fileName: map['file_name'] as String?,
      mimeType: map['mime_type'] as String?,
      fileSizeBytes: (map['file_size_bytes'] as num?)?.toInt(),
      fileDataUrl: map['file_data_url'] as String?,
      notes: map['notes'] as String?,
      rev: (map['rev'] as num?)?.toInt() ?? 1,
      updatedAt: map['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toSqlite() {
    return {
      'id': id,
      'farm_id': farmId,
      'plot_id': plotId,
      'title': title,
      'category': category,
      'document_number': documentNumber,
      'issued_by': issuedBy,
      'issue_date': issueDate,
      'expiry_date': expiryDate,
      'renewal_status': renewalStatus,
      'days_until_expiry': daysUntilExpiry,
      'file_name': fileName,
      'mime_type': mimeType,
      'file_size_bytes': fileSizeBytes,
      'file_data_url': fileDataUrl,
      'notes': notes,
      'rev': rev,
      'updated_at': updatedAt,
    };
  }
}

