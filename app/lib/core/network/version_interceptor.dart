import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mazad/features/system/force_update_notifier.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Adds `App-Version` and `App-Platform` headers to every outbound request,
/// and converts a 426 response into a global force-update event.
///
/// See `.claude/skills/auto-update/SKILL.md` and ADR-0004.
class VersionInterceptor extends Interceptor {
  VersionInterceptor._(this._version, this._platform);

  final String _version;
  final String _platform;

  static Future<VersionInterceptor> create() async {
    final info = await PackageInfo.fromPlatform();
    return VersionInterceptor._(info.version, _detectPlatform());
  }

  static String _detectPlatform() {
    if (kIsWeb) return 'web';
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    return 'web';
  }

  /// Header map for non-Dio callers (e.g. the Supabase Flutter client).
  Map<String, String> get headers => {
        'App-Version': _version,
        'App-Platform': _platform,
      };

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['App-Version'] = _version;
    options.headers['App-Platform'] = _platform;
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 426) {
      final data = err.response?.data;
      Map<String, dynamic>? body;
      if (data is Map<String, dynamic>) body = data;

      ForceUpdateNotifier.instance.trigger(
        minVersion: body?['min_supported_version'] as String?,
        storeUrl: body?['store_url'] as String?,
        releaseNotes: body?['release_notes'] as Map<String, dynamic>?,
      );
      // Do not propagate — app is blocked until update.
      return;
    }
    handler.next(err);
  }
}
