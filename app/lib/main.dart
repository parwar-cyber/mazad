import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazad/app.dart';
import 'package:mazad/core/network/supabase_client.dart';
import 'package:mazad/core/network/version_interceptor.dart';

/// Bootstrap order matters:
///   1. Flutter bindings
///   2. VersionInterceptor (so Supabase init can carry `App-Version` headers)
///   3. Supabase init (no-op if SUPABASE_URL not provided)
///   4. Riverpod scope + MaterialApp.router
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final versionInterceptor = await VersionInterceptor.create();

  // External-API Dio instance — same interceptor is reused for Supabase
  // headers via [VersionInterceptor.headers]. Phase 0 doesn't ship external
  // calls yet; we wire the instance now so feature code can read it from a
  // provider later.
  Dio()..interceptors.add(versionInterceptor);

  await MazadSupabase.init(appHeaders: versionInterceptor.headers);

  runApp(const ProviderScope(child: MazadApp()));
}
