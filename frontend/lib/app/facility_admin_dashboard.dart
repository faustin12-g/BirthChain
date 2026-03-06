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
      final res = await _api.dio.get(ApiEndpoints.providers);
      _providers = res.data as List;
    } on DioException catch (e) {
      _error = e.response?.data?['message'] ?? 'Failed to load providers.';
    } catch (_) {
      _error = 'Something went wrong.';
    }
    setState(() => _loading = false);
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

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _providers.length,
              itemBuilder: (_, i) {
                final p = _providers[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        (p['fullName'] ?? '?')[0].toString().toUpperCase(),
                      ),
                    ),
                    title: Text(p['fullName'] ?? ''),
                    subtitle: Text(
                      '${p['email'] ?? ''}  •  ${p['specialty'] ?? ''}',
                    ),
                    trailing: Chip(label: Text(p['licenseNumber'] ?? '')),
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
