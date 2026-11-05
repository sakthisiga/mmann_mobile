class PlotTenureModel {
  final String? id;
  final String tenureType; // owned, leased_cash, leased_cropshare
  final String? lessorName;
  final String? lessorMobile;
  final double? annualRentInr;
  final double? cropSharePct;
  final String? notes;

  const PlotTenureModel({
    this.id,
    this.tenureType = 'owned',
    this.lessorName,
    this.lessorMobile,
    this.annualRentInr,
    this.cropSharePct,
    this.notes,
  });

  factory PlotTenureModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const PlotTenureModel(tenureType: 'owned');
    }
    return PlotTenureModel(
      id: json['id']?.toString(),
      tenureType: json['tenureType']?.toString() ?? 'owned',
      lessorName: json['lessorName']?.toString(),
      lessorMobile: json['lessorMobile']?.toString(),
      annualRentInr: json['annualRentInr'] != null
          ? (json['annualRentInr'] as num).toDouble()
          : null,
      cropSharePct: json['cropSharePct'] != null
          ? (json['cropSharePct'] as num).toDouble()
          : null,
      notes: json['notes']?.toString(),
    );
  }
}

class PlotModel {
  final String id;
  final String farmId;
  final String name;
  final String? surveyNumber;
  final String? subDivisionNumber;
  final String? pattaNumber;
  final double? areaSqm;
  final double? enteredArea;
  final String? enteredUnit;
  final String? soilType;
  final String? irrigationSource;
  final String? notes;
  final PlotTenureModel tenure;
  final int rev;
  final String? updatedAt;

  const PlotModel({
    required this.id,
    required this.farmId,
    required this.name,
    this.surveyNumber,
    this.subDivisionNumber,
    this.pattaNumber,
    this.areaSqm,
    this.enteredArea,
    this.enteredUnit,
    this.soilType,
    this.irrigationSource,
    this.notes,
    this.tenure = const PlotTenureModel(),
    this.rev = 1,
    this.updatedAt,
  });

  factory PlotModel.fromJson(Map<String, dynamic> json) {
    return PlotModel(
      id: json['id']?.toString() ?? '',
      farmId: json['farmId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      surveyNumber: json['surveyNumber']?.toString(),
      subDivisionNumber: json['subDivisionNumber']?.toString(),
      pattaNumber: json['pattaNumber']?.toString(),
      areaSqm:
          json['areaSqm'] != null ? (json['areaSqm'] as num).toDouble() : null,
      enteredArea: json['enteredArea'] != null
          ? (json['enteredArea'] as num).toDouble()
          : null,
      enteredUnit: json['enteredUnit']?.toString(),
      soilType: json['soilType']?.toString(),
      irrigationSource: json['irrigationSource']?.toString(),
      notes: json['notes']?.toString(),
      tenure: PlotTenureModel.fromJson(
          json['tenure'] as Map<String, dynamic>?),
      rev: (json['rev'] as num?)?.toInt() ?? 1,
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  factory PlotModel.fromSqlite(Map<String, dynamic> map) {
    return PlotModel(
      id: map['id'] as String,
      farmId: map['farm_id'] as String,
      name: map['name'] as String,
      surveyNumber: map['survey_number'] as String?,
      subDivisionNumber: map['sub_division_number'] as String?,
      pattaNumber: map['patta_number'] as String?,
      areaSqm: (map['area_sqm'] as num?)?.toDouble(),
      enteredArea: (map['entered_area'] as num?)?.toDouble(),
      enteredUnit: map['entered_unit'] as String?,
      soilType: map['soil_type'] as String?,
      irrigationSource: map['irrigation_source'] as String?,
      notes: map['notes'] as String?,
      tenure: PlotTenureModel(
        tenureType: map['tenure_type'] as String? ?? 'owned',
        lessorName: map['lessor_name'] as String?,
        lessorMobile: map['lessor_mobile'] as String?,
        annualRentInr: (map['annual_rent_inr'] as num?)?.toDouble(),
        cropSharePct: (map['crop_share_pct'] as num?)?.toDouble(),
      ),
      rev: (map['rev'] as num?)?.toInt() ?? 1,
      updatedAt: map['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toSqlite() {
    return {
      'id': id,
      'farm_id': farmId,
      'name': name,
      'survey_number': surveyNumber,
      'sub_division_number': subDivisionNumber,
      'patta_number': pattaNumber,
      'area_sqm': areaSqm,
      'entered_area': enteredArea,
      'entered_unit': enteredUnit,
      'soil_type': soilType,
      'irrigation_source': irrigationSource,
      'tenure_type': tenure.tenureType,
      'lessor_name': tenure.lessorName,
      'lessor_mobile': tenure.lessorMobile,
      'annual_rent_inr': tenure.annualRentInr,
      'crop_share_pct': tenure.cropSharePct,
      'notes': notes,
      'rev': rev,
      'updated_at': updatedAt,
    };
  }
}

class StateLandPortalModel {
  final String stateCode;
  final String stateName;
  final String portalName;
  final String portalUrl;
  final List<String> documentTypes;
  final String legalDisclaimer;

  const StateLandPortalModel({
    required this.stateCode,
    required this.stateName,
    required this.portalName,
    required this.portalUrl,
    required this.documentTypes,
    required this.legalDisclaimer,
  });

  factory StateLandPortalModel.fromJson(Map<String, dynamic> json) {
    return StateLandPortalModel(
      stateCode: json['stateCode']?.toString() ?? 'TN',
      stateName: json['stateName']?.toString() ?? '',
      portalName: json['portalName']?.toString() ?? '',
      portalUrl: json['portalUrl']?.toString() ?? '',
      documentTypes: (json['documentTypes'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      legalDisclaimer: json['legalDisclaimer']?.toString() ?? '',
    );
  }
}

