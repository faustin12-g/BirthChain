import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
// import 'package:provider/provider.dart'; // Remove duplicate
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../core/widgets/empty_state.dart';
import '../core/widgets/notification_bell.dart';
import '../di/injection.dart';
import '../features/auth/presentation/auth_provider.dart';
import '../features/notifications/notification_provider.dart';
import 'theme.dart';

/// Full-featured admin dashboard with stats, user management, facilities,
/// providers, records overview, and activity logs.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const _OverviewTab(),
      const _UsersTab(),
      const _FacilitiesTab(),
      const _ProvidersTab(),
      const _ActivityLogsTab(),
      _AdminProfileTab(onSwitchTab: (i) => setState(() => _currentIndex = i)),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outlined),
            selectedIcon: Icon(Icons.people),
            label: 'Users',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_hospital_outlined),
            selectedIcon: Icon(Icons.local_hospital),
            label: 'Facilities',
          ),
          NavigationDestination(
            icon: Icon(Icons.badge_outlined),
            selectedIcon: Icon(Icons.badge),
            label: 'Providers',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Logs',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────
// Tab 0: Overview / Stats Dashboard
// ──────────────────────────────────
class _OverviewTab extends StatefulWidget {
  const _OverviewTab();

  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  final _api = getIt<ApiClient>();
  Map<String, dynamic>? _stats;
  List<dynamic> _recentLogs = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    // Load notifications from backend
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().loadNotifications();
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _api.dio.get(ApiEndpoints.adminStats),
        _api.dio.get(ApiEndpoints.activityLogs),
      ]);
      _stats = results[0].data as Map<String, dynamic>;
      final logs = results[1].data as List;
      _recentLogs = logs.take(10).toList();
    } on DioException catch (e) {
      _error = e.response?.data?['message'] ?? 'Failed to load stats.';
    } catch (_) {
      _error = 'Something went wrong.';
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/icon/logo.png', height: 28),
            const SizedBox(width: 8),
            const Text('Admin Dashboard'),
          ],
        ),
        actions: const [NotificationBell(), SizedBox(width: 4)],
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(height: 12),
                    Text(_error!, style: TextStyle(color: Colors.red.shade600)),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _load,
                      icon: Icon(Icons.refresh), // Remove const
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // ── Greeting ──
                    _buildGreeting(auth, theme),
                    const SizedBox(height: 20),

                    // ── Stat cards ──
                    _buildStatGrid(),
                    const SizedBox(height: 24),

                    // ── Role breakdown ──
                    _buildRoleBreakdown(theme),
                    const SizedBox(height: 24),

                    // ── Recent Activity ──
                    _buildRecentActivity(theme),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
    );
  }

  Widget _buildGreeting(AuthProvider auth, ThemeData theme) {
    final hour = DateTime.now().hour;
    final greeting =
        hour < 12
            ? 'Good Morning'
            : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';
    final name = (auth.name ?? 'Admin').split(' ').first;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.navyBlue, Color(0xFF2A5298)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting, $name',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'System overview at a glance',
                  style: TextStyle(
                    color: Colors.white.withAlpha(180),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.admin_panel_settings,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatGrid() {
    final s = _stats!;
    final totalUsers = s['totalUsers'] ?? 0;
    final activeUsers = s['activeUsers'] ?? 0;
    final totalFacilities = s['totalFacilities'] ?? 0;
    final totalProviders = s['totalProviders'] ?? 0;
    final totalClients = s['totalClients'] ?? 0;
    final totalRecords = s['totalRecords'] ?? 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _DashStatCard(
                icon: Icons.people,
                label: 'Total Users',
                value: '$totalUsers',
                subValue: '$activeUsers active',
                color: AppTheme.navyBlue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DashStatCard(
                icon: Icons.local_hospital,
                label: 'Facilities',
                value: '$totalFacilities',
                color: AppTheme.accentOrange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _DashStatCard(
                icon: Icons.badge,
                label: 'Providers',
                value: '$totalProviders',
                color: Colors.teal,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DashStatCard(
                icon: Icons.person,
                label: 'Patients',
                value: '$totalClients',
                color: Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _DashStatCard(
          icon: Icons.description,
          label: 'Medical Records',
          value: '$totalRecords',
          color: Colors.green,
          wide: true,
        ),
      ],
    );
  }

  Widget _buildRoleBreakdown(ThemeData theme) {
    final roles = (_stats?['usersByRole'] as Map<String, dynamic>?) ?? {};
    if (roles.isEmpty) return const SizedBox.shrink();

    final roleColors = {
      'Admin': Colors.red,
      'FacilityAdmin': AppTheme.accentOrange,
      'Provider': Colors.teal,
      'Patient': AppTheme.navyBlue,
    };
    final total = roles.values.fold<int>(0, (a, b) => a + (b as int));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.pie_chart_outline,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Users by Role',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Stacked bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 12,
                child: Row(
                  children:
                      roles.entries.map((e) {
                        final pct = total > 0 ? (e.value as int) / total : 0.0;
                        return Expanded(
                          flex: (pct * 100).round().clamp(1, 100),
                          child: Container(
                            color: roleColors[e.key] ?? Colors.grey,
                          ),
                        );
                      }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children:
                  roles.entries.map((e) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: roleColors[e.key] ?? Colors.grey,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${e.key}: ${e.value}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.history, color: theme.colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Recent Activity',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_recentLogs.isEmpty)
          const EmptyState(icon: Icons.history, title: 'No activity yet')
        else
          ...(_recentLogs.map(
            (log) => Card(
              margin: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.navyBlue.withAlpha(20),
                  child: Icon(
                    _iconForAction(log['action'] ?? ''),
                    size: 16,
                    color: AppTheme.navyBlue,
                  ),
                ),
                title: Text(
                  log['action'] ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  log['userName'] ?? '',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                trailing: Text(
                  _fmtTime(log['timestamp'] ?? ''),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                ),
              ),
            ),
          )),
      ],
    );
  }

  IconData _iconForAction(String action) {
    if (action.contains('Logged in')) return Icons.login;
    if (action.contains('provider')) return Icons.badge;
    if (action.contains('client') || action.contains('patient'))
      return Icons.person_add;
    if (action.contains('record')) return Icons.description;
    if (action.contains('facility')) return Icons.local_hospital;
    return Icons.circle;
  }

  String _fmtTime(String raw) {
    try {
      final dt = DateTime.parse(raw);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return DateFormat('MMM d').format(dt);
    } catch (_) {
      return '';
    }
  }
}

class _DashStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subValue;
  final Color color;
  final bool wide;

  const _DashStatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.subValue,
    required this.color,
    this.wide = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
                Text(value, style: TextStyle(fontSize: 20, color: color)),
                if (subValue != null)
                  Text(
                    subValue!,
                    style: TextStyle(
                      fontSize: 12,
                      color: color.withOpacity(0.7),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────
// Tab 1: Users Management
// ──────────────────────────────────
class _UsersTab extends StatefulWidget {
  const _UsersTab();

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  final _api = getIt<ApiClient>();
  List<dynamic> _users = [];
  bool _loading = true;
  String? _error;
  String _searchQuery = '';
  String? _roleFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _api.dio.get(ApiEndpoints.adminUsers);
      _users = res.data as List;
    } on DioException catch (e) {
      _error = e.response?.data?['message'] ?? 'Failed to load users.';
    } catch (_) {
      _error = 'Something went wrong.';
    }
    setState(() => _loading = false);
  }

  List<dynamic> get _filteredUsers {
    var list = _users;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list =
          list.where((u) {
            final name = (u['fullName'] ?? '').toString().toLowerCase();
            final email = (u['email'] ?? '').toString().toLowerCase();
            return name.contains(q) || email.contains(q);
          }).toList();
    }
    if (_roleFilter != null) {
      list = list.where((u) => u['role'] == _roleFilter).toList();
    }
    return list;
  }

  Future<void> _toggleActive(dynamic user) async {
    final isActive = user['isActive'] == true;
    final action = isActive ? 'deactivate' : 'activate';
    final endpoint =
        isActive
            ? ApiEndpoints.adminDeactivateUser(user['id'])
            : ApiEndpoints.adminActivateUser(user['id']);

    try {
      await _api.dio.put(endpoint);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('User ${action}d successfully')));
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.response?.data?['message'] ?? 'Failed to $action user.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteUser(dynamic user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Delete User'),
            content: Text(
              'Are you sure you want to delete "${user['fullName']}"? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    try {
      await _api.dio.delete(ApiEndpoints.adminDeleteUser(user['id']));
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deleted successfully')),
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.response?.data?['message'] ?? 'Failed to delete user.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roles =
        _users.map((u) => u['role'] as String).toSet().toList()..sort();
    final filtered = _filteredUsers;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/icon/logo.png', height: 28),
            const SizedBox(width: 8),
            const Text('User Management'),
          ],
        ),
        actions: const [NotificationBell(), SizedBox(width: 4)],
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              )
              : RefreshIndicator(
                onRefresh: _load,
                child: Column(
                  children: [
                    // ── Search + filter ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search users...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          filled: true,
                          fillColor: theme.colorScheme.primary.withAlpha(10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 13),
                        onChanged:
                            (v) => setState(() => _searchQuery = v.trim()),
                      ),
                    ),
                    // Role filter chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: FilterChip(
                              label: Text(
                                'All (${_users.length})',
                                style: const TextStyle(fontSize: 12),
                              ),
                              selected: _roleFilter == null,
                              onSelected:
                                  (_) => setState(() => _roleFilter = null),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                          ...roles.map((r) {
                            final count =
                                _users.where((u) => u['role'] == r).length;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: FilterChip(
                                label: Text(
                                  '$r ($count)',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                selected: _roleFilter == r,
                                onSelected:
                                    (sel) => setState(
                                      () => _roleFilter = sel ? r : null,
                                    ),
                                visualDensity: VisualDensity.compact,
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          Text(
                            '${filtered.length} user${filtered.length == 1 ? '' : 's'}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // ── User list ──
                    Expanded(
                      child:
                          filtered.isEmpty
                              ? const EmptyState(
                                icon: Icons.people_outline,
                                title: 'No users found',
                              )
                              : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                itemCount: filtered.length,
                                itemBuilder:
                                    (_, i) => _UserCard(
                                      user: filtered[i],
                                      onToggleActive:
                                          () => _toggleActive(filtered[i]),
                                      onDelete: () => _deleteUser(filtered[i]),
                                    ),
                              ),
                    ),
                  ],
                ),
              ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final dynamic user;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;

  const _UserCard({
    required this.user,
    required this.onToggleActive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final name = user['fullName'] ?? 'Unknown';
    final email = user['email'] ?? '';
    final role = user['role'] ?? '';
    final isActive = user['isActive'] == true;
    final createdAt = user['createdAt'] ?? '';

    Color roleColor;
    switch (role) {
      case 'Admin':
        roleColor = Colors.red;
        break;
      case 'FacilityAdmin':
        roleColor = AppTheme.accentOrange;
        break;
      case 'Provider':
        roleColor = Colors.teal;
        break;
      default:
        roleColor = AppTheme.navyBlue;
    }

    String dateStr = '';
    try {
      dateStr = DateFormat('MMM d, yyyy').format(DateTime.parse(createdAt));
    } catch (_) {}

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: roleColor.withAlpha(25),
              child: Text(
                name[0].toUpperCase(),
                style: TextStyle(
                  color: roleColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: roleColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          role,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: roleColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  if (dateStr.isNotEmpty)
                    Text(
                      'Joined $dateStr',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade400,
                      ),
                    ),
                ],
              ),
            ),
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isActive
                            ? Colors.green.withAlpha(20)
                            : Colors.red.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color:
                          isActive
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  padding: EdgeInsets.zero,
                  onSelected: (value) {
                    if (value == 'toggle') {
                      onToggleActive();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder:
                      (_) => [
                        PopupMenuItem(
                          value: 'toggle',
                          child: Row(
                            children: [
                              Icon(
                                isActive
                                    ? Icons.block
                                    : Icons.check_circle_outline,
                                size: 18,
                                color:
                                    isActive
                                        ? Colors.red.shade400
                                        : Colors.green,
                              ),
                              const SizedBox(width: 8),
                              Text(isActive ? 'Deactivate' : 'Activate'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: Colors.red.shade400,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: TextStyle(color: Colors.red.shade400),
                              ),
                            ],
                          ),
                        ),
                      ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────
// Tab 2: Facilities Management
// ──────────────────────────────────
class _FacilitiesTab extends StatefulWidget {
  const _FacilitiesTab();

  @override
  State<_FacilitiesTab> createState() => _FacilitiesTabState();
}

class _FacilitiesTabState extends State<_FacilitiesTab> {
  final _api = getIt<ApiClient>();
  List<dynamic> _facilities = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _api.dio.get(ApiEndpoints.adminFacilities);
      _facilities = res.data as List;
    } on DioException catch (e) {
      _error = e.response?.data?['message'] ?? 'Failed to load facilities.';
    } catch (_) {
      _error = 'Something went wrong.';
    }
    setState(() => _loading = false);
  }

  Future<void> _toggleFacilityActive(dynamic facility) async {
    final isActive = facility['isActive'] == true;
    final action = isActive ? 'deactivate' : 'activate';
    final endpoint =
        isActive
            ? ApiEndpoints.adminDeactivateFacility(facility['id'])
            : ApiEndpoints.adminActivateFacility(facility['id']);

    try {
      await _api.dio.put(endpoint);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Facility ${action}d successfully')),
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.response?.data?['message'] ?? 'Failed to $action facility.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteFacility(dynamic facility) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Delete Facility'),
            content: Text(
              'Are you sure you want to delete "${facility['name']}"? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    try {
      await _api.dio.delete(ApiEndpoints.adminDeleteFacility(facility['id']));
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Facility deleted successfully')),
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.response?.data?['message'] ?? 'Failed to delete facility.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showCreateFacilityDialog() async {
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final created = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Create Facility'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Facility Name *',
                      ),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: addressCtrl,
                      decoration: const InputDecoration(labelText: 'Address'),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: phoneCtrl,
                      decoration: const InputDecoration(labelText: 'Phone'),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await _api.dio.post(
                      ApiEndpoints.facilities,
                      data: {
                        'name': nameCtrl.text.trim(),
                        'address': addressCtrl.text.trim(),
                        'phone': phoneCtrl.text.trim(),
                        'email': emailCtrl.text.trim(),
                      },
                    );
                    navigator.pop(true);
                  } on DioException catch (e) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          e.response?.data?['message'] ?? 'Failed to create.',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Create'),
              ),
            ],
          ),
    );
    if (created == true) _load();
  }

  Future<void> _showCreateFacilityAdminDialog(dynamic facility) async {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final created = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text('Add Admin for ${facility['name']}'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Full Name *',
                      ),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(labelText: 'Email *'),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: passCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Password *',
                      ),
                      obscureText: true,
                      validator:
                          (v) =>
                              v != null && v.length >= 6 ? null : 'Min 6 chars',
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await _api.dio.post(
                      ApiEndpoints.facilityAdmins,
                      data: {
                        'fullName': nameCtrl.text.trim(),
                        'email': emailCtrl.text.trim(),
                        'password': passCtrl.text,
                        'facilityId': facility['id'],
                      },
                    );
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Facility admin created successfully.'),
                      ),
                    );
                    navigator.pop(true);
                  } on DioException catch (e) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          e.response?.data?['message'] ?? 'Failed to create.',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Create'),
              ),
            ],
          ),
    );
    if (created == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/icon/logo.png', height: 28),
            const SizedBox(width: 8),
            const Text('Facilities'),
          ],
        ),
        actions: const [NotificationBell(), SizedBox(width: 4)],
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              )
              : Column(
                children: [
                  Expanded(
                    child:
                        _facilities.isEmpty
                            ? const EmptyState(
                              icon: Icons.local_hospital_outlined,
                              title: 'No facilities yet',
                            )
                            : RefreshIndicator(
                              onRefresh: _load,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(12),
                                itemCount: _facilities.length,
                                itemBuilder: (_, i) {
                                  final f = _facilities[i];
                                  final isActive = f['isActive'] == true;
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor:
                                                isActive
                                                    ? Colors.orange.shade100
                                                    : Colors.grey.shade200,
                                            child: Icon(
                                              Icons.local_hospital,
                                              color:
                                                  isActive
                                                      ? Colors.orange.shade800
                                                      : Colors.grey.shade500,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Flexible(
                                                      child: Text(
                                                        f['name'] ?? '',
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 6,
                                                            vertical: 2,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            isActive
                                                                ? Colors.green
                                                                    .withAlpha(
                                                                      20,
                                                                    )
                                                                : Colors.red
                                                                    .withAlpha(
                                                                      20,
                                                                    ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              6,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        isActive
                                                            ? 'Active'
                                                            : 'Inactive',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color:
                                                              isActive
                                                                  ? Colors
                                                                      .green
                                                                      .shade700
                                                                  : Colors
                                                                      .red
                                                                      .shade700,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                if ((f['address'] ?? '')
                                                    .toString()
                                                    .isNotEmpty)
                                                  Text(
                                                    f['address'],
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                if ((f['email'] ?? '')
                                                    .toString()
                                                    .isNotEmpty)
                                                  Text(
                                                    f['email'],
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color:
                                                          Colors.grey.shade500,
                                                    ),
                                                  ),
                                                Text(
                                                  '${f['providerCount'] ?? 0} providers • ${f['adminCount'] ?? 0} admins',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey.shade400,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          PopupMenuButton<String>(
                                            icon: const Icon(
                                              Icons.more_vert,
                                              size: 20,
                                            ),
                                            onSelected: (value) {
                                              if (value == 'admin') {
                                                _showCreateFacilityAdminDialog(
                                                  f,
                                                );
                                              } else if (value == 'toggle') {
                                                _toggleFacilityActive(f);
                                              } else if (value == 'delete') {
                                                _deleteFacility(f);
                                              }
                                            },
                                            itemBuilder:
                                                (_) => [
                                                  const PopupMenuItem(
                                                    value: 'admin',
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Icons
                                                              .person_add_alt_1,
                                                          size: 18,
                                                        ),
                                                        SizedBox(width: 8),
                                                        Text('Add Admin'),
                                                      ],
                                                    ),
                                                  ),
                                                  PopupMenuItem(
                                                    value: 'toggle',
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          isActive
                                                              ? Icons.block
                                                              : Icons
                                                                  .check_circle_outline,
                                                          size: 18,
                                                          color:
                                                              isActive
                                                                  ? Colors
                                                                      .red
                                                                      .shade400
                                                                  : Colors
                                                                      .green,
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        Text(
                                                          isActive
                                                              ? 'Deactivate'
                                                              : 'Activate',
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  PopupMenuItem(
                                                    value: 'delete',
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Icons.delete_outline,
                                                          size: 18,
                                                          color:
                                                              Colors
                                                                  .red
                                                                  .shade400,
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        Text(
                                                          'Delete',
                                                          style: TextStyle(
                                                            color:
                                                                Colors
                                                                    .red
                                                                    .shade400,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _showCreateFacilityDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Facility'),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}

// ──────────────────────────────────
// Tab 3: Providers Management
// ──────────────────────────────────
class _ProvidersTab extends StatefulWidget {
  const _ProvidersTab();

  @override
  State<_ProvidersTab> createState() => _ProvidersTabState();
}

class _ProvidersTabState extends State<_ProvidersTab> {
  final _api = getIt<ApiClient>();
  List<dynamic> _providers = [];
  bool _loading = true;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _api.dio.get(ApiEndpoints.adminProviders);
      _providers = res.data as List;
    } on DioException catch (e) {
      _error = e.response?.data?['message'] ?? 'Failed to load providers.';
    } catch (_) {
      _error = 'Something went wrong.';
    }
    setState(() => _loading = false);
  }

  List<dynamic> get _filteredProviders {
    if (_searchQuery.isEmpty) return _providers;
    final q = _searchQuery.toLowerCase();
    return _providers.where((p) {
      final name = (p['fullName'] ?? '').toString().toLowerCase();
      final email = (p['email'] ?? '').toString().toLowerCase();
      final facility = (p['facilityName'] ?? '').toString().toLowerCase();
      return name.contains(q) || email.contains(q) || facility.contains(q);
    }).toList();
  }

  Future<void> _toggleActive(dynamic provider) async {
    final isActive = provider['isActive'] == true;
    final action = isActive ? 'deactivate' : 'activate';
    final endpoint =
        isActive
            ? ApiEndpoints.adminDeactivateProvider(provider['id'])
            : ApiEndpoints.adminActivateProvider(provider['id']);

    try {
      await _api.dio.put(endpoint);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Provider ${action}d successfully')),
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.response?.data?['message'] ?? 'Failed to $action provider.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteProvider(dynamic provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Delete Provider'),
            content: Text(
              'Are you sure you want to delete "${provider['fullName']}"? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    try {
      await _api.dio.delete(ApiEndpoints.adminDeleteProvider(provider['id']));
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Provider deleted successfully')),
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.response?.data?['message'] ?? 'Failed to delete provider.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filteredProviders;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/icon/logo.png', height: 28),
            const SizedBox(width: 8),
            const Text('Providers'),
          ],
        ),
        actions: const [NotificationBell(), SizedBox(width: 4)],
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              )
              : RefreshIndicator(
                onRefresh: _load,
                child: Column(
                  children: [
                    // Search bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search providers...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          filled: true,
                          fillColor: theme.colorScheme.primary.withAlpha(10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 13),
                        onChanged:
                            (v) => setState(() => _searchQuery = v.trim()),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          Text(
                            '${filtered.length} provider${filtered.length == 1 ? '' : 's'}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Provider list
                    Expanded(
                      child:
                          filtered.isEmpty
                              ? const EmptyState(
                                icon: Icons.badge_outlined,
                                title: 'No providers found',
                              )
                              : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                itemCount: filtered.length,
                                itemBuilder: (_, i) {
                                  final p = filtered[i];
                                  final isActive = p['isActive'] == true;
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 22,
                                            backgroundColor: Colors.teal
                                                .withAlpha(25),
                                            child: Text(
                                              (p['fullName'] ?? 'P')[0]
                                                  .toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.teal,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Flexible(
                                                      child: Text(
                                                        p['fullName'] ??
                                                            'Unknown',
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 14,
                                                        ),
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 6,
                                                            vertical: 2,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            isActive
                                                                ? Colors.green
                                                                    .withAlpha(
                                                                      20,
                                                                    )
                                                                : Colors.red
                                                                    .withAlpha(
                                                                      20,
                                                                    ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              6,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        isActive
                                                            ? 'Active'
                                                            : 'Inactive',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color:
                                                              isActive
                                                                  ? Colors
                                                                      .green
                                                                      .shade700
                                                                  : Colors
                                                                      .red
                                                                      .shade700,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  p['email'] ?? '',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.local_hospital,
                                                      size: 12,
                                                      color:
                                                          Colors.grey.shade400,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Flexible(
                                                      child: Text(
                                                        p['facilityName'] ??
                                                            'No facility',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color:
                                                              Colors
                                                                  .grey
                                                                  .shade400,
                                                        ),
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          PopupMenuButton<String>(
                                            icon: const Icon(
                                              Icons.more_vert,
                                              size: 20,
                                            ),
                                            onSelected: (value) {
                                              if (value == 'toggle') {
                                                _toggleActive(p);
                                              } else if (value == 'delete') {
                                                _deleteProvider(p);
                                              }
                                            },
                                            itemBuilder:
                                                (_) => [
                                                  PopupMenuItem(
                                                    value: 'toggle',
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          isActive
                                                              ? Icons.block
                                                              : Icons
                                                                  .check_circle_outline,
                                                          size: 18,
                                                          color:
                                                              isActive
                                                                  ? Colors
                                                                      .red
                                                                      .shade400
                                                                  : Colors
                                                                      .green,
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        Text(
                                                          isActive
                                                              ? 'Deactivate'
                                                              : 'Activate',
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  PopupMenuItem(
                                                    value: 'delete',
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Icons.delete_outline,
                                                          size: 18,
                                                          color:
                                                              Colors
                                                                  .red
                                                                  .shade400,
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        Text(
                                                          'Delete',
                                                          style: TextStyle(
                                                            color:
                                                                Colors
                                                                    .red
                                                                    .shade400,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                    ),
                  ],
                ),
              ),
    );
  }
}

// ──────────────────────────────────
// Tab 4: Activity Logs
// ──────────────────────────────────
class _ActivityLogsTab extends StatefulWidget {
  const _ActivityLogsTab();

  @override
  State<_ActivityLogsTab> createState() => _ActivityLogsTabState();
}

class _ActivityLogsTabState extends State<_ActivityLogsTab> {
  final _api = getIt<ApiClient>();
  List<dynamic> _logs = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _api.dio.get(ApiEndpoints.activityLogs);
      _logs = res.data as List;
    } on DioException catch (e) {
      _error = e.response?.data?['message'] ?? 'Failed to load logs.';
    } catch (_) {
      _error = 'Something went wrong.';
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/icon/logo.png', height: 28),
            const SizedBox(width: 8),
            const Text('Activity Logs'),
          ],
        ),
        actions: const [NotificationBell(), SizedBox(width: 4)],
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              )
              : _logs.isEmpty
              ? const EmptyState(icon: Icons.history, title: 'No activity yet')
              : RefreshIndicator(
                onRefresh: _load,
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _logs.length,
                  itemBuilder: (_, i) {
                    final log = _logs[i];
                    String dateStr = '';
                    try {
                      final dt = DateTime.parse(log['timestamp'] ?? '');
                      dateStr = DateFormat('MMM d, h:mm a').format(dt);
                    } catch (_) {}

                    return Card(
                      margin: const EdgeInsets.only(bottom: 6),
                      child: ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: AppTheme.navyBlue.withAlpha(20),
                          child: Icon(
                            _iconForAction(log['action'] ?? ''),
                            size: 16,
                            color: AppTheme.navyBlue,
                          ),
                        ),
                        title: Text(
                          log['action'] ?? '',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          log['userName'] ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        trailing: Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
    );
  }

  IconData _iconForAction(String action) {
    if (action.contains('Logged in')) return Icons.login;
    if (action.contains('provider')) return Icons.badge;
    if (action.contains('client') || action.contains('patient'))
      return Icons.person_add;
    if (action.contains('record')) return Icons.description;
    if (action.contains('facility')) return Icons.local_hospital;
    return Icons.circle;
  }
}

// ──────────────────────────────────
// Tab 5: Admin Profile
// ──────────────────────────────────
class _AdminProfileTab extends StatefulWidget {
  const _AdminProfileTab({required this.onSwitchTab});
  final ValueChanged<int> onSwitchTab;

  @override
  State<_AdminProfileTab> createState() => _AdminProfileTabState();
}

class _AdminProfileTabState extends State<_AdminProfileTab> {
  final _api = getIt<ApiClient>();
  Map<String, dynamic>? _profile;
  bool _loading = true;
  bool _updatingImage = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  /// Helper to get appropriate ImageProvider for data URLs or network URLs
  ImageProvider _getImageProvider(String url) {
    if (url.startsWith('data:')) {
      // Data URL - extract base64 and decode
      final data = url.split(',').last;
      return MemoryImage(base64Decode(data));
    }
    return NetworkImage(url);
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final res = await _api.dio.get(ApiEndpoints.profile);
      _profile = res.data as Map<String, dynamic>;
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
    );
    if (image == null) return;

    setState(() => _updatingImage = true);
    try {
      // Read and convert image to base64
      final bytes = await File(image.path).readAsBytes();
      final base64Image = base64Encode(bytes);
      final extension = image.path.split('.').last.toLowerCase();
      final contentType = extension == 'png' ? 'image/png' : 'image/jpeg';

      await _api.dio.put(
        ApiEndpoints.profileImage,
        data: {'base64Image': base64Image, 'contentType': contentType},
      );
      _loadProfile();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile image updated')));
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.response?.data?['message'] ?? 'Failed to update image',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    setState(() => _updatingImage = false);
  }

  Future<void> _removeImage() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Remove Profile Image'),
            content: const Text(
              'Are you sure you want to remove your profile image?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Remove'),
              ),
            ],
          ),
    );
    if (confirmed != true) return;

    try {
      await _api.dio.delete(ApiEndpoints.profileImage);
      _loadProfile();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile image removed')));
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.response?.data?['message'] ?? 'Failed to remove image',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showEditDialog() async {
    final nameCtrl = TextEditingController(text: _profile?['fullName'] ?? '');
    final phoneCtrl = TextEditingController(text: _profile?['phone'] ?? '');
    final formKey = GlobalKey<FormState>();

    final updated = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Edit Profile'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Full Name *'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneCtrl,
                    decoration: const InputDecoration(labelText: 'Phone'),
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await _api.dio.put(
                      ApiEndpoints.profile,
                      data: {
                        'fullName': nameCtrl.text.trim(),
                        'phone': phoneCtrl.text.trim(),
                      },
                    );
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Profile updated')),
                    );
                    navigator.pop(true);
                  } on DioException catch (e) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          e.response?.data?['message'] ?? 'Failed to update',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
    if (updated == true) _loadProfile();
  }

  Future<void> _showChangePasswordDialog() async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Change Password'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: currentCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Current Password *',
                    ),
                    obscureText: true,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: newCtrl,
                    decoration: const InputDecoration(
                      labelText: 'New Password *',
                    ),
                    obscureText: true,
                    validator:
                        (v) =>
                            v != null && v.length >= 6 ? null : 'Min 6 chars',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: confirmCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Confirm Password *',
                    ),
                    obscureText: true,
                    validator:
                        (v) =>
                            v == newCtrl.text ? null : 'Passwords don\'t match',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await _api.dio.put(
                      ApiEndpoints.profilePassword,
                      data: {
                        'currentPassword': currentCtrl.text,
                        'newPassword': newCtrl.text,
                      },
                    );
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Password changed successfully'),
                      ),
                    );
                    navigator.pop();
                  } on DioException catch (e) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          e.response?.data?['message'] ??
                              'Failed to change password',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Change'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final profileImageUrl = _profile?['profileImageUrl'] as String?;
    final hasImage = profileImageUrl != null && profileImageUrl.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/icon/logo.png', height: 28),
            const SizedBox(width: 8),
            const Text('Profile'),
          ],
        ),
        actions: const [NotificationBell(), SizedBox(width: 4)],
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadProfile,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Profile card with image
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                GestureDetector(
                                  onTap:
                                      _updatingImage
                                          ? null
                                          : _pickAndUploadImage,
                                  child: CircleAvatar(
                                    radius: 50,
                                    backgroundColor: Colors.red.shade100,
                                    backgroundImage:
                                        hasImage
                                            ? _getImageProvider(
                                              profileImageUrl!,
                                            )
                                            : null,
                                    child:
                                        _updatingImage
                                            ? const CircularProgressIndicator()
                                            : hasImage
                                            ? null
                                            : Text(
                                              (auth.name ?? 'A')[0]
                                                  .toUpperCase(),
                                              style: TextStyle(
                                                color: Colors.red.shade700,
                                                fontSize: 36,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap:
                                        _updatingImage
                                            ? null
                                            : _pickAndUploadImage,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppTheme.navyBlue,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (hasImage)
                              TextButton.icon(
                                onPressed: _removeImage,
                                icon: Icon(
                                  Icons.delete_outline,
                                  size: 16,
                                  color: Colors.red.shade400,
                                ),
                                label: Text(
                                  'Remove Image',
                                  style: TextStyle(
                                    color: Colors.red.shade400,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 12),
                            Text(
                              _profile?['fullName'] ?? auth.name ?? 'Admin',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _profile?['email'] ?? '',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            if ((_profile?['phone'] ?? '')
                                .toString()
                                .isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  _profile!['phone'],
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'System Administrator',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red.shade800,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _showEditDialog,
                                  icon: const Icon(Icons.edit, size: 18),
                                  label: const Text('Edit Profile'),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  onPressed: _showChangePasswordDialog,
                                  icon: const Icon(
                                    Icons.lock_outline,
                                    size: 18,
                                  ),
                                  label: const Text('Change Password'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Quick links
                    Text(
                      'Quick Actions',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.people_outlined),
                            title: const Text('Manage Users'),
                            subtitle: const Text(
                              'View, activate, deactivate users',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => widget.onSwitchTab(1),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.local_hospital_outlined),
                            title: const Text('Manage Facilities'),
                            subtitle: const Text(
                              'Create facilities and assign admins',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => widget.onSwitchTab(2),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.badge_outlined),
                            title: const Text('Manage Providers'),
                            subtitle: const Text(
                              'View and manage healthcare providers',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => widget.onSwitchTab(3),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.history),
                            title: const Text('Activity Logs'),
                            subtitle: const Text('View all system activity'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => widget.onSwitchTab(4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Account section
                    Text(
                      'Account',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: ListTile(
                        leading: Icon(Icons.logout, color: Colors.red.shade400),
                        title: Text(
                          'Sign Out',
                          style: TextStyle(color: Colors.red.shade400),
                        ),
                        onTap: () async {
                          final authProv = context.read<AuthProvider>();
                          final navigator = Navigator.of(context);
                          await authProv.logout();
                          if (context.mounted) {
                            navigator.pushReplacementNamed('/login');
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
