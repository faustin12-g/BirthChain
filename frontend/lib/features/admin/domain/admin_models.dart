// ══════════════════════════════════════════════════════════════════════════════
// DASHBOARD
// ══════════════════════════════════════════════════════════════════════════════

class DashboardStats {
  final int totalFacilities;
  final int activeFacilities;
  final int totalUsers;
  final int activeUsers;
  final int totalProviders;
  final int totalPatients;
  final int totalRecords;

  DashboardStats({
    required this.totalFacilities,
    required this.activeFacilities,
    required this.totalUsers,
    required this.activeUsers,
    required this.totalProviders,
    required this.totalPatients,
    required this.totalRecords,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) => DashboardStats(
    totalFacilities: json['totalFacilities'] ?? 0,
    activeFacilities: json['activeFacilities'] ?? 0,
    totalUsers: json['totalUsers'] ?? 0,
    activeUsers: json['activeUsers'] ?? 0,
    totalProviders: json['totalProviders'] ?? 0,
    totalPatients: json['totalPatients'] ?? 0,
    totalRecords: json['totalRecords'] ?? 0,
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// FACILITY
// ══════════════════════════════════════════════════════════════════════════════

class FacilityDetail {
  final String id;
  final String name;
  final String address;
  final String phone;
  final String email;
  final bool isActive;
  final DateTime createdAt;
  final int providerCount;
  final int userCount;

  FacilityDetail({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.email,
    required this.isActive,
    required this.createdAt,
    required this.providerCount,
    required this.userCount,
  });

  factory FacilityDetail.fromJson(Map<String, dynamic> json) => FacilityDetail(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    address: json['address'] ?? '',
    phone: json['phone'] ?? '',
    email: json['email'] ?? '',
    isActive: json['isActive'] ?? true,
    createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    providerCount: json['providerCount'] ?? 0,
    userCount: json['userCount'] ?? 0,
  );
}

class UpdateFacilityRequest {
  final String? name;
  final String? address;
  final String? phone;
  final String? email;

  UpdateFacilityRequest({this.name, this.address, this.phone, this.email});

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (name != null) map['name'] = name;
    if (address != null) map['address'] = address;
    if (phone != null) map['phone'] = phone;
    if (email != null) map['email'] = email;
    return map;
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// USER
// ══════════════════════════════════════════════════════════════════════════════

class UserDetail {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final String? phone;
  final String? profileImageUrl;
  final bool isActive;
  final bool isEmailVerified;
  final DateTime createdAt;
  final String? facilityId;
  final String? facilityName;

  UserDetail({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.phone,
    this.profileImageUrl,
    required this.isActive,
    required this.isEmailVerified,
    required this.createdAt,
    this.facilityId,
    this.facilityName,
  });

  factory UserDetail.fromJson(Map<String, dynamic> json) => UserDetail(
    id: json['id'] ?? '',
    fullName: json['fullName'] ?? '',
    email: json['email'] ?? '',
    role: json['role'] ?? '',
    phone: json['phone'],
    profileImageUrl: json['profileImageUrl'],
    isActive: json['isActive'] ?? true,
    isEmailVerified: json['isEmailVerified'] ?? false,
    createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    facilityId: json['facilityId'],
    facilityName: json['facilityName'],
  );
}

class UpdateUserRequest {
  final String? fullName;
  final String? phone;
  final String? role;
  final String? facilityId;

  UpdateUserRequest({this.fullName, this.phone, this.role, this.facilityId});

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (fullName != null) map['fullName'] = fullName;
    if (phone != null) map['phone'] = phone;
    if (role != null) map['role'] = role;
    if (facilityId != null) map['facilityId'] = facilityId;
    return map;
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PROVIDER
// ══════════════════════════════════════════════════════════════════════════════

class ProviderDetail {
  final String id;
  final String userId;
  final String fullName;
  final String email;
  final String? phone;
  final String? profileImageUrl;
  final String licenseNumber;
  final String specialty;
  final String facilityId;
  final String facilityName;
  final bool isActive;
  final DateTime createdAt;

  ProviderDetail({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.email,
    this.phone,
    this.profileImageUrl,
    required this.licenseNumber,
    required this.specialty,
    required this.facilityId,
    required this.facilityName,
    required this.isActive,
    required this.createdAt,
  });

  factory ProviderDetail.fromJson(Map<String, dynamic> json) => ProviderDetail(
    id: json['id'] ?? '',
    userId: json['userId'] ?? '',
    fullName: json['fullName'] ?? '',
    email: json['email'] ?? '',
    phone: json['phone'],
    profileImageUrl: json['profileImageUrl'],
    licenseNumber: json['licenseNumber'] ?? '',
    specialty: json['specialty'] ?? '',
    facilityId: json['facilityId'] ?? '',
    facilityName: json['facilityName'] ?? '',
    isActive: json['isActive'] ?? true,
    createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
  );
}

class UpdateProviderRequest {
  final String? fullName;
  final String? phone;
  final String? licenseNumber;
  final String? specialty;

  UpdateProviderRequest({
    this.fullName,
    this.phone,
    this.licenseNumber,
    this.specialty,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (fullName != null) map['fullName'] = fullName;
    if (phone != null) map['phone'] = phone;
    if (licenseNumber != null) map['licenseNumber'] = licenseNumber;
    if (specialty != null) map['specialty'] = specialty;
    return map;
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PROFILE
// ══════════════════════════════════════════════════════════════════════════════

class UpdateProfileRequest {
  final String? fullName;
  final String? phone;

  UpdateProfileRequest({this.fullName, this.phone});

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (fullName != null) map['fullName'] = fullName;
    if (phone != null) map['phone'] = phone;
    return map;
  }
}

class ProfileImageRequest {
  final String base64Image;
  final String contentType;

  ProfileImageRequest({required this.base64Image, required this.contentType});

  Map<String, dynamic> toJson() => {
    'base64Image': base64Image,
    'contentType': contentType,
  };
}

class ChangePasswordRequest {
  final String currentPassword;
  final String newPassword;

  ChangePasswordRequest({
    required this.currentPassword,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() => {
    'currentPassword': currentPassword,
    'newPassword': newPassword,
  };
}
