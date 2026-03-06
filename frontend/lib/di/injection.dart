import 'package:get_it/get_it.dart';
import '../core/network/api_client.dart';
import '../core/storage/secure_storage.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/patients/data/patient_repository.dart';
import '../features/records/data/record_repository.dart';
import '../features/admin/data/admin_repository.dart';
import '../features/admin/data/profile_repository.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  // Core
  getIt.registerLazySingleton<SecureStorageService>(
    () => SecureStorageService(),
  );
  getIt.registerLazySingleton<ApiClient>(
    () => ApiClient(getIt<SecureStorageService>()),
  );

  // Repositories
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepository(getIt<ApiClient>(), getIt<SecureStorageService>()),
  );
  getIt.registerLazySingleton<PatientRepository>(
    () => PatientRepository(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<RecordRepository>(
    () => RecordRepository(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<AdminRepository>(
    () => AdminRepository(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<FacilityAdminRepository>(
    () => FacilityAdminRepository(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<ProfileRepository>(
    () => ProfileRepository(getIt<ApiClient>()),
  );
}
