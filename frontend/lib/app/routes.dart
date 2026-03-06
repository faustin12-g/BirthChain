import 'package:flutter/material.dart';

import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/verify_email_screen.dart';
import 'admin_dashboard_screen.dart';
import 'dashboard_screen.dart';
import 'facility_admin_dashboard.dart';
import 'patient_dashboard_screen.dart';
import 'splash_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const verifyEmail = '/verify-email';
  static const forgotPassword = '/forgot-password';
  static const dashboard = '/dashboard';
  static const adminDashboard = '/admin-dashboard';
  static const facilityAdminDashboard = '/facility-admin-dashboard';
  static const patientDashboard = '/patient-dashboard';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case verifyEmail:
        final email = settings.arguments as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => VerifyEmailScreen(email: email),
        );
      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
      case dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      case adminDashboard:
        return MaterialPageRoute(builder: (_) => const AdminDashboardScreen());
      case facilityAdminDashboard:
        return MaterialPageRoute(
          builder: (_) => const FacilityAdminDashboard(),
        );
      case patientDashboard:
        return MaterialPageRoute(
          builder: (_) => const PatientDashboardScreen(),
        );
      default:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
    }
  }
}
