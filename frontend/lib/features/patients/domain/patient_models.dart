/// Patient category enum values
class PatientCategories {
  static const String general = 'General';
  static const String maternal = 'Maternal';
  static const String chronicDisease = 'ChronicDisease';
  static const String pediatric = 'Pediatric';
  static const String emergency = 'Emergency';

  static const List<String> all = [
    general,
    maternal,
    chronicDisease,
    pediatric,
    emergency,
  ];

  static String getDisplayName(String category) {
    switch (category) {
      case general: return 'General Patient';
      case maternal: return 'Maternal Health';
      case chronicDisease: return 'Chronic Disease';
      case pediatric: return 'Pediatric';
      case emergency: return 'Emergency';
      default: return category;
    }
  }
}

class Patient {
  final String id;
  final String fullName;
  final String phone;
  final String email;
  final String gender;
  final String address;
  final String dateOfBirth;
  final String qrCodeId;
  final String createdAt;
  final String? userId;

  // Medical Profile
  final String patientCategory;
  final String? bloodType;
  final String? allergies;
  final String? chronicConditions;
  final String? emergencyContactName;
  final String? emergencyContactPhone;

  // Maternal Health
  final bool isPregnant;
  final DateTime? lastMenstrualPeriod;
  final DateTime? expectedDeliveryDate;
  final int? gravida;
  final int? parity;
  final bool isHighRiskPregnancy;
  final String? highRiskFactors;

  Patient({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.gender,
    required this.address,
    required this.dateOfBirth,
    required this.qrCodeId,
    required this.createdAt,
    this.userId,
    this.patientCategory = 'General',
    this.bloodType,
    this.allergies,
    this.chronicConditions,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.isPregnant = false,
    this.lastMenstrualPeriod,
    this.expectedDeliveryDate,
    this.gravida,
    this.parity,
    this.isHighRiskPregnancy = false,
    this.highRiskFactors,
  });

  /// Check if patient is a maternal health patient
  bool get isMaternal => patientCategory == PatientCategories.maternal || isPregnant;

  /// Get obstetric history as string (Gravida/Para format)
  String get obstetricHistory {
    if (gravida == null && parity == null) return '';
    return 'G${gravida ?? 0}P${parity ?? 0}';
  }

  /// Get gestational age in weeks (if pregnant)
  int? get gestationalWeeks {
    if (!isPregnant || lastMenstrualPeriod == null) return null;
    return DateTime.now().difference(lastMenstrualPeriod!).inDays ~/ 7;
  }

  /// Get gestational age as readable string
  String get gestationalAge {
    final weeks = gestationalWeeks;
    if (weeks == null) return '';
    final days = DateTime.now().difference(lastMenstrualPeriod!).inDays % 7;
    return '$weeks weeks ${days > 0 ? "$days days" : ""}';
  }

  /// Get days until expected delivery
  int? get daysUntilDelivery {
    if (!isPregnant || expectedDeliveryDate == null) return null;
    return expectedDeliveryDate!.difference(DateTime.now()).inDays;
  }

  /// Get formatted allergies as list
  List<String> get allergyList {
    if (allergies == null || allergies!.isEmpty) return [];
    return allergies!.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  /// Get chronic conditions as list
  List<String> get conditionList {
    if (chronicConditions == null || chronicConditions!.isEmpty) return [];
    return chronicConditions!.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  /// Get high risk factors as list
  List<String> get riskFactorList {
    if (highRiskFactors == null || highRiskFactors!.isEmpty) return [];
    return highRiskFactors!.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  factory Patient.fromJson(Map<String, dynamic> json) => Patient(
    id: json['id'] ?? '',
    fullName: json['fullName'] ?? '',
    phone: json['phone'] ?? '',
    email: json['email'] ?? '',
    gender: json['gender'] ?? '',
    address: json['address'] ?? '',
    dateOfBirth: json['dateOfBirth'] ?? '',
    qrCodeId: json['qrCodeId'] ?? '',
    createdAt: json['createdAt'] ?? '',
    userId: json['userId'],
    patientCategory: json['patientCategory'] ?? 'General',
    bloodType: json['bloodType'],
    allergies: json['allergies'],
    chronicConditions: json['chronicConditions'],
    emergencyContactName: json['emergencyContactName'],
    emergencyContactPhone: json['emergencyContactPhone'],
    isPregnant: json['isPregnant'] ?? false,
    lastMenstrualPeriod: json['lastMenstrualPeriod'] != null 
        ? DateTime.tryParse(json['lastMenstrualPeriod']) 
        : null,
    expectedDeliveryDate: json['expectedDeliveryDate'] != null 
        ? DateTime.tryParse(json['expectedDeliveryDate']) 
        : null,
    gravida: json['gravida'],
    parity: json['parity'],
    isHighRiskPregnancy: json['isHighRiskPregnancy'] ?? false,
    highRiskFactors: json['highRiskFactors'],
  );
}

/// Limited patient info returned from QR code lookup
class PatientLookup {
  final String id;
  final String fullName;
  final String qrCodeId;
  final bool hasPinSet;
  final bool requiresPin;
  final String patientCategory;
  final bool isPregnant;

  PatientLookup({
    required this.id,
    required this.fullName,
    required this.qrCodeId,
    required this.hasPinSet,
    required this.requiresPin,
    this.patientCategory = 'General',
    this.isPregnant = false,
  });

  bool get isMaternal => patientCategory == PatientCategories.maternal || isPregnant;

  factory PatientLookup.fromJson(Map<String, dynamic> json) => PatientLookup(
    id: json['id'] ?? '',
    fullName: json['fullName'] ?? '',
    qrCodeId: json['qrCodeId'] ?? '',
    hasPinSet: json['hasPinSet'] ?? false,
    requiresPin: json['requiresPin'] ?? json['hasPinSet'] ?? false,
    patientCategory: json['patientCategory'] ?? 'General',
    isPregnant: json['isPregnant'] ?? false,
  );
}

class CreatePatientRequest {
  final String fullName;
  final String phone;
  final String email;
  final String gender;
  final String address;
  final String dateOfBirth;

  // Medical Profile
  final String patientCategory;
  final String? bloodType;
  final String? allergies;
  final String? chronicConditions;
  final String? emergencyContactName;
  final String? emergencyContactPhone;

  // Maternal Health (for pregnant women)
  final bool isPregnant;
  final DateTime? lastMenstrualPeriod;
  final DateTime? expectedDeliveryDate;
  final int? gravida;
  final int? parity;
  final bool isHighRiskPregnancy;
  final String? highRiskFactors;

  CreatePatientRequest({
    required this.fullName,
    required this.phone,
    required this.email,
    required this.gender,
    required this.address,
    required this.dateOfBirth,
    this.patientCategory = 'General',
    this.bloodType,
    this.allergies,
    this.chronicConditions,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.isPregnant = false,
    this.lastMenstrualPeriod,
    this.expectedDeliveryDate,
    this.gravida,
    this.parity,
    this.isHighRiskPregnancy = false,
    this.highRiskFactors,
  });

  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'phone': phone,
    'email': email,
    'gender': gender,
    'address': address,
    'dateOfBirth': dateOfBirth,
    'patientCategory': patientCategory,
    if (bloodType != null) 'bloodType': bloodType,
    if (allergies != null) 'allergies': allergies,
    if (chronicConditions != null) 'chronicConditions': chronicConditions,
    if (emergencyContactName != null) 'emergencyContactName': emergencyContactName,
    if (emergencyContactPhone != null) 'emergencyContactPhone': emergencyContactPhone,
    'isPregnant': isPregnant,
    if (lastMenstrualPeriod != null) 'lastMenstrualPeriod': lastMenstrualPeriod!.toUtc().toIso8601String(),
    if (expectedDeliveryDate != null) 'expectedDeliveryDate': expectedDeliveryDate!.toUtc().toIso8601String(),
    if (gravida != null) 'gravida': gravida,
    if (parity != null) 'parity': parity,
    'isHighRiskPregnancy': isHighRiskPregnancy,
    if (highRiskFactors != null) 'highRiskFactors': highRiskFactors,
  };
}

