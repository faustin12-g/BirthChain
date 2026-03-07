/// Complete medical record with all structured fields
class MedicalRecord {
  final String id;
  final String clientId;
  final String providerId;
  final String createdAt;
  final String clientName;
  final String providerName;

  // Record Classification
  final String recordType;
  final DateTime? visitDate;
  final String facilityName;

  // Clinical Information
  final String chiefComplaint;
  final String symptoms;
  final String examination;
  final String diagnosis;
  final String? secondaryDiagnoses;
  final String treatment;

  // Vital Signs
  final String? bloodPressure;
  final int? pulseRate;
  final double? temperature;
  final double? weight;
  final double? height;
  final int? oxygenSaturation;
  final int? respiratoryRate;

  // Maternal Health Fields
  final int? gestationalWeeks;
  final int? gestationalDays;
  final double? fundalHeight;
  final int? fetalHeartRate;
  final String? fetalPresentation;
  final String? fetalMovement;
  final String? deliveryMode;
  final String? birthOutcome;
  final int? babyWeightGrams;
  final int? apgarScore1Min;
  final int? apgarScore5Min;

  // Medications & Lab Tests
  final String? medications;
  final String? labTests;
  final String? immunizations;

  // Plan & Follow-up
  final String? careInstructions;
  final bool followUpRequired;
  final DateTime? followUpDate;
  final String? referralTo;
  final String? notes;

  // Legacy field
  final String description;

  MedicalRecord({
    required this.id,
    required this.clientId,
    required this.providerId,
    required this.createdAt,
    required this.clientName,
    required this.providerName,
    this.recordType = 'Consultation',
    this.visitDate,
    this.facilityName = '',
    this.chiefComplaint = '',
    this.symptoms = '',
    this.examination = '',
    this.diagnosis = '',
    this.secondaryDiagnoses,
    this.treatment = '',
    this.bloodPressure,
    this.pulseRate,
    this.temperature,
    this.weight,
    this.height,
    this.oxygenSaturation,
    this.respiratoryRate,
    this.gestationalWeeks,
    this.gestationalDays,
    this.fundalHeight,
    this.fetalHeartRate,
    this.fetalPresentation,
    this.fetalMovement,
    this.deliveryMode,
    this.birthOutcome,
    this.babyWeightGrams,
    this.apgarScore1Min,
    this.apgarScore5Min,
    this.medications,
    this.labTests,
    this.immunizations,
    this.careInstructions,
    this.followUpRequired = false,
    this.followUpDate,
    this.referralTo,
    this.notes,
    this.description = '',
  });

  /// Get gestational age as readable string
  String get gestationalAge {
    if (gestationalWeeks == null) return '';
    final days = gestationalDays ?? 0;
    return '$gestationalWeeks weeks ${days > 0 ? "$days days" : ""}';
  }

  /// Check if this is a maternal health record
  bool get isMaternal => recordType == 'AntenatalVisit' || recordType == 'Delivery';

  /// Get formatted vital signs as list
  List<String> get vitalSignsList {
    final List<String> signs = [];
    if (bloodPressure != null && bloodPressure!.isNotEmpty) {
      signs.add('BP: $bloodPressure mmHg');
    }
    if (pulseRate != null) signs.add('Pulse: $pulseRate bpm');
    if (temperature != null) signs.add('Temp: ${temperature!.toStringAsFixed(1)}°C');
    if (weight != null) signs.add('Weight: ${weight!.toStringAsFixed(1)} kg');
    if (height != null) signs.add('Height: ${height!.toStringAsFixed(1)} cm');
    if (oxygenSaturation != null) signs.add('SpO2: $oxygenSaturation%');
    if (respiratoryRate != null) signs.add('RR: $respiratoryRate /min');
    return signs;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Backward-compatible getters for existing code
  // ═══════════════════════════════════════════════════════════════════════

  /// Alias for diagnosis (backward compatibility)
  String get details => diagnosis.isNotEmpty ? diagnosis : chiefComplaint;

  /// Alias for medications (backward compatibility)
  String get medication => medications ?? '';

  /// Get event date as string (backward compatibility)
  String get eventDate {
    if (visitDate != null) {
      return visitDate!.toIso8601String();
    }
    return createdAt;
  }

  factory MedicalRecord.fromJson(Map<String, dynamic> json) => MedicalRecord(
    id: json['id'] ?? '',
    clientId: json['clientId'] ?? '',
    providerId: json['providerId'] ?? '',
    createdAt: json['createdAt'] ?? '',
    clientName: json['clientName'] ?? '',
    providerName: json['providerName'] ?? '',
    recordType: json['recordType'] ?? 'Consultation',
    visitDate: json['visitDate'] != null ? DateTime.tryParse(json['visitDate']) : null,
    facilityName: json['facilityName'] ?? '',
    chiefComplaint: json['chiefComplaint'] ?? '',
    symptoms: json['symptoms'] ?? '',
    examination: json['examination'] ?? '',
    diagnosis: json['diagnosis'] ?? '',
    secondaryDiagnoses: json['secondaryDiagnoses'],
    treatment: json['treatment'] ?? '',
    bloodPressure: json['bloodPressure'],
    pulseRate: json['pulseRate'],
    temperature: json['temperature']?.toDouble(),
    weight: json['weight']?.toDouble(),
    height: json['height']?.toDouble(),
    oxygenSaturation: json['oxygenSaturation'],
    respiratoryRate: json['respiratoryRate'],
    gestationalWeeks: json['gestationalWeeks'],
    gestationalDays: json['gestationalDays'],
    fundalHeight: json['fundalHeight']?.toDouble(),
    fetalHeartRate: json['fetalHeartRate'],
    fetalPresentation: json['fetalPresentation'],
    fetalMovement: json['fetalMovement'],
    deliveryMode: json['deliveryMode'],
    birthOutcome: json['birthOutcome'],
    babyWeightGrams: json['babyWeightGrams'],
    apgarScore1Min: json['apgarScore1Min'],
    apgarScore5Min: json['apgarScore5Min'],
    medications: json['medications'],
    labTests: json['labTests'],
    immunizations: json['immunizations'],
    careInstructions: json['careInstructions'],
    followUpRequired: json['followUpRequired'] ?? false,
    followUpDate: json['followUpDate'] != null ? DateTime.tryParse(json['followUpDate']) : null,
    referralTo: json['referralTo'],
    notes: json['notes'],
    description: json['description'] ?? '',
  );
}

/// Record type enum values
class RecordTypes {
  static const String consultation = 'Consultation';
  static const String antenatalVisit = 'AntenatalVisit';
  static const String delivery = 'Delivery';
  static const String immunization = 'Immunization';
  static const String labResult = 'LabResult';
  static const String prescription = 'Prescription';
  static const String chronicCareVisit = 'ChronicCareVisit';
  static const String emergency = 'Emergency';
  static const String referral = 'Referral';

  static const List<String> all = [
    consultation,
    antenatalVisit,
    delivery,
    immunization,
    labResult,
    prescription,
    chronicCareVisit,
    emergency,
    referral,
  ];

  static String getDisplayName(String type) {
    switch (type) {
      case consultation: return 'General Consultation';
      case antenatalVisit: return 'Antenatal Visit';
      case delivery: return 'Delivery';
      case immunization: return 'Immunization';
      case labResult: return 'Lab Result';
      case prescription: return 'Prescription';
      case chronicCareVisit: return 'Chronic Care Visit';
      case emergency: return 'Emergency';
      case referral: return 'Referral';
      default: return type;
    }
  }
}

/// Create record request with all structured fields
class CreateRecordRequest {
  final String clientId;
  
  // Record Classification
  final String recordType;
  final DateTime? visitDate;

  // Clinical Information
  final String chiefComplaint;
  final String symptoms;
  final String? examination;
  final String diagnosis;
  final String? secondaryDiagnoses;
  final String? treatment;

  // Vital Signs
  final String? bloodPressure;
  final int? pulseRate;
  final double? temperature;
  final double? weight;
  final double? height;
  final int? oxygenSaturation;
  final int? respiratoryRate;

  // Maternal Health Fields
  final int? gestationalWeeks;
  final int? gestationalDays;
  final double? fundalHeight;
  final int? fetalHeartRate;
  final String? fetalPresentation;
  final String? fetalMovement;
  final String? deliveryMode;
  final String? birthOutcome;
  final int? babyWeightGrams;
  final int? apgarScore1Min;
  final int? apgarScore5Min;

  // Medications & Lab Tests
  final String? medications;
  final String? labTests;
  final String? immunizations;

  // Plan & Follow-up
  final String? careInstructions;
  final bool followUpRequired;
  final DateTime? followUpDate;
  final String? referralTo;
  final String? notes;

  CreateRecordRequest({
    required this.clientId,
    this.recordType = 'Consultation',
    this.visitDate,
    this.chiefComplaint = '',
    this.symptoms = '',
    this.examination,
    this.diagnosis = '',
    this.secondaryDiagnoses,
    this.treatment,
    this.bloodPressure,
    this.pulseRate,
    this.temperature,
    this.weight,
    this.height,
    this.oxygenSaturation,
    this.respiratoryRate,
    this.gestationalWeeks,
    this.gestationalDays,
    this.fundalHeight,
    this.fetalHeartRate,
    this.fetalPresentation,
    this.fetalMovement,
    this.deliveryMode,
    this.birthOutcome,
    this.babyWeightGrams,
    this.apgarScore1Min,
    this.apgarScore5Min,
    this.medications,
    this.labTests,
    this.immunizations,
    this.careInstructions,
    this.followUpRequired = false,
    this.followUpDate,
    this.referralTo,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'clientId': clientId,
    'recordType': recordType,
    if (visitDate != null) 'visitDate': visitDate!.toUtc().toIso8601String(),
    'chiefComplaint': chiefComplaint,
    'symptoms': symptoms,
    if (examination != null) 'examination': examination,
    'diagnosis': diagnosis,
    if (secondaryDiagnoses != null) 'secondaryDiagnoses': secondaryDiagnoses,
    if (treatment != null) 'treatment': treatment,
    if (bloodPressure != null) 'bloodPressure': bloodPressure,
    if (pulseRate != null) 'pulseRate': pulseRate,
    if (temperature != null) 'temperature': temperature,
    if (weight != null) 'weight': weight,
    if (height != null) 'height': height,
    if (oxygenSaturation != null) 'oxygenSaturation': oxygenSaturation,
    if (respiratoryRate != null) 'respiratoryRate': respiratoryRate,
    if (gestationalWeeks != null) 'gestationalWeeks': gestationalWeeks,
    if (gestationalDays != null) 'gestationalDays': gestationalDays,
    if (fundalHeight != null) 'fundalHeight': fundalHeight,
    if (fetalHeartRate != null) 'fetalHeartRate': fetalHeartRate,
    if (fetalPresentation != null) 'fetalPresentation': fetalPresentation,
    if (fetalMovement != null) 'fetalMovement': fetalMovement,
    if (deliveryMode != null) 'deliveryMode': deliveryMode,
    if (birthOutcome != null) 'birthOutcome': birthOutcome,
    if (babyWeightGrams != null) 'babyWeightGrams': babyWeightGrams,
    if (apgarScore1Min != null) 'apgarScore1Min': apgarScore1Min,
    if (apgarScore5Min != null) 'apgarScore5Min': apgarScore5Min,
    if (medications != null) 'medications': medications,
    if (labTests != null) 'labTests': labTests,
    if (immunizations != null) 'immunizations': immunizations,
    if (careInstructions != null) 'careInstructions': careInstructions,
    'followUpRequired': followUpRequired,
    if (followUpDate != null) 'followUpDate': followUpDate!.toUtc().toIso8601String(),
    if (referralTo != null) 'referralTo': referralTo,
    if (notes != null) 'notes': notes,
  };
}

/// Reminder model for appointments
class Reminder {
  final String id;
  final String clientId;
  final String? providerId;
  final String reminderType;
  final String title;
  final String message;
  final DateTime scheduledDate;
  final int notifyBeforeMinutes;
  final bool isRecurring;
  final String? recurrencePattern;
  final String status;
  final DateTime? sentAt;
  final DateTime? completedAt;
  final String? facilityName;
  final String createdAt;

  Reminder({
    required this.id,
    required this.clientId,
    this.providerId,
    this.reminderType = 'Appointment',
    required this.title,
    required this.message,
    required this.scheduledDate,
    this.notifyBeforeMinutes = 1440,
    this.isRecurring = false,
    this.recurrencePattern,
    this.status = 'Pending',
    this.sentAt,
    this.completedAt,
    this.facilityName,
    required this.createdAt,
  });

  bool get isPending => status == 'Pending';
  bool get isCompleted => status == 'Completed';
  bool get isOverdue => isPending && scheduledDate.isBefore(DateTime.now());

  factory Reminder.fromJson(Map<String, dynamic> json) => Reminder(
    id: json['id'] ?? '',
    clientId: json['clientId'] ?? '',
    providerId: json['providerId'],
    reminderType: json['reminderType'] ?? 'Appointment',
    title: json['title'] ?? '',
    message: json['message'] ?? '',
    scheduledDate: DateTime.parse(json['scheduledDate']),
    notifyBeforeMinutes: json['notifyBeforeMinutes'] ?? 1440,
    isRecurring: json['isRecurring'] ?? false,
    recurrencePattern: json['recurrencePattern'],
    status: json['status'] ?? 'Pending',
    sentAt: json['sentAt'] != null ? DateTime.tryParse(json['sentAt']) : null,
    completedAt: json['completedAt'] != null ? DateTime.tryParse(json['completedAt']) : null,
    facilityName: json['facilityName'],
    createdAt: json['createdAt'] ?? '',
  );
}

/// Create reminder request
class CreateReminderRequest {
  final String clientId;
  final String reminderType;
  final String title;
  final String message;
  final DateTime scheduledDate;
  final int notifyBeforeMinutes;
  final bool isRecurring;
  final String? recurrencePattern;
  final String? facilityName;

  CreateReminderRequest({
    required this.clientId,
    this.reminderType = 'Appointment',
    required this.title,
    required this.message,
    required this.scheduledDate,
    this.notifyBeforeMinutes = 1440, // 24 hours
    this.isRecurring = false,
    this.recurrencePattern,
    this.facilityName,
  });

  Map<String, dynamic> toJson() => {
    'clientId': clientId,
    'reminderType': reminderType,
    'title': title,
    'message': message,
    'scheduledDate': scheduledDate.toUtc().toIso8601String(),
    'notifyBeforeMinutes': notifyBeforeMinutes,
    'isRecurring': isRecurring,
    if (recurrencePattern != null) 'recurrencePattern': recurrencePattern,
    if (facilityName != null) 'facilityName': facilityName,
  };
}

