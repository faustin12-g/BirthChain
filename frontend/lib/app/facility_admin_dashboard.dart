import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../core/widgets/empty_state.dart';
import '../core/widgets/notification_bell.dart';
import '../di/injection.dart';
import '../features/auth/presentation/auth_provider.dart';
import 'profile_screen.dart';

class FacilityAdminDashboard extends StatefulWidget {
  const FacilityAdminDashboard({super.key});

  @override
  State<FacilityAdminDashboard> createState() => _FacilityAdminDashboardState();
}

class _FacilityAdminDashboardState extends State<FacilityAdminDashboard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = const <Widget>[_FacilityProvidersTab(), ProfileScreen()];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.badge_outlined),
            selectedIcon: Icon(Icons.badge),
            label: 'Providers',
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

// ── Providers management for FacilityAdmin ──

class _FacilityProvidersTab extends StatefulWidget {
  const _FacilityProvidersTab();

  @override
  State<_FacilityProvidersTab> createState() => _FacilityProvidersTabState();
}

class _FacilityProvidersTabState extends State<_FacilityProvidersTab> {
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
      final res = await _api.dio.get(ApiEndpoints.facilityAdminProviders);
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
      return name.contains(q) || email.contains(q);
    }).toList();
  }

  Future<void> _toggleActive(dynamic provider) async {
    final isActive = provider['isActive'] == true;
    final action = isActive ? 'deactivate' : 'activate';
    final endpoint = isActive 
        ? ApiEndpoints.facilityAdminDeactivateProvider(provider['id'])
        : ApiEndpoints.facilityAdminActivateProvider(provider['id']);
    
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
            content: Text(e.response?.data?['message'] ?? 'Failed to $action provider.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteProvider(dynamic provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Provider'),
        content: Text('Are you sure you want to delete "${provider['fullName']}"? This action cannot be undone.'),
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
      await _api.dio.delete(ApiEndpoints.facilityAdminDeleteProvider(provider['id']));
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
            content: Text(e.response?.data?['message'] ?? 'Failed to delete provider.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showCreateDialog() async {
    final auth = context.read<AuthProvider>();
    final facilityId = auth.facilityId;
    final facilityName = auth.facilityName ?? 'Your Facility';

    if (facilityId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No facility assigned to your account.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final licCtrl = TextEditingController();
    final specCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final created = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text('Add Provider to $facilityName'),
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
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: licCtrl,
                      decoration: const InputDecoration(
                        labelText: 'License Number *',
                      ),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: specCtrl,
                      decoration: const InputDecoration(labelText: 'Specialty'),
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
                      ApiEndpoints.providers,
                      data: {
                        'fullName': nameCtrl.text.trim(),
                        'email': emailCtrl.text.trim(),
                        'password': passCtrl.text,
                        'licenseNumber': licCtrl.text.trim(),
                        'facilityId': facilityId,
                        'specialty': specCtrl.text.trim(),
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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final facilityName = auth.facilityName ?? 'Facility';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/icon/logo.png', height: 28),
            const SizedBox(width: 8),
            Flexible(
              child: Text(facilityName, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        actions: const [NotificationBell(), SizedBox(width: 4)],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: Colors.red)),
      );
    }
    if (_providers.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const EmptyState(
            icon: Icons.badge_outlined,
            title: 'No providers yet',
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _showCreateDialog,
            icon: const Icon(Icons.person_add),
            label: const Text('Add Provider'),
          ),
        ],
      );
    }

    final filtered = _filteredProviders;
    final theme = Theme.of(context);

    return Column(
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              isDense: true,
            ),
            style: const TextStyle(fontSize: 13),
            onChanged: (v) => setState(() => _searchQuery = v.trim()),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Text(
                '${filtered.length} provider${filtered.length == 1 ? '' : 's'}',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: filtered.isEmpty
                ? const EmptyState(icon: Icons.badge_outlined, title: 'No providers found')
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
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
                                backgroundColor: Colors.teal.withAlpha(25),
                                child: Text(
                                  (p['fullName'] ?? '?')[0].toString().toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.teal,
                                    fontWeight: FontWeight.bold,
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
                                            p['fullName'] ?? '',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isActive
                                                ? Colors.green.withAlpha(20)
                                                : Colors.red.withAlpha(20),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            isActive ? 'Active' : 'Inactive',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: isActive
                                                  ? Colors.green.shade700
                                                  : Colors.red.shade700,
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
                                    Text(
                                      '${p['specialty'] ?? 'General'} • ${p['licenseNumber'] ?? 'N/A'}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, size: 20),
                                onSelected: (value) {
                                  if (value == 'toggle') {
                                    _toggleActive(p);
                                  } else if (value == 'delete') {
                                    _deleteProvider(p);
                                  }
                                },
                                itemBuilder: (_) => [
                                  PopupMenuItem(
                                    value: 'toggle',
                                    child: Row(
                                      children: [
                                        Icon(
                                          isActive ? Icons.block : Icons.check_circle_outline,
                                          size: 18,
                                          color: isActive ? Colors.red.shade400 : Colors.green,
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
                                        Icon(Icons.delete_outline, size: 18, color: Colors.red.shade400),
                                        const SizedBox(width: 8),
                                        Text('Delete', style: TextStyle(color: Colors.red.shade400)),
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
              onPressed: _showCreateDialog,
              icon: const Icon(Icons.person_add),
              label: const Text('Add Provider'),
            ),
          ),
        ),
      ],
    );
  }
}
