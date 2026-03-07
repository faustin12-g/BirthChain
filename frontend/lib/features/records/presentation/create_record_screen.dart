import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../patients/domain/patient_models.dart';
import '../domain/record_models.dart';
import 'record_provider.dart';

class CreateRecordScreen extends StatefulWidget {
  final Patient patient;
  const CreateRecordScreen({super.key, required this.patient});

  @override
  State<CreateRecordScreen> createState() => _CreateRecordScreenState();
}

class _CreateRecordScreenState extends State<CreateRecordScreen> {
  final _formKey = GlobalKey<FormState>();

  // Record type
  String _recordType = RecordTypes.consultation;
  DateTime _visitDate = DateTime.now();

  // Clinical Information
  final _chiefComplaintCtrl = TextEditingController();
  final _symptomsCtrl = TextEditingController();
  final _examinationCtrl = TextEditingController();
  final _diagnosisCtrl = TextEditingController();
  final _secondaryDiagnosesCtrl = TextEditingController();
  final _treatmentCtrl = TextEditingController();

  // Vital Signs
  final _bpSystolicCtrl = TextEditingController();
  final _bpDiastolicCtrl = TextEditingController();
  final _pulseCtrl = TextEditingController();
  final _tempCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _spo2Ctrl = TextEditingController();
  final _rrCtrl = TextEditingController();

  // Maternal Health
  final _gestWeeksCtrl = TextEditingController();
  final _gestDaysCtrl = TextEditingController();
  final _fundalHeightCtrl = TextEditingController();
  final _fetalHRCtrl = TextEditingController();
  String? _fetalPresentation;
  String? _fetalMovement;
  String? _deliveryMode;
  String? _birthOutcome;
  final _babyWeightCtrl = TextEditingController();
  final _apgar1Ctrl = TextEditingController();
  final _apgar5Ctrl = TextEditingController();

  // Medications & Lab Tests
  final _medicationsCtrl = TextEditingController();
  final _labTestsCtrl = TextEditingController();
  final _immunizationsCtrl = TextEditingController();

  // Follow-up
  final _careInstructionsCtrl = TextEditingController();
  bool _followUpRequired = false;
  DateTime? _followUpDate;
  final _referralCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-select maternal record type if patient is pregnant
    if (widget.patient.isMaternal) {
      _recordType = RecordTypes.antenatalVisit;
    }
  }

  @override
  void dispose() {
    _chiefComplaintCtrl.dispose();
    _symptomsCtrl.dispose();
    _examinationCtrl.dispose();
    _diagnosisCtrl.dispose();
    _secondaryDiagnosesCtrl.dispose();
    _treatmentCtrl.dispose();
    _bpSystolicCtrl.dispose();
    _bpDiastolicCtrl.dispose();
    _pulseCtrl.dispose();
    _tempCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _spo2Ctrl.dispose();
    _rrCtrl.dispose();
    _gestWeeksCtrl.dispose();
    _gestDaysCtrl.dispose();
    _fundalHeightCtrl.dispose();
    _fetalHRCtrl.dispose();
    _babyWeightCtrl.dispose();
    _apgar1Ctrl.dispose();
    _apgar5Ctrl.dispose();
    _medicationsCtrl.dispose();
    _labTestsCtrl.dispose();
    _immunizationsCtrl.dispose();
    _careInstructionsCtrl.dispose();
    _referralCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  bool get _showMaternalSection =>
      _recordType == RecordTypes.antenatalVisit ||
      _recordType == RecordTypes.delivery;

  String? get _bloodPressure {
    final sys = _bpSystolicCtrl.text.trim();
    final dia = _bpDiastolicCtrl.text.trim();
    if (sys.isEmpty && dia.isEmpty) return null;
    return '$sys/$dia';
  }

  Future<void> _selectVisitDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _visitDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _visitDate = date);
    }
  }

  Future<void> _selectFollowUpDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate:
          _followUpDate ?? DateTime.now().add(const Duration(days: 14)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _followUpDate = date);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final prov = context.read<RecordProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final record = await prov.create(
      CreateRecordRequest(
        clientId: widget.patient.id,
        recordType: _recordType,
        visitDate: _visitDate,
        chiefComplaint: _chiefComplaintCtrl.text.trim(),
        symptoms: _symptomsCtrl.text.trim(),
        examination:
            _examinationCtrl.text.trim().isEmpty
                ? null
                : _examinationCtrl.text.trim(),
        diagnosis: _diagnosisCtrl.text.trim(),
        secondaryDiagnoses:
            _secondaryDiagnosesCtrl.text.trim().isEmpty
                ? null
                : _secondaryDiagnosesCtrl.text.trim(),
        treatment:
            _treatmentCtrl.text.trim().isEmpty
                ? null
                : _treatmentCtrl.text.trim(),
        bloodPressure: _bloodPressure,
        pulseRate: int.tryParse(_pulseCtrl.text.trim()),
        temperature: double.tryParse(_tempCtrl.text.trim()),
        weight: double.tryParse(_weightCtrl.text.trim()),
        height: double.tryParse(_heightCtrl.text.trim()),
        oxygenSaturation: int.tryParse(_spo2Ctrl.text.trim()),
        respiratoryRate: int.tryParse(_rrCtrl.text.trim()),
        gestationalWeeks: int.tryParse(_gestWeeksCtrl.text.trim()),
        gestationalDays: int.tryParse(_gestDaysCtrl.text.trim()),
        fundalHeight: double.tryParse(_fundalHeightCtrl.text.trim()),
        fetalHeartRate: int.tryParse(_fetalHRCtrl.text.trim()),
        fetalPresentation: _fetalPresentation,
        fetalMovement: _fetalMovement,
        deliveryMode: _deliveryMode,
        birthOutcome: _birthOutcome,
        babyWeightGrams: int.tryParse(_babyWeightCtrl.text.trim()),
        apgarScore1Min: int.tryParse(_apgar1Ctrl.text.trim()),
        apgarScore5Min: int.tryParse(_apgar5Ctrl.text.trim()),
        medications:
            _medicationsCtrl.text.trim().isEmpty
                ? null
                : _medicationsCtrl.text.trim(),
        labTests:
            _labTestsCtrl.text.trim().isEmpty
                ? null
                : _labTestsCtrl.text.trim(),
        immunizations:
            _immunizationsCtrl.text.trim().isEmpty
                ? null
                : _immunizationsCtrl.text.trim(),
        careInstructions:
            _careInstructionsCtrl.text.trim().isEmpty
                ? null
                : _careInstructionsCtrl.text.trim(),
        followUpRequired: _followUpRequired,
        followUpDate: _followUpDate,
        referralTo:
            _referralCtrl.text.trim().isEmpty
                ? null
                : _referralCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      ),
    );

    if (record != null && mounted) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Medical record created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      navigator.pop(true);
    } else if (prov.error != null && mounted) {
      messenger.showSnackBar(
        SnackBar(content: Text(prov.error!), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Medical Record'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Patient info card
            _buildPatientCard(theme, colorScheme),
            const SizedBox(height: 16),

            // Record type selection
            _buildSection(
              title: 'Record Type',
              icon: Icons.category_outlined,
              color: colorScheme.primary,
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _recordType,
                    decoration: const InputDecoration(
                      labelText: 'Type of Visit',
                      prefixIcon: Icon(Icons.local_hospital_outlined),
                    ),
                    items:
                        RecordTypes.all
                            .map(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Text(RecordTypes.getDisplayName(type)),
                              ),
                            )
                            .toList(),
                    onChanged: (v) => setState(() => _recordType = v!),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _selectVisitDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Visit Date',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      child: Text(
                        DateFormat('MMM dd, yyyy').format(_visitDate),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Clinical information
            _buildSection(
              title: 'Clinical Information',
              icon: Icons.medical_information_outlined,
              color: Colors.blue,
              child: Column(
                children: [
                  TextFormField(
                    controller: _chiefComplaintCtrl,
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Chief Complaint *',
                      hintText: 'Main reason for visit',
                      alignLabelWithHint: true,
                    ),
                    validator:
                        (v) =>
                            v == null || v.trim().isEmpty
                                ? 'Chief complaint is required'
                                : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _symptomsCtrl,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Symptoms',
                      hintText: 'Describe symptoms (one per line)',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _examinationCtrl,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Physical Examination',
                      hintText: 'Examination findings',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _diagnosisCtrl,
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Diagnosis *',
                      hintText: 'Primary diagnosis',
                      alignLabelWithHint: true,
                    ),
                    validator:
                        (v) =>
                            v == null || v.trim().isEmpty
                                ? 'Diagnosis is required'
                                : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _secondaryDiagnosesCtrl,
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Secondary Diagnoses',
                      hintText: 'Additional diagnoses (comma separated)',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _treatmentCtrl,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Treatment',
                      hintText: 'Treatment provided',
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Vital signs
            _buildSection(
              title: 'Vital Signs',
              icon: Icons.monitor_heart_outlined,
              color: Colors.red,
              isCollapsible: true,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _bpSystolicCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'BP (Systolic)',
                            hintText: 'e.g. 120',
                            suffixText: 'mmHg',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('/', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _bpDiastolicCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Diastolic',
                            hintText: 'e.g. 80',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _pulseCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Pulse',
                            hintText: 'e.g. 72',
                            suffixText: 'bpm',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _tempCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Temperature',
                            hintText: 'e.g. 36.5',
                            suffixText: '°C',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _weightCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Weight',
                            hintText: 'e.g. 65.5',
                            suffixText: 'kg',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _heightCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Height',
                            hintText: 'e.g. 165',
                            suffixText: 'cm',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _spo2Ctrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'SpO2',
                            hintText: 'e.g. 98',
                            suffixText: '%',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _rrCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Resp. Rate',
                            hintText: 'e.g. 16',
                            suffixText: '/min',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Maternal health section (shown conditionally)
            if (_showMaternalSection) ...[
              _buildSection(
                title: 'Maternal Health',
                icon: Icons.pregnant_woman,
                color: Colors.pink,
                child: Column(
                  children: [
                    // Gestational age
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _gestWeeksCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Gestational Age',
                              hintText: 'Weeks',
                              suffixText: 'weeks',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _gestDaysCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Days',
                              hintText: '0-6',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _fundalHeightCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Fundal Height',
                              hintText: 'e.g. 28',
                              suffixText: 'cm',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _fetalHRCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Fetal Heart Rate',
                              hintText: 'e.g. 140',
                              suffixText: 'bpm',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _fetalPresentation,
                      decoration: const InputDecoration(
                        labelText: 'Fetal Presentation',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Cephalic',
                          child: Text('Cephalic (Head down)'),
                        ),
                        DropdownMenuItem(
                          value: 'Breech',
                          child: Text('Breech'),
                        ),
                        DropdownMenuItem(
                          value: 'Transverse',
                          child: Text('Transverse'),
                        ),
                        DropdownMenuItem(
                          value: 'Oblique',
                          child: Text('Oblique'),
                        ),
                      ],
                      onChanged: (v) => setState(() => _fetalPresentation = v),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _fetalMovement,
                      decoration: const InputDecoration(
                        labelText: 'Fetal Movement',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Active',
                          child: Text('Active'),
                        ),
                        DropdownMenuItem(
                          value: 'Reduced',
                          child: Text('Reduced'),
                        ),
                        DropdownMenuItem(
                          value: 'Absent',
                          child: Text('Absent'),
                        ),
                      ],
                      onChanged: (v) => setState(() => _fetalMovement = v),
                    ),

                    // Delivery fields (for delivery records)
                    if (_recordType == RecordTypes.delivery) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        'Delivery Information',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _deliveryMode,
                        decoration: const InputDecoration(
                          labelText: 'Mode of Delivery',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'SVD',
                            child: Text('Spontaneous Vaginal Delivery'),
                          ),
                          DropdownMenuItem(
                            value: 'Caesarean',
                            child: Text('Caesarean Section'),
                          ),
                          DropdownMenuItem(
                            value: 'Assisted',
                            child: Text('Assisted Delivery'),
                          ),
                          DropdownMenuItem(value: 'VBAC', child: Text('VBAC')),
                        ],
                        onChanged: (v) => setState(() => _deliveryMode = v),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _birthOutcome,
                        decoration: const InputDecoration(
                          labelText: 'Birth Outcome',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Live Birth',
                            child: Text('Live Birth'),
                          ),
                          DropdownMenuItem(
                            value: 'Stillbirth',
                            child: Text('Stillbirth'),
                          ),
                          DropdownMenuItem(
                            value: 'Neonatal Death',
                            child: Text('Neonatal Death'),
                          ),
                        ],
                        onChanged: (v) => setState(() => _birthOutcome = v),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _babyWeightCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Baby Weight',
                          hintText: 'e.g. 3200',
                          suffixText: 'grams',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _apgar1Ctrl,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: const InputDecoration(
                                labelText: 'APGAR (1 min)',
                                hintText: '0-10',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _apgar5Ctrl,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: const InputDecoration(
                                labelText: 'APGAR (5 min)',
                                hintText: '0-10',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Medications & Tests
            _buildSection(
              title: 'Medications & Tests',
              icon: Icons.medication_outlined,
              color: Colors.orange,
              isCollapsible: true,
              child: Column(
                children: [
                  TextFormField(
                    controller: _medicationsCtrl,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Medications Prescribed',
                      hintText: 'List medications with dosage (one per line)',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _labTestsCtrl,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Laboratory Tests',
                      hintText: 'Tests ordered or results (one per line)',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _immunizationsCtrl,
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Immunizations',
                      hintText: 'Vaccines administered',
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Follow-up & Instructions
            _buildSection(
              title: 'Follow-up & Instructions',
              icon: Icons.event_note_outlined,
              color: Colors.teal,
              child: Column(
                children: [
                  TextFormField(
                    controller: _careInstructionsCtrl,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Care Instructions',
                      hintText: 'Instructions for the patient',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    value: _followUpRequired,
                    onChanged:
                        (v) => setState(() {
                          _followUpRequired = v;
                          if (!v) _followUpDate = null;
                        }),
                    title: const Text('Follow-up Required'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (_followUpRequired) ...[
                    InkWell(
                      onTap: _selectFollowUpDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Follow-up Date',
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                        ),
                        child: Text(
                          _followUpDate != null
                              ? DateFormat(
                                'MMM dd, yyyy',
                              ).format(_followUpDate!)
                              : 'Select date',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    controller: _referralCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Referral To',
                      hintText: 'Specialist or facility name',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesCtrl,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Additional Notes',
                      hintText: 'Any other important information',
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Submit button
            Consumer<RecordProvider>(
              builder:
                  (_, prov, __) => FilledButton.icon(
                    onPressed: prov.isLoading ? null : _submit,
                    icon:
                        prov.isLoading
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Icon(Icons.save),
                    label: Text(
                      prov.isLoading ? 'Saving...' : 'Save Medical Record',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                    ),
                  ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientCard(ThemeData theme, ColorScheme colorScheme) {
    final patient = widget.patient;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor:
                  patient.isMaternal
                      ? Colors.pink.shade100
                      : colorScheme.primaryContainer,
              child: Icon(
                patient.isMaternal ? Icons.pregnant_woman : Icons.person,
                color: patient.isMaternal ? Colors.pink : colorScheme.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patient.fullName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    patient.qrCodeId,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                  if (patient.isMaternal) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.pink.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        patient.gestationalAge.isNotEmpty
                            ? 'Pregnant - ${patient.gestationalAge}'
                            : 'Maternal Patient',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.pink.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
    bool isCollapsible = false,
  }) {
    return Card(
      elevation: 1,
      child: ExpansionTile(
        initiallyExpanded: !isCollapsible,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w600, color: color),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [child],
      ),
    );
  }
}
