import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/admin_models.dart';
import '../services/admin_api_service.dart';
import 'admin_login_screen.dart';

class AdminPortalScreen extends ConsumerStatefulWidget {
  const AdminPortalScreen({super.key});

  @override
  ConsumerState<AdminPortalScreen> createState() => _AdminPortalScreenState();
}

class _AdminPortalScreenState extends ConsumerState<AdminPortalScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  bool _isLoading = true;
  AdminDashboardStats? _stats;
  List<AdminOrgSummary> _orgs = [];
  List<AdminUserSummary> _users = [];
  List<AdminFarmSummary> _farms = [];
  List<AdminSession> _sessions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    try {
      final adminApi = ref.read(adminApiServiceProvider);
      final statsFuture = adminApi.getStats();
      final orgsFuture = adminApi.getOrganizations();
      final usersFuture = adminApi.getUsers();
      final farmsFuture = adminApi.getFarms();
      final sessionsFuture = adminApi.getSessions();

      final results = await Future.wait([
        statsFuture,
        orgsFuture,
        usersFuture,
        farmsFuture,
        sessionsFuture,
      ]);

      if (!mounted) return;
      setState(() {
        _stats = results[0] as AdminDashboardStats;
        _orgs = results[1] as List<AdminOrgSummary>;
        _users = results[2] as List<AdminUserSummary>;
        _farms = results[3] as List<AdminFarmSummary>;
        _sessions = results[4] as List<AdminSession>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load admin data: $e')),
      );
    }
  }

  Future<void> _toggleOrgStatus(String id, String currentStatus) async {
    final nextStatus = currentStatus == 'active' ? 'suspended' : 'active';
    try {
      final adminApi = ref.read(adminApiServiceProvider);
      await adminApi.updateOrgStatus(id, nextStatus);
      _loadAll();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating org status: $e')),
      );
    }
  }

  Future<void> _toggleUserStatus(String id, String currentStatus) async {
    final nextStatus = currentStatus == 'active' ? 'blocked' : 'active';
    try {
      final adminApi = ref.read(adminApiServiceProvider);
      await adminApi.updateUserStatus(id, nextStatus);
      _loadAll();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating user status: $e')),
      );
    }
  }

  Future<void> _revokeSession(String id) async {
    try {
      final adminApi = ref.read(adminApiServiceProvider);
      await adminApi.revokeSession(id, 'Revoked by super admin from mobile portal');
      _loadAll();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error revoking session: $e')),
      );
    }
  }

  Future<void> _logout() async {
    final adminApi = ref.read(adminApiServiceProvider);
    await adminApi.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF151D2A),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
              ),
              child: const Text(
                'SUPER ADMIN',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'M1 Console',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _loadAll,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: _logout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF10B981),
          labelColor: const Color(0xFF10B981),
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Orgs'),
            Tab(text: 'Farmers'),
            Tab(text: 'Farms & Auth'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF10B981)),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildOrgsTab(),
                _buildUsersTab(),
                _buildFarmsAndSessionsTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    if (_stats == null) {
      return const Center(child: Text('No stats available', style: TextStyle(color: Colors.white60)));
    }
    final s = _stats!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Identity & Access Metrics',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildStatCard('Organizations', '${s.totalOrgs}', '${s.activeOrgs} active', Icons.business, const Color(0xFF6366F1)),
            _buildStatCard('Farmers', '${s.totalUsers}', '${s.activeUsers} active', Icons.people, const Color(0xFF10B981)),
            _buildStatCard('Physical Farms', '${s.totalFarms}', 'Multi-farm model', Icons.agriculture, const Color(0xFF00E5A3)),
            _buildStatCard('Live Sessions', '${s.activeSessions}', '${s.totalConsents} consents', Icons.devices, const Color(0xFFF59E0B)),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF151D2A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF222D42)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.security, color: Color(0xFF10B981), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'PostgreSQL Native RLS Bypass Status',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Cross-tenant isolation policy active. Platform admin privileges verified with GUC app.is_admin=true.',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String count, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF151D2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF222D42)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w600)),
              Icon(icon, color: color, size: 18),
            ],
          ),
          Text(count, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          Text(subtitle, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildOrgsTab() {
    if (_orgs.isEmpty) {
      return const Center(child: Text('No organizations found', style: TextStyle(color: Colors.white60)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _orgs.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final org = _orgs[index];
        final isActive = org.status == 'active';
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF151D2A),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF222D42)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(org.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(
                      '${org.kind.toUpperCase()} • ${org.district ?? '—'}, ${org.stateCode}',
                      style: const TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${org.memberCount} members • ${org.farmCount} farms',
                      style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      org.status.toUpperCase(),
                      style: TextStyle(
                        color: isActive ? Colors.greenAccent : Colors.orangeAccent,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: () => _toggleOrgStatus(org.id, org.status),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      minimumSize: Size.zero,
                    ),
                    child: Text(
                      isActive ? 'Suspend' : 'Activate',
                      style: TextStyle(
                        color: isActive ? Colors.orangeAccent : Colors.greenAccent,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUsersTab() {
    if (_users.isEmpty) {
      return const Center(child: Text('No users found', style: TextStyle(color: Colors.white60)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _users.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final user = _users[index];
        final isActive = user.status == 'active';
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF151D2A),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF222D42)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.displayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(user.mobile, style: const TextStyle(color: Color(0xFF00E5A3), fontSize: 12, fontFamily: 'monospace')),
                    const SizedBox(height: 4),
                    Text(
                      '${user.preferredLanguage} • ${user.stateCode ?? '—'} • ${user.orgCount} orgs',
                      style: const TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      user.status.toUpperCase(),
                      style: TextStyle(
                        color: isActive ? Colors.greenAccent : Colors.redAccent,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: () => _toggleUserStatus(user.id, user.status),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      minimumSize: Size.zero,
                    ),
                    child: Text(
                      isActive ? 'Block' : 'Unblock',
                      style: TextStyle(
                        color: isActive ? Colors.redAccent : Colors.greenAccent,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFarmsAndSessionsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Cross-Tenant Physical Farms',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 8),
        ..._farms.map((f) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF151D2A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF222D42)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(f.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text('${f.orgName ?? 'Org'} • ${f.village ?? '—'}, ${f.district ?? '—'}', style: const TextStyle(color: Colors.white60, fontSize: 11)),
                  ],
                ),
              ),
              Text(
                '${f.enteredArea ?? 0} ${f.enteredUnit ?? "acre"}',
                style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
        )),

        const SizedBox(height: 20),
        const Text(
          'Active Login Sessions (auth_session)',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 8),
        ..._sessions.map((s) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF151D2A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF222D42)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.userDisplayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(s.userMobile, style: const TextStyle(color: Colors.white60, fontSize: 11, fontFamily: 'monospace')),
                    Text('IP: ${s.ip ?? "—"}', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                  ],
                ),
              ),
              if (s.active)
                TextButton(
                  onPressed: () => _revokeSession(s.id),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.red.withValues(alpha: 0.15),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                  ),
                  child: const Text('Kill Session', style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                )
              else
                const Text('Inactive', style: TextStyle(color: Colors.white38, fontSize: 10)),
            ],
          ),
        )),
      ],
    );
  }
}
