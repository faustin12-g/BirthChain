import 'dart:convert';

class MedicalRecord {
  final String id;
  final String clientId;
  final String providerId;
  final String description;
  final String createdAt;
  final String clientName;
  final String providerName;

  MedicalRecord({
    required this.id,
    required this.clientId,
    required this.providerId,
    required this.description,
    required this.createdAt,
    required this.clientName,
    required this.providerName,
  });

  Map<String, dynamic>? _cache;

  Map<String, dynamic> get _parsed {
    _cache ??= _tryParse();
    return _cache!;
  }

  Map<String, dynamic> _tryParse() {
    try {
      final r = json.decode(description);
      if (r is Map<String, dynamic>) return r;
    } catch (_) {}
    return {};
  }

  /// Record type (Diagnosis, Medication, Vaccination, etc.)
  String get recordType => _parsed['type'] as String? ?? 'General';

  /// The medical details / notes
  String get details => _parsed['details'] as String? ?? description;

  /// Symptoms
  String get symptoms => _parsed['symptoms'] as String? ?? '';

  /// Medication prescribed
  String get medication => _parsed['medication'] as String? ?? '';

  /// Lab test results
  String get labTests => _parsed['labTests'] as String? ?? '';

  /// Additional notes
  String get notes => _parsed['notes'] as String? ?? '';

  /// Healthcare facility name
  String get facilityName => _parsed['facility'] as String? ?? '';

  /// Date of the medical event (not the record creation date)
  String get eventDate => _parsed['date'] as String? ?? createdAt;

  factory MedicalRecord.fromJson(Map<String, dynamic> json) => MedicalRecord(
    id: json['id'] ?? '',
    clientId: json['clientId'] ?? '',
    providerId: json['providerId'] ?? '',
    description: json['description'] ?? '',
    createdAt: json['createdAt'] ?? '',
    clientName: json['clientName'] ?? '',
    providerName: json['providerName'] ?? '',
  );
}

class CreateRecordRequest {
  final String clientId;
  final String diagnosis;
  final String symptoms;
  final String medication;
  final String labTests;
  final String notes;
  final String facilityName;
  final String eventDate;

  CreateRecordRequest({
    required this.clientId,
    required this.diagnosis,
    this.symptoms = '',
    this.medication = '',
    this.labTests = '',
    this.notes = '',
    this.facilityName = '',
    this.eventDate = '',
  });

  Map<String, dynamic> toJson() => {
    'clientId': clientId,
    'description': json.encode({
      'type': 'Consultation',
      'details': diagnosis,
      'symptoms': symptoms,
      'medication': medication,
      'labTests': labTests,
      'notes': notes,
      'facility': facilityName,
      'date': eventDate,
    }),
  };
}
