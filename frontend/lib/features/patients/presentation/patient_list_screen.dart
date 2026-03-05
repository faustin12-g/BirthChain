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
  @override
  void initState() {
    super.initState();
    final provider = context.read<PatientProvider>();
    Future.microtask(() => provider.loadAll());
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
      body: Consumer<PatientProvider>(
        builder: (_, prov, __) {
          if (prov.isLoading && prov.patients.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (prov.error != null && prov.patients.isEmpty) {
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
          if (prov.patients.isEmpty) {
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
              itemCount: prov.patients.length,
              itemBuilder: (_, i) => _PatientCard(patient: prov.patients[i]),
            ),
          );
        },
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
