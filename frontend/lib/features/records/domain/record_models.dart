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
  final String recordType;
  final String details;
  final String facilityName;
  final String eventDate;

  CreateRecordRequest({
    required this.clientId,
    required this.recordType,
    required this.details,
    required this.facilityName,
    required this.eventDate,
  });

  Map<String, dynamic> toJson() => {
    'clientId': clientId,
    'description': json.encode({
      'type': recordType,
      'details': details,
      'facility': facilityName,
      'date': eventDate,
    }),
  };
}
