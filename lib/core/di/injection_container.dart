import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/crm/data/datasources/lead_remote_data_source.dart';
import '../../features/crm/data/repositories/lead_repository_impl.dart';
import '../../features/crm/domain/repositories/lead_repository.dart';
import '../../features/crm/presentation/bloc/lead_bloc.dart';
import '../../features/crm/presentation/bloc/lead_detail_bloc.dart';

/// The global Service Locator instance.
final sl = GetIt.instance;

/// Initialize all app dependencies.
Future<void> initDI() async {
  // External Clients
  sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);

  // ─── Auth ──────────────────────────────────────────────────────────
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl<SupabaseClient>()),
  );
  sl.registerFactory<AuthBloc>(
    () => AuthBloc(authRepository: sl<AuthRepository>()),
  );

  // ─── CRM Data Sources & Repositories ──────────────────────────────
  sl.registerLazySingleton<LeadRemoteDataSource>(
    () => LeadRemoteDataSourceImpl(sl<SupabaseClient>()),
  );
  sl.registerLazySingleton<LeadRepository>(
    () => LeadRepositoryImpl(sl<LeadRemoteDataSource>()),
  );

  // ─── CRM Blocs ─────────────────────────────────────────────────────
  // Singleton LeadBloc ensures all screens (List, Add, Detail, Dashboard) share the same live state
  sl.registerLazySingleton<LeadBloc>(
    () => LeadBloc(leadRepository: sl<LeadRepository>()),
  );
  sl.registerFactory<LeadDetailBloc>(
    () => LeadDetailBloc(
      leadRepository: sl<LeadRepository>(),
      leadBloc: sl<LeadBloc>(),
    ),
  );
}
