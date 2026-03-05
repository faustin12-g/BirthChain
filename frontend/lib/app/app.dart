import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../di/injection.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/presentation/auth_provider.dart';
import '../features/patients/data/patient_repository.dart';
import '../features/patients/presentation/patient_provider.dart';
import '../features/records/data/record_repository.dart';
import '../features/records/presentation/record_provider.dart';
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
      ],
      child: Consumer<AuthProvider>(
        builder:
            (_, auth, __) => MaterialApp(
              title: 'BirthChain',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              initialRoute:
                  auth.isLoggedIn ? AppRoutes.dashboard : AppRoutes.login,
              onGenerateRoute: AppRoutes.onGenerateRoute,
            ),
      ),
    );
  }
}
