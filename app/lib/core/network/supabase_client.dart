import 'package:supabase_flutter/supabase_flutter.dart';

/// Initialize the Supabase client. URL + anon key come from `--dart-define`s
/// or compile-time env at build:
///
///   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
///
/// Phase 0 ships with empty defaults; real values land in `.env` and CI.
class MazadSupabase {
  static const _url = String.fromEnvironment('SUPABASE_URL');
  static const _anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Initialize once at app start. Pass [appHeaders] so every Supabase call
  /// carries `App-Version` / `App-Platform` (see ADR-0004).
  static Future<void> init({required Map<String, String> appHeaders}) async {
    if (_url.isEmpty || _anonKey.isEmpty) {
      // Permit Phase 0 boot with no backend wired yet.
      return;
    }
    await Supabase.initialize(
      url: _url,
      anonKey: _anonKey,
      headers: appHeaders,
    );
  }

  static bool get isConfigured => _url.isNotEmpty && _anonKey.isNotEmpty;
}
