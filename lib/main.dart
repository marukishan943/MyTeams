import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/supabase_config.dart';
import 'core/di/injection_container.dart';
import 'core/router/app_router.dart';
import 'core/services/supabase_keep_alive_service.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.anonKey,
  );

  // Ping Supabase to refresh activity status
  SupabaseKeepAliveService.ping();

  await initDI();

  runApp(const MyTeamsApp());
}

class MyTeamsApp extends StatelessWidget {
  const MyTeamsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>(
      create: (context) => sl<AuthBloc>(),
      child: MaterialApp.router(
        title: 'MY TEAMS',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: appRouter,
      ),
    );
  }
}

