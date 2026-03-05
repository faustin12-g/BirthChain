class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

class RegisterRequest {
  final String fullName;
  final String email;
  final String password;
  final String phone;
  final String gender;
  final String address;
  final DateTime dateOfBirth;

  RegisterRequest({
    required this.fullName,
    required this.email,
    required this.password,
    required this.phone,
    required this.gender,
    required this.address,
    required this.dateOfBirth,
  });

  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'email': email,
    'password': password,
    'phone': phone,
    'gender': gender,
    'address': address,
    'dateOfBirth': dateOfBirth.toUtc().toIso8601String(),
  };
}

class LoginResponse {
  final String token;
  final String userId;
  final String email;
  final String fullName;
  final String role;
  final String expiresAt;

  LoginResponse({
    required this.token,
    required this.userId,
    required this.email,
    required this.fullName,
    required this.role,
    required this.expiresAt,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
    token: json['token'] ?? '',
    userId: json['userId'] ?? '',
    email: json['email'] ?? '',
    fullName: json['fullName'] ?? '',
    role: json['role'] ?? '',
    expiresAt: json['expiresAt'] ?? '',
  );
}
