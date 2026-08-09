class SupabaseConfig {
  /// The Supabase Project URL.
  /// Can be configured during build with:
  /// `--dart-define=SUPABASE_URL=your_project_url`
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://tfmxyzrjvezfxurkkyhf.supabase.co',
  );

  /// The Supabase Anon Key.
  /// Can be configured during build with:
  /// `--dart-define=SUPABASE_ANON_KEY=your_anon_key`
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRmbXh5enJqdmV6Znh1cmtreWhmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM4NjExMTUsImV4cCI6MjA5OTQzNzExNX0.gaiWZwvoNvacRUH1em_lK9XLijoy9ImHNeM87P03YjU',
  );
}
