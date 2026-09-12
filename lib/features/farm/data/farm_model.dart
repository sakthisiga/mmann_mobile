class Farm {
  final String id;
  final String name;
  final String? village;
  final String? taluk;
  final String? district;
  final String? stateCode;
  final String? pincode;
  final double? totalAreaSqm;
  final double? enteredArea;
  final String enteredUnit;
  final bool isPrimary;
  final String? notes;
  final int rev;

  Farm({
    required this.id,
    required this.name,
    this.village,
    this.taluk,
    this.district,
    this.stateCode,
    this.pincode,
    this.totalAreaSqm,
    this.enteredArea,
    this.enteredUnit = 'acre',
    this.isPrimary = false,
    this.notes,
    this.rev = 1,
  });

  factory Farm.fromJson(Map<String, dynamic> json) {
    return Farm(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      village: json['village'] as String?,
      taluk: json['taluk'] as String?,
      district: json['district'] as String?,
      stateCode: json['stateCode'] as String?,
      pincode: json['pincode'] as String?,
      totalAreaSqm: (json['totalAreaSqm'] as num?)?.toDouble(),
      enteredArea: (json['enteredArea'] as num?)?.toDouble(),
      enteredUnit: json['enteredUnit'] as String? ?? 'acre',
      isPrimary: json['isPrimary'] as bool? ?? false,
      notes: json['notes'] as String?,
      rev: json['rev'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'village': village,
        'taluk': taluk,
        'district': district,
        'stateCode': stateCode,
        'pincode': pincode,
        'totalAreaSqm': totalAreaSqm,
        'enteredArea': enteredArea,
        'enteredUnit': enteredUnit,
        'isPrimary': isPrimary,
        'notes': notes,
        'rev': rev,
      };

  Map<String, dynamic> toSqlite() => {
        'id': id,
        'name': name,
        'village': village,
        'taluk': taluk,
        'district': district,
        'state_code': stateCode,
        'pincode': pincode,
        'total_area_sqm': totalAreaSqm,
        'entered_area': enteredArea,
        'entered_unit': enteredUnit,
        'is_primary': isPrimary ? 1 : 0,
        'notes': notes,
        'rev': rev,
      };

  factory Farm.fromSqlite(Map<String, dynamic> map) {
    return Farm(
      id: map['id'] as String,
      name: map['name'] as String,
      village: map['village'] as String?,
      taluk: map['taluk'] as String?,
      district: map['district'] as String?,
      stateCode: map['state_code'] as String?,
      pincode: map['pincode'] as String?,
      totalAreaSqm: (map['total_area_sqm'] as num?)?.toDouble(),
      enteredArea: (map['entered_area'] as num?)?.toDouble(),
      enteredUnit: map['entered_unit'] as String? ?? 'acre',
      isPrimary: (map['is_primary'] as int? ?? 0) == 1,
      notes: map['notes'] as String?,
      rev: map['rev'] as int? ?? 1,
    );
  }

  Farm copyWith({
    String? id,
    String? name,
    String? village,
    String? taluk,
    String? district,
    String? stateCode,
    String? pincode,
    double? totalAreaSqm,
    double? enteredArea,
    String? enteredUnit,
    bool? isPrimary,
    String? notes,
    int? rev,
  }) {
    return Farm(
      id: id ?? this.id,
      name: name ?? this.name,
      village: village ?? this.village,
      taluk: taluk ?? this.taluk,
      district: district ?? this.district,
      stateCode: stateCode ?? this.stateCode,
      pincode: pincode ?? this.pincode,
      totalAreaSqm: totalAreaSqm ?? this.totalAreaSqm,
      enteredArea: enteredArea ?? this.enteredArea,
      enteredUnit: enteredUnit ?? this.enteredUnit,
      isPrimary: isPrimary ?? this.isPrimary,
      notes: notes ?? this.notes,
      rev: rev ?? this.rev,
    );
  }

  String get displayArea {
    if (enteredArea == null) return '';
    return '$enteredArea $enteredUnit';
  }
}
