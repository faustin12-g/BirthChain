import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../core/notifications/notification_service.dart';
import '../features/notifications/notification_provider.dart';
import '../di/injection.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/presentation/auth_provider.dart';
import '../features/patients/data/patient_repository.dart';
import '../features/patients/presentation/patient_provider.dart';
import '../features/records/data/record_repository.dart';
import '../features/records/presentation/record_provider.dart';
import '../features/admin/data/admin_repository.dart';
import '../features/admin/data/profile_repository.dart';
import '../features/admin/presentation/admin_provider.dart';
import '../features/admin/presentation/profile_provider.dart';
import '../features/pin/data/pin_repository.dart';
import '../features/pin/presentation/pin_provider.dart';
import 'routes.dart';
import 'theme.dart';

class BirthChainApp extends StatelessWidget {
  const BirthChainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(getIt<AuthRepository>())..checkSession(),
        ),
        ChangeNotifierProvider(
          create: (_) => PatientProvider(getIt<PatientRepository>()),
        ),
        ChangeNotifierProvider(
          create: (_) => RecordProvider(getIt<RecordRepository>()),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(getIt<Dio>()),
        ),
        ChangeNotifierProvider(
          create: (_) => AdminProvider(getIt<AdminRepository>()),
        ),
        ChangeNotifierProvider(
          create: (_) => ProfileProvider(getIt<ProfileRepository>()),
        ),
        ChangeNotifierProvider(
          create: (_) => PinProvider(getIt<PinRepository>()),
        ),
      ],
      child: Builder(
        builder: (context) {
          NotificationService.initialize(context);
          return Consumer<AuthProvider>(
            builder:
                (_, auth, __) => MaterialApp(
                  title: 'BirthChain',
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.lightTheme,
                  initialRoute: AppRoutes.splash,
                  onGenerateRoute: AppRoutes.onGenerateRoute,
                ),
          );
        },
      ),
    );
  }
}
