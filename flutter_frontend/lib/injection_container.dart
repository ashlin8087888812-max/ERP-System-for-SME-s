import 'package:get_it/get_it.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'services/api_client.dart';
import 'services/websocket_service.dart';
import 'services/auth_storage.dart';
import 'repositories/auth_repository.dart';
import 'repositories/contacts_repository.dart';
import 'repositories/threads_repository.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // External - Secure Storage with platform-specific encryption
  sl.registerLazySingleton(
    () => const FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
        resetOnError: true,
      ),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
        accountName: 'Syncerity',
      ),
      webOptions: WebOptions(
        dbName: 'SynceritySecureStorage',
        publicKey: 'SyncerityPublicKey',
      ),
    ),
  );

  // Core
  sl.registerLazySingleton(() => AuthStorage(sl()));
  sl.registerLazySingleton(() => WebSocketService(authStorage: sl()));
  sl.registerLazySingleton(() => ApiClient(sl()));
  sl.registerLazySingleton(() => sl<ApiClient>().dio);

  // Features - Auth
  sl.registerLazySingleton(() => AuthRepository(sl(), sl()));

  // Modules - Contacts
  sl.registerLazySingleton(() => ContactsRepository(sl<ApiClient>()));
  sl.registerLazySingleton(() => ThreadsRepository(sl<ApiClient>()));
}
