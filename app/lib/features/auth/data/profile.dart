import 'package:flutter/foundation.dart';

/// Plain Dart model mirroring the `profiles` row. Keep in lockstep with
/// `supabase/migrations/20260512000001_initial_schema.sql` and the Phase 1
/// bootstrap migration.
@immutable
class MazadProfile {
  const MazadProfile({
    required this.id,
    required this.pseudonym,
    required this.kycTier,
    required this.locale,
    this.displayName,
    this.phone,
    this.city,
    this.email,
  });

  final String id;
  final String pseudonym;
  final int kycTier; // 0, 1, 2
  final String locale; // 'en' | 'ar' | 'ku' | 'tr'
  final String? displayName;
  final String? phone;
  final String? city;
  final String? email;

  bool get hasCompletedSetup =>
      displayName != null && displayName!.trim().isNotEmpty;

  bool get isSeller => kycTier >= 2;

  factory MazadProfile.fromJson(Map<String, dynamic> json) => MazadProfile(
        id: json['id'] as String,
        pseudonym: (json['pseudonym'] ?? '') as String,
        kycTier: (json['kyc_tier'] ?? 0) as int,
        locale: (json['locale'] ?? 'en') as String,
        displayName: json['display_name'] as String?,
        phone: json['phone'] as String?,
        city: json['city'] as String?,
        email: json['email'] as String?,
      );

  MazadProfile copyWith({
    String? displayName,
    String? locale,
    String? city,
    int? kycTier,
  }) =>
      MazadProfile(
        id: id,
        pseudonym: pseudonym,
        kycTier: kycTier ?? this.kycTier,
        locale: locale ?? this.locale,
        displayName: displayName ?? this.displayName,
        phone: phone,
        city: city ?? this.city,
        email: email,
      );
}
