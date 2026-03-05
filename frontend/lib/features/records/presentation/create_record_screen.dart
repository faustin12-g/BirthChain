import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../patients/domain/patient_models.dart';
import '../domain/record_models.dart';
import 'record_provider.dart';
import 'record_type_helper.dart';

class CreateRecordScreen extends StatefulWidget {
  final Patient patient;
  const CreateRecordScreen({super.key, required this.patient});

  @override
  State<CreateRecordScreen> createState() => _CreateRecordScreenState();
}

class _CreateRecordScreenState extends State<CreateRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _facilityCtrl = TextEditingController();
  String _selectedType = RecordTypeHelper.types.first;
  DateTime _eventDate = DateTime.now();

  @override
  void dispose() {
    _descCtrl.dispose();
    _facilityCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _eventDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final prov = context.read<RecordProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final record = await prov.create(
      CreateRecordRequest(
        clientId: widget.patient.id,
        recordType: _selectedType,
        details: _descCtrl.text.trim(),
        facilityName: _facilityCtrl.text.trim(),
        eventDate:
            '${_eventDate.year}-${_eventDate.month.toString().padLeft(2, '0')}-${_eventDate.day.toString().padLeft(2, '0')}',
      ),
    );

    if (record != null && mounted) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Record added successfully.')),
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

    return Scaffold(
      appBar: AppBar(title: const Text('Add Medical Record')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Patient card
              Card(
                color: theme.colorScheme.primary.withAlpha(15),
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(widget.patient.fullName),
                  subtitle: Text(widget.patient.qrCodeId),
                ),
              ),
              const SizedBox(height: 20),

              // Record type dropdown
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Record Type',
                  prefixIcon: Icon(Icons.category),
                ),
                items:
                    RecordTypeHelper.types
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                onChanged: (v) => setState(() => _selectedType = v!),
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Diagnosis or treatment details...',
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 50),
                    child: Icon(Icons.notes),
                  ),
                ),
                validator:
                    (v) =>
                        v == null || v.trim().isEmpty
                            ? 'Details are required'
                            : null,
              ),
              const SizedBox(height: 16),

              // Facility name
              TextFormField(
                controller: _facilityCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Facility Name',
                  prefixIcon: Icon(Icons.local_hospital_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // Date picker
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(
                    '${_eventDate.year}-${_eventDate.month.toString().padLeft(2, '0')}-${_eventDate.day.toString().padLeft(2, '0')}',
                  ),
                ),
              ),
              const SizedBox(height: 28),

              Consumer<RecordProvider>(
                builder:
                    (_, prov, __) => FilledButton(
                      onPressed: prov.isLoading ? null : _submit,
                      child:
                          prov.isLoading
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : const Text(
                                'Add Record',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
