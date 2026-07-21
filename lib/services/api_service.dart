import 'package:supabase_flutter/supabase_flutter.dart';

class ApiService {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const smartReportWebUrl = String.fromEnvironment(
    'SMART_REPORT_WEB_URL',
    defaultValue: 'http://10.0.2.2:8501',
  );
  static const geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'AIzaSyCFltFDqgNFj2vz0TUoa639LGOfVRqt51o',
  );
  static const geminiModel = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-2.5-flash',
  );

  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static String get normalizedGeminiApiKey {
    var key = geminiApiKey.trim();
    while (key.endsWith('+')) {
      key = key.substring(0, key.length - 1);
    }
    return key;
  }

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    if (!isSupabaseConfigured) {
      return;
    }

    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }
}
