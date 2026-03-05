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
  });

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
  );
}

class CreatePatientRequest {
  final String fullName;
  final String phone;
  final String email;
  final String gender;
  final String address;
  final String dateOfBirth;

  CreatePatientRequest({
    required this.fullName,
    required this.phone,
    required this.email,
    required this.gender,
    required this.address,
    required this.dateOfBirth,
  });

  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'phone': phone,
    'email': email,
    'gender': gender,
    'address': address,
    'dateOfBirth': dateOfBirth,
  };
}
