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
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String? _facilityFilter;
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    final prov = context.read<RecordProvider>();
    Future.microtask(() => prov.loadByClientId(widget.patient.id));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Filter records based on search query, facility, and date range.
  List<MedicalRecord> _applyFilters(List<MedicalRecord> records) {
    var filtered = records;

    // Text search across diagnosis, symptoms, medication, notes, labTests
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered =
          filtered.where((r) {
            return r.details.toLowerCase().contains(q) ||
                r.symptoms.toLowerCase().contains(q) ||
                r.medication.toLowerCase().contains(q) ||
                (r.notes ?? '').toLowerCase().contains(q) ||
                (r.labTests ?? '').toLowerCase().contains(q) ||
                r.facilityName.toLowerCase().contains(q) ||
                r.providerName.toLowerCase().contains(q);
          }).toList();
    }

    // Facility filter
    if (_facilityFilter != null) {
      filtered =
          filtered.where((r) => r.facilityName == _facilityFilter).toList();
    }

    // Date range filter
    if (_dateRange != null) {
      filtered =
          filtered.where((r) {
            final date = DateTime.tryParse(r.eventDate);
            if (date == null) return false;
            return !date.isBefore(_dateRange!.start) &&
                !date.isAfter(_dateRange!.end.add(const Duration(days: 1)));
          }).toList();
    }

    return filtered;
  }

  /// Extract unique facility names from records.
  List<String> _uniqueFacilities(List<MedicalRecord> records) {
    return records
        .map((r) => r.facilityName)
        .where((f) => f.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  void _clearAllFilters() {
    setState(() {
      _searchCtrl.clear();
      _searchQuery = '';
      _facilityFilter = null;
      _dateRange = null;
    });
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
                              Icon(
                                Icons.email_outlined,
                                size: 14,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                patient.email,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (patient.address.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                patient.address,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

              const Divider(),
              const SizedBox(height: 8),

              // ── Medical History Header ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Medical History',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_searchQuery.isNotEmpty ||
                      _facilityFilter != null ||
                      _dateRange != null)
                    TextButton.icon(
                      onPressed: _clearAllFilters,
                      icon: const Icon(Icons.clear_all, size: 18),
                      label: const Text('Clear'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // ── Search bar ──
              TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search records...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon:
                      _searchQuery.isNotEmpty
                          ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                          : null,
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
              const SizedBox(height: 8),

              // ── Filter chips row ──
              if (!prov.isLoading && prov.records.isNotEmpty)
                Builder(
                  builder: (_) {
                    final facilities = _uniqueFacilities(prov.records);
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          // Date range chip
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: FilterChip(
                              avatar: const Icon(
                                Icons.calendar_today,
                                size: 14,
                              ),
                              label: Text(
                                _dateRange != null
                                    ? '${_fmt(_dateRange!.start)} – ${_fmt(_dateRange!.end)}'
                                    : 'Date range',
                                style: const TextStyle(fontSize: 12),
                              ),
                              selected: _dateRange != null,
                              onSelected: (_) => _pickDateRange(),
                              onDeleted:
                                  _dateRange != null
                                      ? () => setState(() => _dateRange = null)
                                      : null,
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          // Facility chips
                          ...facilities.map(
                            (f) => Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: FilterChip(
                                avatar: const Icon(
                                  Icons.local_hospital,
                                  size: 14,
                                ),
                                label: Text(
                                  f,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                selected: _facilityFilter == f,
                                onSelected: (sel) {
                                  setState(
                                    () => _facilityFilter = sel ? f : null,
                                  );
                                },
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 8),

              // ── Records list ──
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
                Builder(
                  builder: (_) {
                    final filtered = _applyFilters(prov.records);
                    if (filtered.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.filter_list_off,
                                size: 40,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No records match your filters',
                                style: TextStyle(color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            '${filtered.length} record${filtered.length == 1 ? '' : 's'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),
                        ...filtered.map((r) => _MedicalHistoryCard(record: r)),
                      ],
                    );
                  },
                ),
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

/// Format date as MM/DD for chip label.
String _fmt(DateTime d) =>
    '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';

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
                      child: Icon(
                        Icons.medical_information_outlined,
                        color: theme.colorScheme.primary,
                        size: 18,
                      ),
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
                      Icon(
                        Icons.local_hospital,
                        size: 12,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        record.facilityName,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Diagnosis (always shown)
            _RecordField(
              icon: Icons.medical_information_outlined,
              label: 'Diagnosis',
              value: record.details,
            ),

            // Symptoms
            if (record.symptoms.isNotEmpty)
              _RecordField(
                icon: Icons.sick_outlined,
                label: 'Symptoms',
                value: record.symptoms,
              ),

            // Medication
            if (record.medication.isNotEmpty)
              _RecordField(
                icon: Icons.medication_outlined,
                label: 'Medication',
                value: record.medication,
              ),

            // Lab Tests
            if ((record.labTests ?? '').isNotEmpty)
              _RecordField(
                icon: Icons.science_outlined,
                label: 'Lab Tests',
                value: record.labTests ?? '',
              ),

            // Notes
            if ((record.notes ?? '').isNotEmpty)
              _RecordField(
                icon: Icons.note_alt_outlined,
                label: 'Notes',
                value: record.notes ?? '',
              ),
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
  const _RecordField({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}
