import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../domain/patient_models.dart';
import 'patient_provider.dart';

class RegisterPatientScreen extends StatefulWidget {
  /// When true, the screen is used as a tab (no back button, "Done" resets form).
  final bool embedded;
  const RegisterPatientScreen({super.key, this.embedded = false});

  @override
  State<RegisterPatientScreen> createState() => _RegisterPatientScreenState();
}

class _RegisterPatientScreenState extends State<RegisterPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Basic info
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  String _selectedGender = 'Male';
  DateTime? _dob;
  
  // Medical profile
  String _patientCategory = PatientCategories.general;
  String? _bloodType;
  final _allergiesCtrl = TextEditingController();
  final _chronicConditionsCtrl = TextEditingController();
  final _emergencyNameCtrl = TextEditingController();
  final _emergencyPhoneCtrl = TextEditingController();
  
  // Maternal health
  bool _isPregnant = false;
  DateTime? _lastMenstrualPeriod;
  int? _gravida;
  int? _parity;
  bool _isHighRisk = false;
  final _highRiskFactorsCtrl = TextEditingController();
  
  Patient? _createdPatient;

  static const _genders = ['Male', 'Female', 'Other'];
  static const _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _allergiesCtrl.dispose();
    _chronicConditionsCtrl.dispose();
    _emergencyNameCtrl.dispose();
    _emergencyPhoneCtrl.dispose();
    _highRiskFactorsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _pickLMPDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 60)),
      firstDate: DateTime.now().subtract(const Duration(days: 300)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _lastMenstrualPeriod = picked);
  }

  DateTime? get _expectedDeliveryDate {
    if (_lastMenstrualPeriod == null) return null;
    return _lastMenstrualPeriod!.add(const Duration(days: 280));
  }

  int? get _gestationalWeeks {
    if (_lastMenstrualPeriod == null) return null;
    return DateTime.now().difference(_lastMenstrualPeriod!).inDays ~/ 7;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date of birth.')),
      );
      return;
    }

    final prov = context.read<PatientProvider>();
    final patient = await prov.create(
      CreatePatientRequest(
        fullName: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        gender: _selectedGender,
        address: _addressCtrl.text.trim(),
        dateOfBirth: _dob!.toIso8601String().split('T').first,
        patientCategory: _patientCategory,
        bloodType: _bloodType,
        allergies: _allergiesCtrl.text.trim().isEmpty ? null : _allergiesCtrl.text.trim(),
        chronicConditions: _chronicConditionsCtrl.text.trim().isEmpty ? null : _chronicConditionsCtrl.text.trim(),
        emergencyContactName: _emergencyNameCtrl.text.trim().isEmpty ? null : _emergencyNameCtrl.text.trim(),
        emergencyContactPhone: _emergencyPhoneCtrl.text.trim().isEmpty ? null : _emergencyPhoneCtrl.text.trim(),
        isPregnant: _isPregnant,
        lastMenstrualPeriod: _lastMenstrualPeriod,
        expectedDeliveryDate: _expectedDeliveryDate,
        gravida: _gravida,
        parity: _parity,
        isHighRiskPregnancy: _isHighRisk,
        highRiskFactors: _highRiskFactorsCtrl.text.trim().isEmpty ? null : _highRiskFactorsCtrl.text.trim(),
      ),
    );

    if (patient != null && mounted) {
      setState(() => _createdPatient = patient);
    } else if (prov.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(prov.error!), backgroundColor: Colors.red),
      );
    }
  }

  void _resetForm() {
    setState(() {
      _createdPatient = null;
      _nameCtrl.clear();
      _phoneCtrl.clear();
      _emailCtrl.clear();
      _addressCtrl.clear();
      _allergiesCtrl.clear();
      _chronicConditionsCtrl.clear();
      _emergencyNameCtrl.clear();
      _emergencyPhoneCtrl.clear();
      _highRiskFactorsCtrl.clear();
      _selectedGender = 'Male';
      _dob = null;
      _patientCategory = PatientCategories.general;
      _bloodType = null;
      _isPregnant = false;
      _lastMenstrualPeriod = null;
      _gravida = null;
      _parity = null;
      _isHighRisk = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ── Success state: show generated QR ──
    if (_createdPatient != null) {
      return Scaffold(
        appBar: AppBar(
          title:
              widget.embedded
                  ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/icon/logo.png', height: 28),
                      const SizedBox(width: 8),
                      const Text('BirthChain'),
                    ],
                  )
                  : const Text('Register Patient'),
          automaticallyImplyLeading: !widget.embedded,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Icon(Icons.check_circle, size: 60, color: Colors.green.shade400),
              const SizedBox(height: 16),
              Text(
                'Patient Registered!',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _createdPatient!.qrCodeId,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: QrImageView(
                    data: _createdPatient!.qrCodeId,
                    version: QrVersions.auto,
                    size: 200,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'QR code generated.\nUse this code to access patient\'s records.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (widget.embedded) {
                      _resetForm();
                    } else {
                      Navigator.of(context).pop(true);
                    }
                  },
                  child: Text(widget.embedded ? 'Register Another' : 'Done'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ── Form state ──
    return Scaffold(
      appBar: AppBar(
        title:
            widget.embedded
                ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/icon/logo.png', height: 28),
                    const SizedBox(width: 8),
                    const Text('BirthChain'),
                  ],
                )
                : const Text('Register Patient'),
        automaticallyImplyLeading: !widget.embedded,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // === SECTION: Basic Information ===
            _buildSectionHeader(context, 'Basic Information', Icons.person_outline, Colors.blue),
            const SizedBox(height: 12),
            
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Full Name *',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedGender,
                    decoration: const InputDecoration(
                      labelText: 'Gender *',
                      prefixIcon: Icon(Icons.wc_outlined),
                    ),
                    items: _genders.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                    onChanged: (v) {
                      setState(() {
                        _selectedGender = v!;
                        // Auto-select maternal category for females if pregnant
                        if (v != 'Female') {
                          _isPregnant = false;
                          if (_patientCategory == PatientCategories.maternal) {
                            _patientCategory = PatientCategories.general;
                          }
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date of Birth *',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      child: Text(
                        _dob != null
                            ? DateFormat('MMM dd, yyyy').format(_dob!)
                            : 'Select',
                        style: TextStyle(
                          color: _dob != null ? null : Colors.grey.shade500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _addressCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Address',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 24),

            // === SECTION: Patient Category ===
            _buildSectionHeader(context, 'Patient Category', Icons.category_outlined, Colors.purple),
            const SizedBox(height: 12),
            
            DropdownButtonFormField<String>(
              value: _patientCategory,
              decoration: const InputDecoration(
                labelText: 'Patient Type *',
                prefixIcon: Icon(Icons.medical_services_outlined),
              ),
              items: PatientCategories.all.map((cat) => DropdownMenuItem(
                value: cat,
                child: Text(PatientCategories.getDisplayName(cat)),
              )).toList(),
              onChanged: (v) {
                setState(() {
                  _patientCategory = v!;
                  if (v == PatientCategories.maternal && _selectedGender == 'Female') {
                    _isPregnant = true;
                  }
                });
              },
            ),
            const SizedBox(height: 24),

            // === SECTION: Medical Profile ===
            _buildSectionHeader(context, 'Medical Profile', Icons.medical_information_outlined, Colors.orange),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: _bloodType,
              decoration: const InputDecoration(
                labelText: 'Blood Type',
                prefixIcon: Icon(Icons.bloodtype_outlined),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Unknown')),
                ..._bloodTypes.map((bt) => DropdownMenuItem(value: bt, child: Text(bt))),
              ],
              onChanged: (v) => setState(() => _bloodType = v),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _allergiesCtrl,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Known Allergies',
                hintText: 'e.g., Penicillin, Peanuts (comma-separated)',
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 24),
                  child: Icon(Icons.warning_amber_outlined),
                ),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),

            if (_patientCategory == PatientCategories.chronicDisease) ...[
              TextFormField(
                controller: _chronicConditionsCtrl,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Chronic Conditions',
                  hintText: 'e.g., Diabetes, Hypertension (comma-separated)',
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 24),
                    child: Icon(Icons.healing_outlined),
                  ),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 12),

            // Emergency contact
            Text(
              'Emergency Contact',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _emergencyNameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      prefixIcon: Icon(Icons.contact_emergency_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _emergencyPhoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // === SECTION: Maternal Health (only for females) ===
            if (_selectedGender == 'Female') ...[
              _buildSectionHeader(context, 'Maternal Health', Icons.pregnant_woman, Colors.pink),
              const SizedBox(height: 12),
              
              SwitchListTile(
                value: _isPregnant,
                onChanged: (v) => setState(() {
                  _isPregnant = v;
                  if (v && _patientCategory == PatientCategories.general) {
                    _patientCategory = PatientCategories.maternal;
                  }
                }),
                title: const Text('Currently Pregnant'),
                contentPadding: EdgeInsets.zero,
              ),

              if (_isPregnant) ...[
                const SizedBox(height: 12),
                InkWell(
                  onTap: _pickLMPDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Last Menstrual Period (LMP)',
                      prefixIcon: Icon(Icons.calendar_month),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _lastMenstrualPeriod != null
                              ? DateFormat('MMM dd, yyyy').format(_lastMenstrualPeriod!)
                              : 'Tap to select',
                          style: TextStyle(
                            color: _lastMenstrualPeriod != null ? null : Colors.grey.shade500,
                          ),
                        ),
                        if (_lastMenstrualPeriod != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'GA: $_gestationalWeeks weeks | EDD: ${DateFormat('MMM dd, yyyy').format(_expectedDeliveryDate!)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.pink.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: _gravida?.toString(),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          labelText: 'Gravida (G)',
                          hintText: 'Total pregnancies',
                        ),
                        onChanged: (v) => _gravida = int.tryParse(v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        initialValue: _parity?.toString(),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          labelText: 'Parity (P)',
                          hintText: 'Live births',
                        ),
                        onChanged: (v) => _parity = int.tryParse(v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                SwitchListTile(
                  value: _isHighRisk,
                  onChanged: (v) => setState(() => _isHighRisk = v),
                  title: const Text('High-Risk Pregnancy'),
                  subtitle: const Text('Previous complications, medical conditions, etc.'),
                  contentPadding: EdgeInsets.zero,
                ),
                
                if (_isHighRisk) ...[
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _highRiskFactorsCtrl,
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'High Risk Factors',
                      hintText: 'e.g., Previous C-section, Preeclampsia, Diabetes',
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 24),
            ],

            // Submit button
            Consumer<PatientProvider>(
              builder: (_, prov, __) => FilledButton.icon(
                onPressed: prov.isLoading ? null : _submit,
                icon: prov.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.person_add),
                label: Text(
                  prov.isLoading ? 'Registering...' : 'Register Patient',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
