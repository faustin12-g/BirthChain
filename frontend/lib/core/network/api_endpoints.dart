class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String sendOtp = '/auth/send-otp';
  static const String verifyEmail = '/auth/verify-email';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';

  // Facilities
  static const String facilities = '/facilities';
  static String facilityById(String id) => '/facilities/$id';
  static const String facilityAdmins = '/facilities/admins';

  // Providers
  static const String providers = '/providers';
  static String providerMe = '/providers/me';
  static String providersByFacility(String id) => '/providers/by-facility/$id';

  // Clients (patients)
  static const String clients = '/clients';
  static const String clientMe = '/clients/me';
  static String clientByQr(String qr) => '/clients/by-qr/$qr';
  static String clientSearch(String query) => '/clients/search?q=$query';

  // Records
  static const String records = '/records';
  static const String myRecords = '/records/my';
  static String recordsByClient(String id) => '/records/by-client/$id';
  static String recordsByQr(String qr) => '/records/by-qr/$qr';

  // Activity Logs
  static const String activityLogs = '/activitylogs';
  static String activityLogsByUser(String id) => '/activitylogs/by-user/$id';

  // Admin
  static const String adminStats = '/admin/stats';
  static const String adminUsers = '/admin/users';
  static String adminUserById(String id) => '/admin/users/$id';
  static String adminToggleActive(String id) => '/admin/users/$id/toggle-active';
}
