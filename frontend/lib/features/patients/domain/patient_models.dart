class Patient {
  final String id;
  final String fullName;
  final String phone;
  final String dateOfBirth;
  final String qrCodeId;
  final String createdAt;

  Patient({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.dateOfBirth,
    required this.qrCodeId,
    required this.createdAt,
  });

  factory Patient.fromJson(Map<String, dynamic> json) => Patient(
    id: json['id'] ?? '',
    fullName: json['fullName'] ?? '',
    phone: json['phone'] ?? '',
    dateOfBirth: json['dateOfBirth'] ?? '',
    qrCodeId: json['qrCodeId'] ?? '',
    createdAt: json['createdAt'] ?? '',
  );
}

class CreatePatientRequest {
  final String fullName;
  final String phone;
  final String dateOfBirth;

  CreatePatientRequest({
    required this.fullName,
    required this.phone,
    required this.dateOfBirth,
  });

  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'phone': phone,
    'dateOfBirth': dateOfBirth,
  };
}
