import 'dart:developer' as developer;

/// Tiny logger seam. Sentry/PostHog wiring lands in a later phase
/// (see ADR-0006 deferred deps). Never use `print()` in app code.
class AppLogger {
  AppLogger(this.tag);

  final String tag;

  void info(String message, {Map<String, dynamic>? data}) =>
      developer.log(message, name: tag, level: 800, error: data);

  void warn(String message, {Object? error, StackTrace? stackTrace}) =>
      developer.log(message,
          name: tag, level: 900, error: error, stackTrace: stackTrace);

  void error(String message, {Object? error, StackTrace? stackTrace}) =>
      developer.log(message,
          name: tag, level: 1000, error: error, stackTrace: stackTrace);
}
