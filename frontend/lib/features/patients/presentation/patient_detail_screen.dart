import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/utils/date_formatter.dart';
import '../../records/domain/record_models.dart';
import '../../records/presentation/create_record_screen.dart';
import '../../records/presentation/record_provider.dart';
import '../domain/patient_models.dart';

class PatientDetailScreen extends StatefulWidget {
  final Patient patient;
  const PatientDetailScreen({super.key, required this.patient});

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  @override
  void initState() {
    super.initState();
    final prov = context.read<RecordProvider>();
    Future.microtask(() => prov.loadByClientId(widget.patient.id));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final patient = widget.patient;

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
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'refresh') {
                context.read<RecordProvider>().loadByClientId(patient.id);
              }
            },
            itemBuilder:
                (_) => [
                  const PopupMenuItem(value: 'refresh', child: Text('Refresh')),
                ],
          ),
        ],
      ),
      body: Consumer<RecordProvider>(
        builder: (_, prov, __) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Patient Info + QR ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patient.fullName,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (patient.phone.isNotEmpty)
                          Row(
                            children: [
                              Icon(
                                Icons.phone,
                                size: 14,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                patient.phone,
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        const SizedBox(height: 2),
                        if (patient.gender.isNotEmpty)
                          Row(
                            children: [
                              Icon(
                                Icons.wc,
                                size: 14,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                patient.gender,
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        if (patient.gender.isNotEmpty)
                          const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.cake,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormatter.formatDate(patient.dateOfBirth),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            patient.qrCodeId,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                              fontSize: 13,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: QrImageView(
                        data: patient.qrCodeId,
                        version: QrVersions.auto,
                        size: 80,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Additional Info (email & address) ──
              if (patient.email.isNotEmpty || patient.address.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    children: [
                      if (patient.email.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Icon(Icons.email_outlined, size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 6),
                              Text(patient.email, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                            ],
                          ),
                        ),
                      if (patient.address.isNotEmpty)
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(patient.address, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

              const Divider(),
              const SizedBox(height: 8),

              // ── Medical History ──
              Text(
                'Medical History',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              if (prov.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (prov.records.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 48,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No records yet',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...prov.records.map((r) => _MedicalHistoryCard(record: r)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final prov = context.read<RecordProvider>();
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => CreateRecordScreen(patient: widget.patient),
            ),
          );
          if (result == true && mounted) {
            prov.loadByClientId(widget.patient.id);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _MedicalHistoryCard extends StatelessWidget {
  final MedicalRecord record;
  const _MedicalHistoryCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Date + Facility
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.medical_information_outlined,
                          color: theme.colorScheme.primary, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormatter.formatDate(record.eventDate),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                if (record.facilityName.isNotEmpty)
                  Row(
                    children: [
                      Icon(Icons.local_hospital, size: 12, color: Colors.grey.shade500),
                      const SizedBox(width: 3),
                      Text(
                        record.facilityName,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Diagnosis (always shown)
            _RecordField(icon: Icons.medical_information_outlined, label: 'Diagnosis', value: record.details),

            // Symptoms
            if (record.symptoms.isNotEmpty)
              _RecordField(icon: Icons.sick_outlined, label: 'Symptoms', value: record.symptoms),

            // Medication
            if (record.medication.isNotEmpty)
              _RecordField(icon: Icons.medication_outlined, label: 'Medication', value: record.medication),

            // Lab Tests
            if (record.labTests.isNotEmpty)
              _RecordField(icon: Icons.science_outlined, label: 'Lab Tests', value: record.labTests),

            // Notes
            if (record.notes.isNotEmpty)
              _RecordField(icon: Icons.note_alt_outlined, label: 'Notes', value: record.notes),
          ],
        ),
      ),
    );
  }
}

class _RecordField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _RecordField({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Text('$label: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}
