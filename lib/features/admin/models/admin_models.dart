class AdminAuthResponse {
  final String accessToken;
  final String tokenType;
  final String expiresAt;
  final String username;
  final String displayName;
  final String role;

  AdminAuthResponse({
    required this.accessToken,
    required this.tokenType,
    required this.expiresAt,
    required this.username,
    required this.displayName,
    required this.role,
  });

  factory AdminAuthResponse.fromJson(Map<String, dynamic> json) {
    return AdminAuthResponse(
      accessToken: json['accessToken'] as String,
      tokenType: json['tokenType'] as String,
      expiresAt: json['expiresAt'] as String,
      username: json['username'] as String,
      displayName: json['displayName'] as String,
      role: json['role'] as String,
    );
  }
}

class AdminDashboardStats {
  final int totalOrgs;
  final int activeOrgs;
  final int suspendedOrgs;
  final int totalUsers;
  final int activeUsers;
  final int blockedUsers;
  final int totalFarms;
  final int totalMemberships;
  final int activeSessions;
  final int totalConsents;

  AdminDashboardStats({
    required this.totalOrgs,
    required this.activeOrgs,
    required this.suspendedOrgs,
    required this.totalUsers,
    required this.activeUsers,
    required this.blockedUsers,
    required this.totalFarms,
    required this.totalMemberships,
    required this.activeSessions,
    required this.totalConsents,
  });

  factory AdminDashboardStats.fromJson(Map<String, dynamic> json) {
    return AdminDashboardStats(
      totalOrgs: (json['totalOrgs'] as num).toInt(),
      activeOrgs: (json['activeOrgs'] as num).toInt(),
      suspendedOrgs: (json['suspendedOrgs'] as num).toInt(),
      totalUsers: (json['totalUsers'] as num).toInt(),
      activeUsers: (json['activeUsers'] as num).toInt(),
      blockedUsers: (json['blockedUsers'] as num).toInt(),
      totalFarms: (json['totalFarms'] as num).toInt(),
      totalMemberships: (json['totalMemberships'] as num).toInt(),
      activeSessions: (json['activeSessions'] as num).toInt(),
      totalConsents: (json['totalConsents'] as num).toInt(),
    );
  }
}

class AdminOrgSummary {
  final String id;
  final String name;
  final String kind;
  final String stateCode;
  final String? district;
  final String status;
  final int memberCount;
  final int farmCount;

  AdminOrgSummary({
    required this.id,
    required this.name,
    required this.kind,
    required this.stateCode,
    this.district,
    required this.status,
    required this.memberCount,
    required this.farmCount,
  });

  factory AdminOrgSummary.fromJson(Map<String, dynamic> json) {
    return AdminOrgSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      kind: json['kind'] as String,
      stateCode: json['stateCode'] as String,
      district: json['district'] as String?,
      status: json['status'] as String,
      memberCount: (json['memberCount'] as num).toInt(),
      farmCount: (json['farmCount'] as num).toInt(),
    );
  }
}

class AdminUserSummary {
  final String id;
  final String mobile;
  final String displayName;
  final String preferredLanguage;
  final String? stateCode;
  final String status;
  final int orgCount;

  AdminUserSummary({
    required this.id,
    required this.mobile,
    required this.displayName,
    required this.preferredLanguage,
    this.stateCode,
    required this.status,
    required this.orgCount,
  });

  factory AdminUserSummary.fromJson(Map<String, dynamic> json) {
    return AdminUserSummary(
      id: json['id'] as String,
      mobile: json['mobile'] as String,
      displayName: json['displayName'] as String,
      preferredLanguage: json['preferredLanguage'] as String,
      stateCode: json['stateCode'] as String?,
      status: json['status'] as String,
      orgCount: (json['orgCount'] as num).toInt(),
    );
  }
}

class AdminFarmSummary {
  final String id;
  final String orgId;
  final String? orgName;
  final String name;
  final String? village;
  final String? district;
  final String stateCode;
  final double? enteredArea;
  final String? enteredUnit;
  final bool isPrimary;

  AdminFarmSummary({
    required this.id,
    required this.orgId,
    this.orgName,
    required this.name,
    this.village,
    this.district,
    required this.stateCode,
    this.enteredArea,
    this.enteredUnit,
    required this.isPrimary,
  });

  factory AdminFarmSummary.fromJson(Map<String, dynamic> json) {
    return AdminFarmSummary(
      id: json['id'] as String,
      orgId: json['orgId'] as String,
      orgName: json['orgName'] as String?,
      name: json['name'] as String,
      village: json['village'] as String?,
      district: json['district'] as String?,
      stateCode: json['stateCode'] as String,
      enteredArea: (json['enteredArea'] as num?)?.toDouble(),
      enteredUnit: json['enteredUnit'] as String?,
      isPrimary: json['isPrimary'] as bool? ?? false,
    );
  }
}

class AdminSession {
  final String id;
  final String userDisplayName;
  final String userMobile;
  final String? orgName;
  final String? deviceId;
  final String? ip;
  final String issuedAt;
  final String expiresAt;
  final bool active;

  AdminSession({
    required this.id,
    required this.userDisplayName,
    required this.userMobile,
    this.orgName,
    this.deviceId,
    this.ip,
    required this.issuedAt,
    required this.expiresAt,
    required this.active,
  });

  factory AdminSession.fromJson(Map<String, dynamic> json) {
    return AdminSession(
      id: json['id'] as String,
      userDisplayName: json['userDisplayName'] as String? ?? 'Farmer',
      userMobile: json['userMobile'] as String? ?? '',
      orgName: json['orgName'] as String?,
      deviceId: json['deviceId'] as String?,
      ip: json['ip'] as String?,
      issuedAt: json['issuedAt'] as String,
      expiresAt: json['expiresAt'] as String,
      active: json['active'] as bool? ?? false,
    );
  }
}

