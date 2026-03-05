import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../features/auth/presentation/auth_provider.dart';
import '../../features/records/domain/record_models.dart';
import '../../features/records/presentation/record_provider.dart';

/// Dashboard shown to patients (role = Patient).
/// Tabs: My Records, My QR Code, Profile.
class PatientDashboardScreen extends StatefulWidget {
  const PatientDashboardScreen({super.key});

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Load patient's own records on launch
    final prov = context.read<RecordProvider>();
    Future.microtask(() => prov.loadMyRecords());
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const _MyRecordsTab(),
      const _MyQrCodeTab(),
      const _PatientProfileTab(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.medical_information_outlined),
            selectedIcon: Icon(Icons.medical_information),
            label: 'My Records',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_2_outlined),
            selectedIcon: Icon(Icons.qr_code_2),
            label: 'My QR',
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

// ─────────────────────────────────────────────
// Tab 1: My Records
// ─────────────────────────────────────────────
class _MyRecordsTab extends StatelessWidget {
  const _MyRecordsTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/icon/logo.png', height: 28),
            const SizedBox(width: 8),
            const Text('My Health Records'),
          ],
        ),
      ),
      body: Consumer<RecordProvider>(
        builder: (_, prov, __) {
          if (prov.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (prov.error != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline,
                      size: 48, color: Colors.red.shade300),
                  const SizedBox(height: 12),
                  Text(prov.error!,
                      style: TextStyle(color: Colors.red.shade600)),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => prov.loadMyRecords(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (prov.records.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.folder_open,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text(
                    'No medical records yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Records will appear here when a\nhealthcare provider adds them.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.grey.shade400, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          final records = prov.records.reversed.toList();
          return RefreshIndicator(
            onRefresh: () => prov.loadMyRecords(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: records.length + 1, // +1 for header
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      '${records.length} record${records.length == 1 ? '' : 's'}',
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 13),
                    ),
                  );
                }
                final rec = records[index - 1];
                return _PatientRecordCard(record: rec);
              },
            ),
          );
        },
      ),
    );
  }
}

class _PatientRecordCard extends StatelessWidget {
  final MedicalRecord record;
  const _PatientRecordCard({required this.record});

  String _fmtDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('MMM d, yyyy').format(dt);
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: facility + date
            Row(
              children: [
                Icon(Icons.local_hospital,
                    size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    record.facilityName.isNotEmpty
                        ? record.facilityName
                        : 'Unknown Facility',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
                Text(
                  _fmtDate(record.eventDate),
                  style:
                      TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
            if (record.providerName.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Dr. ${record.providerName}',
                style:
                    TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
            const Divider(height: 20),

            // Diagnosis
            if (record.details.isNotEmpty)
              _Field(label: 'Diagnosis', value: record.details),
            if (record.symptoms.isNotEmpty)
              _Field(label: 'Symptoms', value: record.symptoms),
            if (record.medication.isNotEmpty)
              _Field(label: 'Medication', value: record.medication),
            if (record.labTests.isNotEmpty)
              _Field(label: 'Lab Tests', value: record.labTests),
            if (record.notes.isNotEmpty)
              _Field(label: 'Notes', value: record.notes),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String value;
  const _Field({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Tab 2: My QR Code
// ─────────────────────────────────────────────
class _MyQrCodeTab extends StatelessWidget {
  const _MyQrCodeTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/icon/logo.png', height: 28),
            const SizedBox(width: 8),
            const Text('My QR Code'),
          ],
        ),
      ),
      body: Consumer<RecordProvider>(
        builder: (_, prov, __) {
          if (prov.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final patient = prov.currentClient;
          if (patient == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.qr_code_2,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text(
                    'QR Code not available',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => prov.loadMyRecords(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    'Show this QR code to your\nhealthcare provider',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(20),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        QrImageView(
                          data: patient.qrCodeId,
                          version: QrVersions.auto,
                          size: 220,
                          eyeStyle: QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: theme.colorScheme.primary,
                          ),
                          dataModuleStyle: QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            patient.qrCodeId,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Patient info summary
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _InfoRow(icon: Icons.person, label: patient.fullName),
                          if (patient.email.isNotEmpty)
                            _InfoRow(
                                icon: Icons.email_outlined,
                                label: patient.email),
                          if (patient.phone.isNotEmpty)
                            _InfoRow(
                                icon: Icons.phone_outlined,
                                label: patient.phone),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Tab 3: Patient Profile
// ─────────────────────────────────────────────
class _PatientProfileTab extends StatelessWidget {
  const _PatientProfileTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();

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
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // User card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: theme.colorScheme.primary,
                    child: Text(
                      (auth.name ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.name ?? 'Patient',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Patient',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Patient details from loaded client
          Consumer<RecordProvider>(
            builder: (_, prov, __) {
              final p = prov.currentClient;
              if (p == null) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Personal Information',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Column(
                      children: [
                        if (p.email.isNotEmpty)
                          ListTile(
                            leading: const Icon(Icons.email_outlined),
                            title: const Text('Email'),
                            subtitle: Text(p.email),
                          ),
                        if (p.phone.isNotEmpty)
                          ListTile(
                            leading: const Icon(Icons.phone_outlined),
                            title: const Text('Phone'),
                            subtitle: Text(p.phone),
                          ),
                        if (p.gender.isNotEmpty)
                          ListTile(
                            leading: const Icon(Icons.wc_outlined),
                            title: const Text('Gender'),
                            subtitle: Text(p.gender),
                          ),
                        if (p.address.isNotEmpty)
                          ListTile(
                            leading: const Icon(Icons.location_on_outlined),
                            title: const Text('Address'),
                            subtitle: Text(p.address),
                          ),
                        if (p.dateOfBirth.isNotEmpty)
                          ListTile(
                            leading:
                                const Icon(Icons.calendar_today_outlined),
                            title: const Text('Date of Birth'),
                            subtitle: Text(_fmtDob(p.dateOfBirth)),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            },
          ),

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
    );
  }

  static String _fmtDob(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('MMM d, yyyy').format(dt);
    } catch (_) {
      return raw;
    }
  }
}
