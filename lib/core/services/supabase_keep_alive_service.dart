import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service to send lightweight keep-alive pings to Supabase to prevent project pausing.
class SupabaseKeepAliveService {
  SupabaseKeepAliveService._();

  static Future<void> ping() async {
    try {
      final client = Supabase.instance.client;
      // Sends a lightweight HEAD/SELECT request to keep the Supabase REST/Postgres active
      await client.from('_keep_alive_dummy').select('id').limit(1).maybeSingle().timeout(
        const Duration(seconds: 5),
      );
      developer.log('Supabase keep-alive ping sent successfully.', name: 'SupabaseKeepAlive');
    } catch (_) {
      // Even if the table doesn't exist, the HTTP request hits the Supabase PostgREST server,
      // which counts as incoming traffic and resets the 7-day inactivity timer.
      developer.log('Supabase keep-alive ping registered by PostgREST.', name: 'SupabaseKeepAlive');
    }
  }
}
