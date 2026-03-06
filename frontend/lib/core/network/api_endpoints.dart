class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String sendOtp = '/auth/send-otp';
  static const String verifyEmail = '/auth/verify-email';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';

  // Profile
  static const String profile = '/profile';
  static const String profileImage = '/profile/image';
  static const String profilePassword = '/profile/password';

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

  // Admin - Dashboard
  static const String adminDashboard = '/admin/dashboard';
  static const String adminStats = '/admin/dashboard';

  // Admin - Facility Management
  static const String adminFacilities = '/admin/facilities';
  static String adminFacilityById(String id) => '/admin/facilities/$id';
  static String adminActivateFacility(String id) =>
      '/admin/facilities/$id/activate';
  static String adminDeactivateFacility(String id) =>
      '/admin/facilities/$id/deactivate';
  static String adminDeleteFacility(String id) => '/admin/facilities/$id';

  // Admin - User Management
  static const String adminUsers = '/admin/users';
  static String adminUsersByRole(String role) => '/admin/users/role/$role';
  static String adminUserById(String id) => '/admin/users/$id';
  static String adminActivateUser(String id) => '/admin/users/$id/activate';
  static String adminDeactivateUser(String id) => '/admin/users/$id/deactivate';
  static String adminDeleteUser(String id) => '/admin/users/$id';

  // Admin - Provider Management
  static const String adminProviders = '/admin/providers';
  static String adminProvidersByFacility(String id) =>
      '/admin/providers/facility/$id';
  static String adminProviderById(String id) => '/admin/providers/$id';
  static String adminActivateProvider(String id) =>
      '/admin/providers/$id/activate';
  static String adminDeactivateProvider(String id) =>
      '/admin/providers/$id/deactivate';
  static String adminDeleteProvider(String id) => '/admin/providers/$id';

  // Facility Admin - Provider Management
  static const String facilityAdminMyFacility = '/facility-admin/my-facility';
  static const String facilityAdminProviders = '/facility-admin/providers';
  static String facilityAdminProviderById(String id) =>
      '/facility-admin/providers/$id';
  static String facilityAdminActivateProvider(String id) =>
      '/facility-admin/providers/$id/activate';
  static String facilityAdminDeactivateProvider(String id) =>
      '/facility-admin/providers/$id/deactivate';
  static String facilityAdminDeleteProvider(String id) =>
      '/facility-admin/providers/$id';

  // Notifications
  static const String notifications = '/notification';
  static const String notificationToken = '/notification/token';
  static String notificationMarkRead(String id) => '/notification/$id/read';
  static const String notificationMarkAllRead = '/notification/read-all';
}
