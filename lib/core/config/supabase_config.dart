import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppEnv {
  static String get supabaseUrl {
    final v = dotenv.env['SUPABASE_URL'];
    assert(v != null && v.isNotEmpty, 'SUPABASE_URL missing from .env');
    return v ?? '';
  }

  static String get supabaseAnonKey {
    final v = dotenv.env['SUPABASE_ANON_KEY'];
    assert(v != null && v.isNotEmpty, 'SUPABASE_ANON_KEY missing from .env');
    return v ?? '';
  }

  static String get geminiApiKey {
    final v = dotenv.env['GEMINI_API_KEY'];
    assert(v != null && v.isNotEmpty, 'GEMINI_API_KEY missing from .env');
    return v ?? '';
  }
}

class SupabaseConfig {
  static Future<void> initialize() async {
    await dotenv.load(fileName: '.env');
    if (kDebugMode) {
      assert(AppEnv.supabaseUrl.isNotEmpty, '❌ SUPABASE_URL is empty in .env');
      assert(AppEnv.supabaseAnonKey.isNotEmpty, '❌ SUPABASE_ANON_KEY is empty in .env');
      assert(AppEnv.geminiApiKey.isNotEmpty, '❌ GEMINI_API_KEY is empty in .env');
    }
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
