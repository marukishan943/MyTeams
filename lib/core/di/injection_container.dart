import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

/// The global Service Locator instance.
final sl = GetIt.instance;

/// Initialize all app dependencies.
Future<void> initDI() async {
  // External Clients
  sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);

  // Data Sources (Will be registered in future steps)
  
  // Repositories (Will be registered in Step 3)
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl<SupabaseClient>()),
  );

  // BLoCs / Cubits (Will be registered in Step 4)
  sl.registerFactory<AuthBloc>(
    () => AuthBloc(authRepository: sl<AuthRepository>()),
  );
}
