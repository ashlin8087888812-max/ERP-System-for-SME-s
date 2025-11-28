import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'services/api_client.dart';
import 'services/auth_storage.dart';
import 'repositories/auth_repository.dart';
import 'repositories/contacts_repository.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // External
  sl.registerLazySingleton(() => const FlutterSecureStorage());

  // Core
  sl.registerLazySingleton(() => AuthStorage(sl()));
  sl.registerLazySingleton(() => ApiClient(sl()));
  sl.registerLazySingleton(() => sl<ApiClient>().dio);

  // Features - Auth
  sl.registerLazySingleton(() => AuthRepository(sl(), sl()));

  // Modules - Contacts
  sl.registerLazySingleton(() => ContactsRepository(sl<ApiClient>()));

}
