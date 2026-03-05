import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../core/utils/date_formatter.dart';
import '../core/widgets/empty_state.dart';
import '../di/injection.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administration'),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.orange,
          tabs: const [
            Tab(icon: Icon(Icons.badge_outlined), text: 'Providers'),
            Tab(icon: Icon(Icons.history), text: 'Activity Logs'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: const [_ProvidersTab(), _ActivityLogsTab()],
      ),
    );
  }
}

// ── Providers Tab ──

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
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final licCtrl = TextEditingController();
    final facCtrl = TextEditingController();
    final specCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final created = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Create Provider'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Full Name'),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: passCtrl,
                      decoration: const InputDecoration(labelText: 'Password'),
                      obscureText: true,
                      validator:
                          (v) =>
                              v != null && v.length >= 6 ? null : 'Min 6 chars',
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: licCtrl,
                      decoration: const InputDecoration(
                        labelText: 'License Number',
                      ),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: facCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Facility Name',
                      ),
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
                        'facilityName': facCtrl.text.trim(),
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
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: Colors.red)),
      );
    }

    if (_providers.isEmpty) {
      return const EmptyState(
        icon: Icons.badge_outlined,
        title: 'No providers yet',
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
                    subtitle: Text('${p['email']}  •  ${p['specialty'] ?? ''}'),
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
              label: const Text('Create Provider'),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Activity Logs Tab ──

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
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: Colors.red)),
      );
    }

    if (_logs.isEmpty) {
      return const EmptyState(icon: Icons.history, title: 'No activity yet');
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _logs.length,
        itemBuilder: (_, i) {
          final log = _logs[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 6),
            child: ListTile(
              dense: true,
              leading: Icon(
                _iconForAction(log['action'] ?? ''),
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              title: Text(
                log['action'] ?? '',
                style: const TextStyle(fontSize: 13),
              ),
              subtitle: Text(
                log['userName'] ?? '',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: Text(
                DateFormatter.formatDateTime(log['timestamp'] ?? ''),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _iconForAction(String action) {
    if (action.contains('Logged in')) return Icons.login;
    if (action.contains('Created provider')) return Icons.badge;
    if (action.contains('Registered client')) return Icons.person_add;
    if (action.contains('record')) return Icons.description;
    return Icons.circle;
  }
}
