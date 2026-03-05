import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/empty_state.dart';
import '../domain/patient_models.dart';
import 'patient_detail_screen.dart';
import 'patient_provider.dart';
import 'register_patient_screen.dart';

class PatientListScreen extends StatefulWidget {
  const PatientListScreen({super.key});

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider = context.read<PatientProvider>();
    Future.microtask(() => provider.loadAll());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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
            const Text('BirthChain'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<PatientProvider>().loadAll(),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search Bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by name, phone, or QR code...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Consumer<PatientProvider>(
                  builder: (_, prov, __) {
                    if (prov.searchQuery.isNotEmpty) {
                      return IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          prov.clearSearch();
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.primary.withAlpha(10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (v) => context.read<PatientProvider>().search(v),
            ),
          ),

          // ── Patient List ──
          Expanded(
            child: Consumer<PatientProvider>(
              builder: (_, prov, __) {
                // Determine which list to show
                final isSearch = prov.searchQuery.isNotEmpty;
                final displayList = isSearch ? prov.searchResults : prov.patients;

                if (prov.isLoading && prov.patients.isEmpty && !isSearch) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (prov.isSearching) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (prov.error != null && prov.patients.isEmpty && !isSearch) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(prov.error!, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 12),
                        FilledButton.tonal(
                          onPressed: () => prov.loadAll(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                if (isSearch && displayList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off, size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 8),
                        Text(
                          'No patients found for "${prov.searchQuery}"',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () {
                            _searchCtrl.clear();
                            prov.clearSearch();
                            Navigator.of(context).push<bool>(
                              MaterialPageRoute(builder: (_) => const RegisterPatientScreen()),
                            ).then((result) {
                              if (result == true) prov.loadAll();
                            });
                          },
                          icon: const Icon(Icons.person_add),
                          label: const Text('Register New Patient'),
                        ),
                      ],
                    ),
                  );
                }
                if (!isSearch && prov.patients.isEmpty) {
                  return const EmptyState(
                    icon: Icons.people_outline,
                    title: 'No patients yet',
                    subtitle: 'Register your first patient to get started.',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => prov.loadAll(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: displayList.length,
                    itemBuilder: (_, i) => _PatientCard(patient: displayList[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final provider = context.read<PatientProvider>();
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const RegisterPatientScreen()),
          );
          if (result == true && mounted) {
            provider.loadAll();
          }
        },
        tooltip: 'Register Patient',
        child: const Icon(Icons.person_add),
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  final Patient patient;
  const _PatientCard({required this.patient});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withAlpha(25),
          child: Text(
            patient.fullName.isNotEmpty
                ? patient.fullName[0].toUpperCase()
                : '?',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          patient.fullName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'QR: ${patient.qrCodeId}  •  DOB: ${DateFormatter.formatDate(patient.dateOfBirth)}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap:
            () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PatientDetailScreen(patient: patient),
              ),
            ),
      ),
    );
  }
}
