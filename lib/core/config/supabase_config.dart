import 'package:supabase_flutter/supabase_flutter.dart';

/// Build-time configuration, injected with `--dart-define-from-file=env.json`
/// (see `env.example.json`). Only PUBLIC values belong here: the Supabase URL and
/// anon key are designed to be public and are protected by Row Level Security.
/// Secret keys (e.g. the Groq key) must NEVER be added to the app — they live in
/// Supabase Edge Function secrets.
class AppEnv {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static void validate() {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw StateError(
        'Missing SUPABASE_URL / SUPABASE_ANON_KEY. Run with '
        '--dart-define-from-file=env.json (copy env.example.json to env.json).',
      );
    }
  }
}

class SupabaseConfig {
  static Future<void> initialize() async {
    AppEnv.validate();
    await Supabase.initialize(
      url: AppEnv.supabaseUrl,
      anonKey: AppEnv.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        autoRefreshToken: true,
      ),
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
  static GoTrueClient get auth => client.auth;
  static SupabaseStorageClient get storage => client.storage;
}
