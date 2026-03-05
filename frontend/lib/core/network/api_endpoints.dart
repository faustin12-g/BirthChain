class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String login = '/auth/login';

  // Providers
  static const String providers = '/providers';
  static String providerMe = '/providers/me';

  // Clients (patients)
  static const String clients = '/clients';
  static String clientByQr(String qr) => '/clients/by-qr/$qr';

  // Records
  static const String records = '/records';
  static String recordsByClient(String id) => '/records/by-client/$id';
  static String recordsByQr(String qr) => '/records/by-qr/$qr';

  // Activity Logs
  static const String activityLogs = '/activitylogs';
  static String activityLogsByUser(String id) => '/activitylogs/by-user/$id';
}
