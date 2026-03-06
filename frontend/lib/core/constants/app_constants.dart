class AppConstants {
  AppConstants._();

  static const String appName = 'BirthChain';

  // Production URL - Railway deployment
  static const String apiBaseUrlProduction =
      'https://birthchain-production.up.railway.app/api';

  // Development URLs
  static const String apiBaseUrl =
      'http://10.0.2.2:5066/api'; // Android emulator → host
  static const String apiBaseUrlWindows = 'http://localhost:5066/api';

  // Set to true when using production server
  static const bool useProductionServer = true;
}
