import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Errors surfaced to the auth UI. We map Supabase / network errors into
/// these tagged values so the screens can pick a localized message and
/// keep their own code path narrow.
enum AuthErrorKind {
  invalidPhone,
  rateLimited,
  invalidCode,
  expiredCode,
  network,
  unknown,
}

class AuthException implements Exception {
  AuthException(this.kind, [this.cause]);
  final AuthErrorKind kind;
  final Object? cause;
  @override
  String toString() => 'AuthException($kind): $cause';
}

class AuthService {
  AuthService(this._client);
  final SupabaseClient _client;

  /// Sends an OTP to the phone via Supabase Auth (Twilio Verify provider).
  /// Phone must be E.164 — caller is responsible for normalization.
  Future<void> sendOtp(String e164Phone) async {
    try {
      await _client.auth.signInWithOtp(phone: e164Phone);
    } on AuthApiException catch (e) {
      throw AuthException(_kindFromMessage(e.message), e);
    } catch (e) {
      throw AuthException(AuthErrorKind.unknown, e);
    }
  }

  /// Verifies the OTP and creates / signs in the user.
  Future<Session?> verifyOtp({
    required String e164Phone,
    required String code,
  }) async {
    try {
      final res = await _client.auth.verifyOTP(
        phone: e164Phone,
        token: code,
        type: OtpType.sms,
      );
      return res.session;
    } on AuthApiException catch (e) {
      throw AuthException(_kindFromMessage(e.message), e);
    } catch (e) {
      throw AuthException(AuthErrorKind.unknown, e);
    }
  }

  Future<void> signOut() => _client.auth.signOut();

  /// Best-effort mapping of Supabase Auth error messages to our enum. The
  /// surface area here is small in Phase 1; expand as we hit real cases.
  AuthErrorKind _kindFromMessage(String message) {
    final m = message.toLowerCase();
    if (m.contains('rate') || m.contains('too many')) return AuthErrorKind.rateLimited;
    if (m.contains('invalid') && m.contains('phone')) return AuthErrorKind.invalidPhone;
    if (m.contains('expired')) return AuthErrorKind.expiredCode;
    if (m.contains('invalid') || m.contains('token')) return AuthErrorKind.invalidCode;
    return AuthErrorKind.unknown;
  }
}

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(Supabase.instance.client),
);

/// Iraq mobile-number normalization. Accepts the local form (07xxxxxxxx)
/// and full E.164 (+9647xxxxxxxx). Returns null if the input doesn't look
/// like a valid Iraqi mobile.
String? normalizeIraqiPhone(String raw) {
  final stripped = raw.replaceAll(RegExp(r'[\s\-\(\)]'), '');
  if (stripped.isEmpty) return null;

  // Already E.164 with Iraq country code.
  if (stripped.startsWith('+964')) {
    final rest = stripped.substring(4);
    return _isValidIqMobileBody(rest) ? '+964$rest' : null;
  }
  if (stripped.startsWith('00964')) {
    final rest = stripped.substring(5);
    return _isValidIqMobileBody(rest) ? '+964$rest' : null;
  }
  // Local form: 07xxxxxxxx (10 digits starting with 07).
  if (stripped.startsWith('07') && stripped.length == 11) {
    final rest = stripped.substring(1); // drop leading 0
    return _isValidIqMobileBody(rest) ? '+964$rest' : null;
  }
  // Bare 7xxxxxxxx (10 digits starting with 7).
  if (stripped.startsWith('7') && stripped.length == 10) {
    return _isValidIqMobileBody(stripped) ? '+964$stripped' : null;
  }
  return null;
}

bool _isValidIqMobileBody(String digits) {
  // Iraqi mobile networks all use a leading 7 followed by 9 more digits.
  return RegExp(r'^7\d{9}$').hasMatch(digits);
}
