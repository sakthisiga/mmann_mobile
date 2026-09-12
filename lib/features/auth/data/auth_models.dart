class UserProfile {
  final String id;
  final String mobile;
  final String? displayName;
  final String? stateCode;
  final String? language;
  final int? age;

  UserProfile({
    required this.id,
    required this.mobile,
    this.displayName,
    this.stateCode,
    this.language,
    this.age,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? '',
      mobile: json['mobile'] as String? ?? '',
      displayName: json['displayName'] as String?,
      stateCode: json['stateCode'] as String?,
      language: (json['preferredLanguage'] ?? json['language']) as String?,
      age: (json['age'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'mobile': mobile,
        'displayName': displayName,
        'stateCode': stateCode,
        'language': language,
        'age': age,
      };
}

class OrgSummary {
  final String id;
  final String name;
  final String category;
  final String stateCode;
  final String? district;
  final String? village;
  final String? taluk;
  final String role;

  OrgSummary({
    required this.id,
    required this.name,
    required this.category,
    required this.stateCode,
    this.district,
    this.village,
    this.taluk,
    required this.role,
  });

  factory OrgSummary.fromJson(Map<String, dynamic> json) {
    return OrgSummary(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: (json['kind'] ?? json['category']) as String? ?? 'personal_farm',
      stateCode: json['stateCode'] as String? ?? 'TN',
      district: json['district'] as String?,
      village: json['village'] as String?,
      taluk: json['taluk'] as String?,
      role: json['role'] as String? ?? 'owner',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'stateCode': stateCode,
        'district': district,
        'village': village,
        'taluk': taluk,
        'role': role,
      };
}

class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;
  final UserProfile? user;
  final OrgSummary? org;
  final bool newUser;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    this.user,
    this.org,
    required this.newUser,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      tokenType: json['tokenType'] as String? ?? 'Bearer',
      expiresIn: (json['expiresIn'] as num?)?.toInt() ?? 900,
      user: json['user'] != null
          ? UserProfile.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      org: json['org'] != null
          ? OrgSummary.fromJson(json['org'] as Map<String, dynamic>)
          : null,
      newUser: json['newUser'] as bool? ?? false,
    );
  }
}
