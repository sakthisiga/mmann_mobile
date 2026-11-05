import 'package:flutter_test/flutter_test.dart';
import 'package:mmann_mobile/features/admin/models/admin_models.dart';

void main() {
  group('Admin Models Tests', () {
    test('AdminAuthResponse parses correctly from JSON', () {
      final json = {
        'accessToken': 'jwt-sample-token',
        'tokenType': 'Bearer',
        'expiresAt': '2026-11-06T10:00:00Z',
        'username': 'admin',
        'displayName': 'Super Administrator',
        'role': 'super_admin',
      };

      final response = AdminAuthResponse.fromJson(json);
      expect(response.accessToken, 'jwt-sample-token');
      expect(response.username, 'admin');
      expect(response.role, 'super_admin');
    });

    test('AdminDashboardStats parses metrics correctly', () {
      final json = {
        'totalOrgs': 12,
        'activeOrgs': 10,
        'suspendedOrgs': 2,
        'totalUsers': 50,
        'activeUsers': 48,
        'blockedUsers': 2,
        'totalFarms': 35,
        'totalMemberships': 55,
        'activeSessions': 8,
        'totalConsents': 50,
      };

      final stats = AdminDashboardStats.fromJson(json);
      expect(stats.totalOrgs, 12);
      expect(stats.activeOrgs, 10);
      expect(stats.totalUsers, 50);
      expect(stats.activeUsers, 48);
      expect(stats.totalFarms, 35);
      expect(stats.activeSessions, 8);
    });

    test('AdminOrgSummary parses correctly', () {
      final json = {
        'id': 'org-123',
        'name': 'Kaveri Delta Agro',
        'kind': 'fpo',
        'stateCode': 'TN',
        'district': 'Thanjavur',
        'status': 'active',
        'memberCount': 25,
        'farmCount': 14,
      };

      final org = AdminOrgSummary.fromJson(json);
      expect(org.name, 'Kaveri Delta Agro');
      expect(org.kind, 'fpo');
      expect(org.stateCode, 'TN');
      expect(org.memberCount, 25);
      expect(org.farmCount, 14);
    });
  });
}

